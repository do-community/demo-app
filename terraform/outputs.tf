output "kubeconfig" {
  value = digitalocean_kubernetes_cluster.primary.kube_config
  sensitive = true
}
output "cluster-id" {
  value = digitalocean_kubernetes_cluster.primary.id
}
output "cluster_info" {
  value = format("Kubernetes cluster %s is %s", digitalocean_kubernetes_cluster.primary.name, digitalocean_kubernetes_cluster.primary.status)
}