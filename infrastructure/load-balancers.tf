resource "google_compute_forwarding_rule" "load_balancer_kubernetes_workers" {
  provider              = google
  project               = var.project
  name                  = "load-balancer-kubernetes-workers"
  target                = google_compute_target_pool.kubernetes_workers_target_pool.self_link
  load_balancing_scheme = "EXTERNAL"
  all_ports             = true
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
  load_balancing_scheme = "INTERNAL_MANAGED"
  ports                 = ["6443"]
  ip_address            = google_compute_address.static_ip_load_balancer_masters.self_link
  ip_protocol           = "TCP"
  network_tier          = "PREMIUM"
  subnetwork            = google_compute_subnetwork.kubernetes_subnetwork.self_link
  target                = google_compute_region_target_tcp_proxy.kubernetes_masters_target_tcp_proxy.self_link
  region                = var.region
}

resource "google_compute_region_backend_service" "kubernetes_masters_backend_service" {
  name                  = "kubernetes-masters-backend-service"
  region                = var.region
  load_balancing_scheme = "INTERNAL_MANGED"
  protocol              = "TCP"
  session_affinity      = "NONE"
  health_checks         = [google_compute_region_health_check.kubernetes_masters_health_check.self_link]

  backend {
    group                        = google_compute_instance_group.kubernetes_masters_instance_group.self_link
    balancing_mode               = "CONNECTION"
  }
}

resource "google_compute_region_target_tcp_proxy" "kubernetes_masters_target_tcp_proxy" {
  provider        = google-beta
  name            = "kubernetes-masters-target-tcp-proxy"
  region          = var.region
  backend_service = google_compute_region_backend_service.kubernetes_masters_backend_service.self_link
  proxy_header    = "NONE"
}

resource "google_compute_instance_group" "kubernetes_masters_instance_group" {
  name      = "kubernetes-masters-instance-group"
  zone      = var.zone
  instances = google_compute_instance.kubernetes_masters.*.id
}

resource "google_compute_region_health_check" "kubernetes_masters_health_check" {
  name                = "kubernetes-masters-health-check"
  region              = var.region
  timeout_sec         = 1
  check_interval_sec  = 1
  healthy_threshold   = 4
  unhealthy_threshold = 2

  tcp_health_check {
    port = 6443
  }
}
