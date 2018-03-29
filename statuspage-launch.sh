#!/bin/sh

export TF_VAR_token=$do_token

apt-add-repository ppa:ansible/ansible
apt update
apt install -y unzip software-properties-common python-boto3 apache2-utils ansible
apt autoremove -y
ssh-keygen -P "" -f /root/.ssh/id_rsa
wget https://releases.hashicorp.com/terraform/0.11.3/terraform_0.11.3_linux_amd64.zip -O terraform_0.11.3_linux_amd64.zip
unzip terraform_0.11.3_linux_amd64.zip
mv terraform /usr/bin/terraform
rm terraform_0.11.3_linux_amd64.zip
cd ~
#TODO: Update this URL to GH release URL when this repository becomes public
wget https://statuspage-demo.nyc3.digitaloceanspaces.com/statuspage-demo.zip
unzip statuspage-demo.zip -d statuspage-demo
rm -f statuspage-demo.zip
cd statuspage-demo
cat >> /root/.bashrc << EOF
export TF_VAR_token=$do_token
EOF
export bastion_id=$(curl -s http://169.254.169.254/metadata/v1/id)
cat > bucket_create.py << EOF
import boto3
from botocore.client import Config
session = boto3.session.Session()
client = session.client('s3',
                        endpoint_url='https://nyc3.digitaloceanspaces.com',
                        aws_access_key_id='$do_spaces_id',
                        aws_secret_access_key='$do_spaces_key')
response = client.list_buckets()
spaces = [space['Name'] for space in response['Buckets']]
if 'tf-states-$bastion_id' in spaces:
  print("Spaces List: %s" % spaces)
else:
  client.create_bucket(Bucket='tf-states-$bastion_id')
EOF
cat > bucket_delete.py << EOF
import boto3
s3 = boto3.resource('s3',
                        endpoint_url='https://nyc3.digitaloceanspaces.com',
                        aws_access_key_id='$do_spaces_id',
                        aws_secret_access_key='$do_spaces_key')
session = boto3.session.Session()
client = session.client('s3',
                        endpoint_url='https://nyc3.digitaloceanspaces.com',
                        aws_access_key_id='$do_spaces_id',
                        aws_secret_access_key='$do_spaces_key')
response = client.list_buckets()
spaces = [space['Name'] for space in response['Buckets']]
if 'tf-states-$bastion_id' in spaces:
  tf_bucket = s3.Bucket('tf-states-$bastion_id')
  for key in tf_bucket.objects.all():
    key.delete()
  tf_bucket.delete()
EOF
cat > terraform/remote.tf << EOF
terraform {
  backend "s3" {
    bucket = "tf-states-$bastion_id"
    key    = "status-page-demo/terraform.tfstate"
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
python bucket_create.py && rm -f bucket_create.py
cat > cleanup.sh << EOF
cd /root/statuspage-demo/terraform
terraform state rm digitalocean_droplet.bastion
terraform destroy -force
python /root/statuspage-demo/bucket_delete.py
EOF
chmod +x cleanup.sh
cd terraform
terraform init -backend
terraform import digitalocean_droplet.bastion $bastion_id
terraform apply -auto-approve
