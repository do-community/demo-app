provider "digitalocean" {
  token = "${var.token}"
}

#Add Bastion's SSH Key
resource "digitalocean_ssh_key" "default" {
  name       = "Status Page demo"
  public_key = "${file(var.pub_key_path)}"
}

#Should be imported during cloud-init
resource "digitalocean_droplet" "bastion" {
  image  = "ubuntu-16-04-x64"
  name   = "bastion"
  region = "${var.region}"
  size   = "s-1vcpu-1gb"
  private_networking = true
  resize_disk = false
}

#Create volume for database droplet
resource "digitalocean_volume" "db" {
  region = "${var.region}"
  name   = "statuspage-db-${digitalocean_droplet.bastion.id}"
  size   = 100
}

#Create database droplet
resource "digitalocean_droplet" "db" {
  image  = "ubuntu-16-04-x64"
  name   = "statuspage-db"
  region = "${var.region}"
  size   = "1gb"

  monitoring = true
  ssh_keys = ["${digitalocean_ssh_key.default.id}"]
  private_networking = true

  volume_ids = ["${digitalocean_volume.db.id}"]

  user_data = "${file("user_data.sh")}"
}

#Create Web-Server droplets
resource "digitalocean_droplet" "web" {
  count = "${var.web_server_params["count"]}"

  image  = "ubuntu-16-04-x64"
  name   = "statuspage-web-${count.index}"
  region = "${var.region}"
  size   = "512mb"

  monitoring = true
  ssh_keys = ["${digitalocean_ssh_key.default.id}"]
  private_networking = true

  user_data = "${file("user_data.sh")}"
}

#Create Loadbalancer
resource "digitalocean_loadbalancer" "lb" {
  name   = "statuspage-loadbalancer-${digitalocean_droplet.bastion.id}"
  region = "${var.region}"

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 8080
    target_protocol = "http"
  }

  healthcheck {
    port     = 8080
    protocol = "tcp"
  }

  droplet_ids = ["${digitalocean_droplet.web.*.id}"]

  depends_on = ["digitalocean_droplet.web"]
}

#Create firewall_rules for web and db droplets
resource "digitalocean_firewall" "web" {
  name = "statuspage-loadbalancer-to-web-firewall-${digitalocean_droplet.bastion.id}"

  droplet_ids = ["${digitalocean_droplet.web.*.id}"]

  inbound_rule = [
    {
      protocol         = "tcp"
      port_range       = "8080"
      source_load_balancer_uids = ["${digitalocean_loadbalancer.lb.id}"]
    },
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["${digitalocean_droplet.bastion.ipv4_address_private}"]
    },
    {
      protocol         = "icmp"
      source_addresses = ["${digitalocean_droplet.bastion.ipv4_address_private}"]
    },
  ]

  outbound_rule = [
    {
      protocol         = "tcp"
      port_range       = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "udp"
      port_range       = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "icmp"
      port_range       = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
  ]
}

resource "digitalocean_firewall" "db" {
  name = "statuspage-web-to-database-firewall-${digitalocean_droplet.bastion.id}"

  droplet_ids = ["${digitalocean_droplet.db.id}"]

  inbound_rule = [
    {
      protocol         = "tcp"
      port_range       = "3306"
      source_addresses = ["${digitalocean_droplet.web.*.ipv4_address_private}"]
    },
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["${digitalocean_droplet.bastion.ipv4_address_private}"]
    },
    {
      protocol         = "icmp"
      source_addresses = ["${digitalocean_droplet.bastion.ipv4_address_private}"]
    },
  ]

  outbound_rule = [
    {
      protocol         = "tcp"
      port_range       = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "udp"
      port_range       = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "icmp"
      port_range       = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
  ]
}

data "template_file" "ansible_hosts" {
  template = "[web]\n$${web}\n\n[db]\n$${db}\n"
  depends_on = ["digitalocean_droplet.web", "digitalocean_droplet.db"]

  vars {
    web = "${join("\n", digitalocean_droplet.web.*.ipv4_address_private)}"
    db = "db-0 ansible_host=${digitalocean_droplet.db.ipv4_address_private}"
  }
}

data "template_file" "load_gen" {
  template = "* * * * * root ab -qSd -t 60 -n $(shuf -i 50000-150000 -n 1) -c $(shuf -i 50-100 -n 1) http://$${lb_ip}/ 2>&1 > /dev/null"
  depends_on = ["digitalocean_loadbalancer.lb", "null_resource.ansible_web"]

  vars {
    lb_ip = "${digitalocean_loadbalancer.lb.ip}"
  }
}

resource null_resource "load_gen" {
  depends_on = ["digitalocean_loadbalancer.lb"]
  triggers {
    template_rendered = "${data.template_file.load_gen.rendered}"
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.load_gen.rendered}' > /etc/cron.d/statuspage-load-generator"
  }
}

resource null_resource "ansible_prep" {
  depends_on = ["digitalocean_droplet.web", "digitalocean_droplet.db"]
  triggers {
    template_rendered = "${data.template_file.ansible_hosts.rendered}"
  }

  provisioner "local-exec" {
    command = "cd ../ansible && echo '${data.template_file.ansible_hosts.rendered}' > hosts"
  }
}

resource null_resource "ansible_web" {
  depends_on = ["null_resource.ansible_prep", "digitalocean_firewall.web"]

  provisioner "local-exec" {
    command = "cd ../ansible && ansible-playbook playbooks/web.yml"
  }
}

resource null_resource "ansible_db" {
  depends_on = ["null_resource.ansible_prep", "digitalocean_firewall.db"]

  provisioner "local-exec" {
    command = "cd ../ansible && ansible-playbook playbooks/db.yml"
  }
}
