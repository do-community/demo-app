#!/bin/bash -x

set -e

# Install Ansible
apt-add-repository ppa:ansible/ansible
apt update
apt install -y ansible

# Download the demo app
wget -P /root https://statuspage-demo.nyc3.digitaloceanspaces.com/statuspage-demo.tar.gz
mkdir /root/statuspage-demo
tar -xf /root/statuspage-demo.tar.gz -C /root/statuspage-demo
rm /root/statuspage-demo.tar.gz

# Run the localhost playbook
cd /root/statuspage-demo/ansible
HOME=/root ansible-playbook playbooks/localhost.yml --connection=local --inventory=localhost,

# Get our bastion Droplet ID by calling the metadata API.
export bastion_id=$(curl -s http://169.254.169.254/metadata/v1/id)

# Add a script for creating a Space for our Terraform state
cat > /root/statuspage-demo/space_create.py << EOF
import boto3
s3 = boto3.client(
    's3',
    endpoint_url='https://nyc3.digitaloceanspaces.com',
    aws_access_key_id='$do_spaces_id',
    aws_secret_access_key='$do_spaces_key'
)
response = s3.list_buckets()
spaces = [space['Name'] for space in response['Buckets']]
if 'tfstate-$bastion_id' in spaces:
  print('Space already exists.')
else:
  s3.create_bucket(Bucket='tfstate-$bastion_id')
EOF

# Execute the script and remove it
python /root/statuspage-demo/space_create.py && \
  rm /root/statuspage-demo/space_create.py

# Add a script for deleting the Space later
cat > /root/statuspage-demo/space_delete.py << EOF
import boto3
s3 = boto3.resource(
    's3',
    endpoint_url='https://nyc3.digitaloceanspaces.com',
    aws_access_key_id='$do_spaces_id',
    aws_secret_access_key='$do_spaces_key'
)
response = s3.meta.client.list_buckets()
spaces = [space['Name'] for space in response['Buckets']]
if 'tfstate-$bastion_id' in spaces:
  tf_bucket = s3.Bucket('tfstate-$bastion_id')
  for key in tf_bucket.objects.all():
    key.delete()
  tf_bucket.delete()
EOF

# Configure our new space as the backend for Terraform.
# This will be where we store Terraform state.
cat > /root/statuspage-demo/terraform/remote.tf << EOF
terraform {
  backend "s3" {
    bucket = "tfstate-$bastion_id"
    key = "statuspage-demo.tfstate"
    region = "us-east-1"
    endpoint = "https://nyc3.digitaloceanspaces.com"
    access_key = "$do_spaces_id"
    secret_key = "$do_spaces_key"
    skip_credentials_validation = true
    skip_get_ec2_platforms = true
    skip_requesting_account_id = true
    skip_metadata_api_check = true
  }
}
EOF

# Run Terraform.
cd /root/statuspage-demo/terraform
echo "token = \"$do_token\"" > token.auto.tfvars
terraform init
terraform import digitalocean_droplet.bastion $bastion_id
terraform apply -auto-approve
