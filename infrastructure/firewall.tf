resource "google_compute_firewall" "allow_ssh_bastion" {
  name          = "allow-ssh-bastion"
  network       = google_compute_network.kubernetes_network.name
  target_tags   = ["allow-ssh-bastion"] // this targets our tagged VM
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "allow_ssh_cluster" {
  name          = "allow-ssh-cluster"
  network       = google_compute_network.kubernetes_network.name
  target_tags   = ["allow-ssh-cluster"] // this targets our tagged VM
  source_ranges = ["10.0.0.0/8"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "allow_kubernetes" {
  name          = "allow-kubernetes"
  network       = google_compute_network.kubernetes_network.name
  target_tags   = ["allow-kubernetes"] // this targets our tagged VM
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }
}

resource "google_compute_firewall" "allow_grafana" {
  name          = "allow-grafana"
  network       = google_compute_network.kubernetes_network.name
  target_tags   = ["allow-grafana"] // this targets our tagged VM
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "8443", var.grafana_port, "30000-32767"]
  }
}

resource "google_compute_firewall" "allow_all_kubernetes" {
  name          = "allow-all-kubernetes"
  network       = google_compute_network.kubernetes_network.name
  target_tags   = ["allow-all-kubernetes"] // this targets our tagged VM
  source_ranges = ["10.0.0.0/8"]

  allow {
    protocol = "tcp"
    ports    = ["6443", "2379-2380", "10250", "10259", "10257"]
  }
}

resource "google_compute_firewall" "allow_flannel" {
  name          = "allow-flannel"
  network       = google_compute_network.kubernetes_network.name
  target_tags   = ["allow-flannel"] // this targets our tagged VM
  source_ranges = ["10.0.0.0/8"]

  allow {
    protocol = "udp"
    ports    = ["8252", "8472"]
  }
}
