output "web_address" {
  value = ["${digitalocean_droplet.web.*.ipv4_address_private}"]
}

output "db_address" {
  value = ["${digitalocean_droplet.db.*.ipv4_address_private}"]
}

output "lb_address" {
  value = ["${digitalocean_loadbalancer.lb.*.ip}"]
}