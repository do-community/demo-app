variable region {
  description = "Digital Ocean region"
  default     = "ams3"
}

variable "do_token" {
  description = "Digital Ocean API Token"
}

variable pub_key_path {
  description = "Path to bastion ssh public key"
  default     = "~/.ssh/id_rsa.pub"
}

variable ssh_key_path {
  description = "Path to bastion ssh private key"
  default     = "~/.ssh/id_rsa"
}

variable "doks_cluster_name" {
  description = "DOKS cluster name"
  type        = string
}

variable "doks_cluster_region" {
  description = "DOKS cluster region"
  type        = string
}

variable "doks_cluster_version" {
  description = "Kubernetes version provided by DOKS"
  type        = string
  default     = "1.21.3-do.0" # Grab the latest version slug from "doctl kubernetes options versions"
}

variable "doks_cluster_pool_size" {
  description = "DOKS cluster node pool size"
  type        = string
}

variable "doks_cluster_pool_node_count" {
  description = "DOKS cluster worker nodes count"
  type        = number
}

# The first part of my URL. Ex: the www in www.digitalocean.com
variable "subdomain" {
    type = string
}

# Domain you have registered and DigitalOcean manages
variable domain_name {
    type = string
}

variable web_server_params {
  default = {
    "count" = "2"
  }
}

#variable "tls_private_key_password" {
#  type        = string
#}

# The operating system image we want to use. 
# Can view slugs (valid options) https://slugs.do-api.dev/
variable "image" {
    type = string
    default = "ubuntu-22-04-x64"
}
# The size we want our droplets to be. 
# Can view slugs (valid options) https://slugs.do-api.dev/
variable "droplet_size" {
    type = string
    default = "s-1vcpu-1gb"
}