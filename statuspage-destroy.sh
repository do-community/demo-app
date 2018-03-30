#!/bin/bash -x

set -e

cd /root/statuspage-demo/terraform
terraform state rm digitalocean_droplet.bastion
terraform destroy -force
