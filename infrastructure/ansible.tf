resource "local_file" "ansible_inventory" {
  content = templatefile("../ansible-inventory/inventory.tmpl", {
    bastion_user               = var.bastion_user,
    cluster_user               = var.cluster_user,
    bastion_key_path           = "../infrastructure/.ssh/bastion",
    cluster_key_path           = "../infrastructure/.ssh/cluster",
    bastion_address            = google_compute_instance.bastion.network_interface.0.access_config.0.nat_ip,
    bastion_name               = google_compute_instance.bastion.name,
    kubernetes_master_address  = google_compute_instance.kubernetes_master.network_interface.0.network_ip,
    kubernetes_master_name     = google_compute_instance.kubernetes_master.name,
    kubernetes_workers_address = google_compute_instance.kubernetes_worker.*.network_interface.0.network_ip,
    kubernetes_workers_name    = google_compute_instance.kubernetes_worker.*.name,
  })
  filename = "../ansible-inventory/inventory"

  provisioner "local-exec" {
    working_dir = "../ansible-inventory/"
    command     = "ansible-playbook main.yml"
  }

  depends_on = [
    google_compute_router_nat.nat,
    google_compute_instance.bastion,
    google_compute_instance.kubernetes_master,
    google_compute_instance.kubernetes_worker
  ]
}
