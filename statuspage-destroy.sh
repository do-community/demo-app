#!/bin/bash

set -e

# Destroy resources Terraform manages except the bastion host.
cd /root/statuspage-demo/terraform
terraform state rm digitalocean_droplet.bastion
terraform destroy -force

# Destroy the Space we've been using for Terraform remote state.
python /root/statuspage-demo/space_delete.py
