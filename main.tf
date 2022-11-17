terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }

  backend "http" {
  }
}

provider "google" {
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
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

  provisioner "local-exec" { 
    command = "echo '${tls_private_key.ssh.private_key_pem}' > ./google_compute_engine; chmod 400 ./google_compute_engine"
  }
}

resource "local_file" "ssh_private_key_pem" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = ".ssh/google_compute_engine"
  file_permission = "0600"
}

resource "google_compute_network" "vpc_network" {
  name = "my-network"
}

resource "google_compute_address" "static_ip_master" {
  name = "debian-master"
}

resource "google_compute_address" "static_ip_worker_1" {
  name = "debian-worker-1"
}

resource "google_compute_address" "static_ip_worker_2" {
  name = "debian-worker-2"
}

resource "google_compute_firewall" "allow_ssh" {
  name          = "allow-ssh"
  network       = google_compute_network.vpc_network.name
  target_tags   = ["allow-ssh"] // this targets our tagged VM
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "allow_http" {
  name          = "allow-http"
  network       = google_compute_network.vpc_network.name
  target_tags   = ["allow-http"] // this targets our tagged VM
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_firewall" "allow_kuebernetes_api" {
  name          = "allow-kubernetes-api"
  network       = google_compute_network.vpc_network.name
  target_tags   = ["allow-http"] // this targets our tagged VM
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }
}

data "google_client_openid_userinfo" "me" {}

resource "google_compute_instance" "debian_master" {
  name         = "debian-master"
  machine_type = "f1-micro"
  tags         = ["allow-ssh","allow-http","allow-kubernetes-api"] // this receives the firewall rule

  metadata = {
    ssh-keys = "${var.user}:${tls_private_key.ssh.public_key_openssh}"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size = 50
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name

    access_config {
      nat_ip = google_compute_address.static_ip_master.address
    }
  }

  provisioner "remote-exec" {
    connection {
      host        = google_compute_address.static_ip_master.address
      type        = "ssh"
      user        = var.user
      timeout     = "500s"
      private_key = tls_private_key.ssh.private_key_pem
    }
    inline = [
      "sudo apt -y update",
      "sudo apt -y install nginx git",
      "sudo nginx -v",
    ]
  }
}

resource "google_compute_instance" "debian_worker_1" {
  name         = "debian-worker-1"
  machine_type = "f1-micro"
  tags         = ["allow-ssh"] // this receives the firewall rule

  metadata = {
    ssh-keys = "${var.user}:${tls_private_key.ssh.public_key_openssh}"
    //ssh-keys = "${split("@", data.google_client_openid_userinfo.me.email)[0]}:${tls_private_key.ssh.public_key_openssh}"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size = 50
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name

    access_config {
      nat_ip = google_compute_address.static_ip_worker_1.address
    }
  }
}

resource "google_compute_instance" "debian_worker_2" {
  name         = "debian-worker-2"
  machine_type = "f1-micro"
  tags         = ["allow-ssh"] // this receives the firewall rule

  metadata = {
    ssh-keys = "${var.user}:${tls_private_key.ssh.public_key_openssh}"
    //ssh-keys = "${split("@", data.google_client_openid_userinfo.me.email)[0]}:${tls_private_key.ssh.public_key_openssh}"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size = 50
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name

    access_config {
      nat_ip = google_compute_address.static_ip_worker_2.address
    }
  }
}