terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }

  // for gitlab ci
  backend "http" {
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = var.region
  zone        = var.zone
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
}

resource "tls_private_key" "ssh_cluster" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_cluster_private_key_pem" {
  content         = tls_private_key.ssh_cluster.private_key_openssh
  filename        = ".ssh/cluster"
  file_permission = "0600"
}

resource "local_file" "ssh_cluster_public_key_pem" {
  content         = tls_private_key.ssh_cluster.public_key_openssh
  filename        = ".ssh/cluster.pub"
  file_permission = "0600"
}

resource "tls_private_key" "ssh_bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_bastion_private_key_pem" {
  content         = tls_private_key.ssh_bastion.private_key_openssh
  filename        = ".ssh/bastion"
  file_permission = "0600"
}

resource "local_file" "ssh_bastion_public_key_pem" {
  content         = tls_private_key.ssh_bastion.public_key_openssh
  filename        = ".ssh/bastion.pub"
  file_permission = "0600"
}

resource "google_compute_network" "kubernetes_network" {
  name = "kubernetes-network"
}

resource "google_compute_address" "static_ip_bastion" {
  name = "kubernetes-master"
}

resource "google_compute_address" "static_ip_load_balancer" {
  name = "load-balancer"
}

