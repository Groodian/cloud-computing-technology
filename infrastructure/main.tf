terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    tls = {
      source  = "hashicorp/tls"
    }
  }

  // for gitlab ci
  backend "http" {
  }
}

provider "google" {
  credentials   = file(var.credentials_file)
  project       = var.project
  region        = var.region
  zone          = var.zone
}

resource "google_project_service" "cloud_resource_manager" {
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

provider "tls" {
  // no config needed
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key_pem" {
  content         = tls_private_key.ssh.private_key_openssh
  filename        = ".ssh/google_compute_engine"
  file_permission = "0600"
}

resource "local_file" "ssh_public_key_pem" {
  content         = tls_private_key.ssh.public_key_openssh
  filename        = ".ssh/google_compute_engine.pub"
  file_permission = "0600"
}

resource "google_compute_network" "kubernetes_network" {
  name = "kubernetes-network"
}

resource "google_compute_address" "static_ip_kubernetes_master" {
  name = "kubernetes-master"
}

resource "google_compute_firewall" "allow_ssh" {
  name          = "allow-ssh"
  network       = google_compute_network.kubernetes_network.name
  target_tags   = ["allow-ssh"] // this targets our tagged VM
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "allow_http" {
  name          = "allow-http"
  network       = google_compute_network.kubernetes_network.name
  target_tags   = ["allow-http"] // this targets our tagged VM
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_firewall" "allow_grafana" {
  name          = "allow-grafana"
  network       = google_compute_network.kubernetes_network.name
  target_tags   = ["allow-grafana"] // this targets our tagged VM
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["9090","30000-32700"]
  }
}

resource "google_compute_firewall" "allow_kubernetes_api" {
  name          = "allow-kubernetes-api"
  network       = google_compute_network.kubernetes_network.name
  target_tags   = ["allow-kubernetes-api"] // this targets our tagged VM
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["6443","2379-2380","10250","10259","10257","30000-32767"]
  }
}

data "google_client_openid_userinfo" "me" {}

resource "google_compute_instance" "kubernetes_master" {
  name         = "kubernetes-master"
  machine_type = "e2-medium"
  tags         = ["allow-ssh","allow-http","allow-kubernetes-api","allow-grafana"] // this receives the firewall rule

  metadata = {
    ssh-keys = "${var.user}:${tls_private_key.ssh.public_key_openssh}"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size = 40
    }
  }

  network_interface {
    network = google_compute_network.kubernetes_network.name

    access_config {
      nat_ip = google_compute_address.static_ip_kubernetes_master.address
    }
  }

  provisioner "remote-exec" {
    connection {
      host        = google_compute_address.static_ip_kubernetes_master.address
      type        = "ssh"
      user        = var.user
      timeout     = "180s"
      private_key = tls_private_key.ssh.private_key_pem
    }

    inline = [
      "echo 'Wait until SSH is ready'",
    ]
  }

}

resource "google_compute_instance" "kubernetes_worker" {
  name         = "kubernetes-worker-${count.index}"
  machine_type = "e2-medium"
  tags         = ["allow-ssh","allow-kubernetes-api"] // this receives the firewall rule
  count        = var.worker_count

  metadata = {
    ssh-keys = "${var.user}:${tls_private_key.ssh.public_key_openssh}"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size = 40
    }
  }

  network_interface {
    network = google_compute_network.kubernetes_network.name

    access_config {
    }
  }

  provisioner "remote-exec" {
    connection {
      host        = google_compute_address.static_ip_kubernetes_master.address
      type        = "ssh"
      user        = var.user
      timeout     = "180s"
      private_key = tls_private_key.ssh.private_key_pem
    }

    inline = [
      "echo 'Wait until SSH is ready'",
    ]
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("../kubernetes-install/inventory.tmpl", {
    user                        = var.user,
    key_path                    = "../infrastructure/.ssh/google_compute_engine",
    kubernetes_master_address   = google_compute_instance.kubernetes_master.network_interface.0.access_config.0.nat_ip,
    kubernetes_master_name      = google_compute_instance.kubernetes_master.name,
    kubernetes_workers_address  = google_compute_instance.kubernetes_worker.*.network_interface.0.access_config.0.nat_ip,
    kubernetes_workers_name     = google_compute_instance.kubernetes_worker.*.name,
  })
  filename = "../kubernetes-install/inventory"

  provisioner "local-exec" {
    working_dir = "../kubernetes-install/"
    command     = "ansible-playbook main.yml"
  }
}
