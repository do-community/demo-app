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

# Run Terraform.
cd /root/statuspage-demo/terraform
echo "token = \"$do_token\"" > token.auto.tfvars
terraform init
terraform import digitalocean_droplet.bastion $(curl -s http://169.254.169.254/metadata/v1/id)
terraform apply -auto-approve
