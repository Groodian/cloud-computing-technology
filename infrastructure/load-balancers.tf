resource "google_compute_forwarding_rule" "load_balancer_kubernetes_workers" {
  provider              = google
  project               = var.project
  name                  = "load-balancer-kubernetes-workers"
  target                = google_compute_target_pool.kubernetes_workers_target_pool.self_link
  load_balancing_scheme = "EXTERNAL"
  port_range            = null
  ip_address            = google_compute_address.static_ip_load_balancer_workers.self_link
  ip_protocol           = "TCP"
  network_tier          = "PREMIUM"
}

resource "google_compute_target_pool" "kubernetes_workers_target_pool" {
  provider         = google
  project          = var.project
  name             = "kubernetes-workers-target-pool"
  region           = var.region
  session_affinity = "NONE"
  instances        = google_compute_instance.kubernetes_worker.*.self_link
  health_checks    = [google_compute_http_health_check.kubernetes_workers_target_pool_health_check.self_link]
}

resource "google_compute_http_health_check" "kubernetes_workers_target_pool_health_check" {
  provider            = google
  project             = var.project
  name                = "kubernetes-workers-target-pool-health-check"
  timeout_sec         = 1
  check_interval_sec  = 1
  healthy_threshold   = 4
  unhealthy_threshold = 2
  port                = var.grafana_port # check if grafana is running
  request_path        = "/login"
}

resource "google_compute_forwarding_rule" "load_balancer_kubernetes_masters" {
  provider              = google
  project               = var.project
  name                  = "load-balancer-kubernetes-masters"
  target                = google_compute_target_pool.kubernetes_masters_target_pool.self_link
  load_balancing_scheme = "INTERNAL"
  port_range            = null
  ip_address            = google_compute_address.static_ip_load_balancer_masters.self_link
  ip_protocol           = "TCP"
  network_tier          = "PREMIUM"
  subnetwork            = google_compute_subnetwork.kubernetes_subnetwork.self_link
}

resource "google_compute_target_pool" "kubernetes_masters_target_pool" {
  provider         = google
  project          = var.project
  name             = "kubernetes-masters-target-pool"
  region           = var.region
  session_affinity = "NONE"
  instances        = google_compute_instance.kubernetes_masters.*.self_link
  health_checks    = [google_compute_http_health_check.kubernetes_masters_target_pool_health_check.self_link]
}

resource "google_compute_http_health_check" "kubernetes_masters_target_pool_health_check" {
  provider            = google
  project             = var.project
  name                = "kubernetes-masters-target-pool-health-check"
  timeout_sec         = 1
  check_interval_sec  = 1
  healthy_threshold   = 4
  unhealthy_threshold = 2
  port                = 6443 # check if kubernetes api is running
  request_path        = "/"
}
