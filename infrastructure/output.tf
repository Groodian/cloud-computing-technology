output "bastion_ip" {
  value = google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip
}

output "kubernetes_master_ip" {
  value = google_compute_instance.kubernetes_master.network_interface.0.network_ip
}

output "kubernetes_worker_ip" {
  value = google_compute_instance.kubernetes_worker.*.network_interface.0.network_ip
}
