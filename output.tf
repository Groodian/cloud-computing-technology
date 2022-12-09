output "kubernetes_master_ip" {
  value = google_compute_address.static_ip_kubernetes_master.address
}

output "kubernetes_worker_ip" {
  value = google_compute_instance.kubernetes_worker.*.network_interface.0.access_config.0.nat_ip
}

output "ssh_private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}
