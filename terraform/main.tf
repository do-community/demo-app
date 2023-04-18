provider "digitalocean" {
  token = "${var.do_token}"
}

data "digitalocean_ssh_key" "k3s-1" {
  name = "k3s-1"
}

data "digitalocean_vpc" "local-vpc" {
  name = "local-vpc"
}


data "digitalocean_domain" "web" {
  name = "${var.domain_name}"
}

#Should be imported during cloud-init
resource "digitalocean_droplet" "bastion" {
  image  = "ubuntu-22-04-x64"
  name   = "bastion"
  region = "${var.region}"
  size   = "s-1vcpu-512mb-10gb"
  ssh_keys = [data.digitalocean_ssh_key.k3s-1.id]
#  monitoring = true
  vpc_uuid   = data.digitalocean_vpc.local-vpc.id
  resize_disk = false
  lifecycle {
    create_before_destroy = true
  }
}

resource "digitalocean_record" "bastion" {
    domain = data.digitalocean_domain.web.name
    type   = "A"
    name   = "bastion"
    value  = digitalocean_droplet.bastion.ipv4_address
    ttl    = 300
}

################################################################################
# Create n web servers with nginx installed and a custom message on main page  #
################################################################################
resource "digitalocean_droplet" "web" {
#    count = var.droplet_count
    image = var.image
    name = "web-${var.subdomain}-${var.doks_cluster_name}"
    region = var.doks_cluster_region
    size = var.droplet_size
    vpc_uuid = data.digitalocean_vpc.local-vpc.id
    tags = ["${var.doks_cluster_name}-webserver", "terraform-sample-archs"]

    user_data = <<EOF
    #cloud-config
    packages:
        - nginx
        - postgresql
        - postgresql-contrib
    runcmd:
        - wget -P /var/www/html https://raw.githubusercontent.com/do-community/terraform-sample-digitalocean-architectures/master/01-minimal-web-db-stack/assets/index.html
        - sed -i "s/CHANGE_ME/web-${var.doks_cluster_region}/" /var/www/html/index.html
    EOF
    lifecycle {
        create_before_destroy = true
    }
}

resource "digitalocean_record" "web-srv" {
    domain = data.digitalocean_domain.web.name
    type   = "A"
    name   = "web-srv"
    value  = digitalocean_droplet.web.ipv4_address
    ttl    = 300
}


#resource "digitalocean_certificate" "web" {
#   name = "web-srv.${var.domain_name}"
#   type = "lets_encrypt"
#   domains = ["web-srv.${var.domain_name}"]
#    lifecycle {
#        create_before_destroy = true
#    }
#}

#Create volume for database droplet
resource "digitalocean_volume" "db" {
  region = "${var.region}"
  name   = "statuspage-db-${digitalocean_droplet.web.id}"
  size   = 3
  lifecycle {
    create_before_destroy = true
  }
}

resource "digitalocean_kubernetes_cluster" "primary" {
  name    = var.doks_cluster_name
  region  = var.doks_cluster_region
  version = var.doks_cluster_version

  node_pool {
    name       = "${var.doks_cluster_name}-pool"
    size       = var.doks_cluster_pool_size
    node_count = var.doks_cluster_pool_node_count
    tags       = ["backend"]
#    monitoring = true kube1-pool-*
    labels = {
      service  = "backend"
      priority = "high"
    }
  }
  vpc_uuid   = data.digitalocean_vpc.local-vpc.id
#  tls_private_key_password = var.tls_private_key_password
#  tls_cert        = file("cert/tls.crt")
#  tls_private_key = file("cert/tls.key")
}

#Create Loadbalancer
# resource "digitalocean_loadbalancer" "lb" {
#   name   = "statuspage-loadbalancer-${digitalocean_droplet.bastion.id}"
#   region = "${var.region}"
#    forwarding_rule {
#     entry_port     = 80
#     entry_protocol = "http"
# 
#     target_port     = 8080
#     target_protocol = "http"
#   }
#   healthcheck {
#     port     = 8080
#     protocol = "tcp"
#   }
# 
#   droplet_ids = ["${digitalocean_droplet.kube1-pool-*.id}"]
# # depends_on = ["digitalocean_droplet.kube1"]
# }

#    # one
#    lifecycle {
#        create_before_destroy = true
#    }