resource "google_compute_instance" "bastion" {
  name         = "bastion"
  machine_type = "e2-small"
  tags         = ["allow-ssh-bastion"] // this receives the firewall rule

  metadata = {
    ssh-keys = "${var.bastion_user}:${tls_private_key.ssh_bastion.public_key_openssh}"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    network = google_compute_network.kubernetes_network.name

    access_config {
      nat_ip = google_compute_address.static_ip_bastion.address
    }
  }

  provisioner "remote-exec" {
    connection {
      host        = google_compute_address.static_ip_bastion.address
      type        = "ssh"
      user        = var.bastion_user
      timeout     = "180s"
      private_key = tls_private_key.ssh_bastion.private_key_pem
    }

    inline = [
      "echo 'Wait until SSH is ready'",
    ]
  }

}

resource "google_compute_instance" "kubernetes_masters" {
  name         = "kubernetes-master-${count.index}"
  machine_type = "e2-medium"
  tags         = ["allow-ssh-cluster", "allow-kubernetes", "allow-grafana", "allow-all-kubernetes", "allow-flannel"] // this receives the firewall rule
  count        = var.master_count

  metadata = {
    ssh-keys = "${var.cluster_user}:${tls_private_key.ssh_cluster.public_key_openssh}"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 40
    }
  }

  network_interface {
    network = google_compute_network.kubernetes_network.name
  }

  provisioner "remote-exec" {
    connection {
      host                = self.network_interface.0.network_ip
      type                = "ssh"
      user                = var.cluster_user
      timeout             = "180s"
      private_key         = tls_private_key.ssh_cluster.private_key_pem
      bastion_host        = google_compute_address.static_ip_bastion.address
      bastion_user        = var.bastion_user
      bastion_private_key = tls_private_key.ssh_bastion.private_key_pem
    }

    inline = [
      "echo 'Wait until SSH is ready'",
    ]
  }

}

resource "google_compute_instance" "kubernetes_worker" {
  name         = "kubernetes-worker-${count.index}"
  machine_type = "e2-medium"
  tags         = ["allow-ssh-cluster", "allow-kubernetes", "allow-grafana", "allow-all-kubernetes", "allow-flannel"] // this receives the firewall rule
  count        = var.worker_count

  metadata = {
    ssh-keys = "${var.cluster_user}:${tls_private_key.ssh_cluster.public_key_openssh}"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 40
    }
  }

  network_interface {
    network = google_compute_network.kubernetes_network.name
  }

  provisioner "remote-exec" {
    connection {
      host                = self.network_interface.0.network_ip
      type                = "ssh"
      user                = var.cluster_user
      timeout             = "180s"
      private_key         = tls_private_key.ssh_cluster.private_key_pem
      bastion_host        = google_compute_address.static_ip_bastion.address
      bastion_user        = var.bastion_user
      bastion_private_key = tls_private_key.ssh_bastion.private_key_pem
    }

    inline = [
      "echo 'Wait until SSH is ready'",
    ]
  }
}
