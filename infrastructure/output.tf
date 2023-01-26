output "bastion_ip" {
  value = google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip
}

output "load_balancer_ip_workers" {
  value = google_compute_address.static_ip_load_balancer_workers.address
}

output "load_balancer_ip_masters" {
  value = google_compute_address.static_ip_load_balancer_masters.address
}

output "kubernetes_master_ip" {
  value = google_compute_instance.kubernetes_masters.*.network_interface.0.network_ip
}

output "kubernetes_worker_ip" {
  value = google_compute_instance.kubernetes_worker.*.network_interface.0.network_ip
}
