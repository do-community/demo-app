variable "token" {}

variable "region" {
  default = "nyc3"
}

provider "digitalocean" {
  token = "${var.token}"
}

resource "digitalocean_droplet" "bastion" {
  # should be imported during cloud-init
  image  = "ubuntu-16-04-x64"
  name   = "bastion"
  region = "${var.region}"
  size   = "s-1vcpu-1gb"
  private_networking = true
  resize_disk = false
}

resource "digitalocean_ssh_key" "default" {
  name       = "Status Page demo"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "digitalocean_droplet" "web" {
  count = 1

  image  = "ubuntu-16-04-x64"
  name   = "statuspage-web-${count.index}"
  region = "${var.region}"
  size   = "512mb"

  ssh_keys = ["${digitalocean_ssh_key.default.id}"]

  monitoring = true

  private_networking = true
}

resource "digitalocean_volume" "db" {
  region = "${var.region}"
  name   = "statuspage-db"
  size   = 100
}

resource "digitalocean_droplet" "db" {
  image  = "mysql-16-04"
  name   = "db"
  region = "${var.region}"
  size   = "1gb"

  monitoring = true
  ssh_keys = ["${digitalocean_ssh_key.default.id}"]
  private_networking = true

  volume_ids = ["${digitalocean_volume.db.id}"]
}

resource "digitalocean_loadbalancer" "lb" {
  name   = "statuspage-loadbalancer"
  region = "${var.region}"

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 80
    protocol = "http"
    path     = "/health"
  }

  droplet_ids = ["${digitalocean_droplet.web.*.id}"]
}

resource "digitalocean_firewall" "web" {
  name = "statuspage-loadbalancer-to-web-firewall"

  droplet_ids = ["${digitalocean_droplet.web.*.id}"]

  inbound_rule = [
    {
      protocol         = "tcp"
      port_range       = "80"
      source_addresses = ["${digitalocean_loadbalancer.lb.ip}"]
    },
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["${digitalocean_droplet.bastion.*.ipv4_address_private}"]
    },
  ]
}

resource "digitalocean_firewall" "db" {
  name = "statuspage-web-to-database-firewall"

  droplet_ids = ["${digitalocean_droplet.db.id}"]

  inbound_rule = [
    {
      protocol         = "tcp"
      port_range       = "5432"
      source_addresses = ["${digitalocean_droplet.web.*.ipv4_address_private}"]
    },
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["${digitalocean_droplet.bastion.*.ipv4_address_private}"]
    },
  ]
}
