output "master_ip" {
  value = google_compute_address.static_ip_master.address
}

output "worker_ip_1" {
  value = google_compute_address.static_ip_worker_1.address
}

output "worker_ip_2" {
  value = google_compute_address.static_ip_worker_2.address
}


output "ssh_private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}