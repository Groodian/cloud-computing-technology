resource "google_compute_forwarding_rule" "load_balancer" {
  provider              = google
  project               = var.project
  name                  = "load-balancer"
  target                = google_compute_target_pool.kubernetes_target_pool.self_link
  load_balancing_scheme = "EXTERNAL"
  port_range            = null
  ip_address            = google_compute_address.static_ip_load_balancer.self_link
  ip_protocol           = "TCP"
  network_tier          = "PREMIUM"
}

resource "google_compute_target_pool" "kubernetes_target_pool" {
  provider         = google
  project          = var.project
  name             = "kubernetes-target-pool"
  region           = var.region
  session_affinity = "NONE"
  instances        = concat(google_compute_instance.kubernetes_worker.*.self_link, [google_compute_instance.kubernetes_master.self_link])
  health_checks    = [google_compute_http_health_check.kubernetes_target_pool_health_check.self_link]
}

resource "google_compute_http_health_check" "kubernetes_target_pool_health_check" {
  provider            = google
  project             = var.project
  name                = "kubernetes-target-pool-health-check"
  timeout_sec         = 1
  check_interval_sec  = 1
  healthy_threshold   = 4
  unhealthy_threshold = 2
  port                = 31000 # check if grafana is running
  request_path        = "/login"
}
