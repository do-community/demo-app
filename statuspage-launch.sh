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
cat > cleanup.sh << EOF
cd /root/statuspage-demo/terraform
terraform state rm digitalocean_droplet.bastion
terraform destroy -force
EOF
chmod +x cleanup.sh
cd terraform
terraform init -backend
terraform import digitalocean_droplet.bastion $bastion_id
terraform apply -auto-approve
