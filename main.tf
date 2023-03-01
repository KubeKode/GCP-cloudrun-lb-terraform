terraform{

}
provider "google" {
  project = var.project_id
  region  = "us-central1"
  zone    = "us-central1-c"
}
resource "google_cloud_run_service" "my_service" {
  name     = "my-service"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"
      }
    }
  }
}
data "google_iam_policy" "admin" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}
resource "google_cloud_run_service_iam_policy" "my_service_invoker" {
  location    = google_cloud_run_service.my_service.location
  project     = google_cloud_run_service.my_service.project
  service     = google_cloud_run_service.my_service.name
  policy_data = data.google_iam_policy.admin.policy_data
}
resource "google_compute_backend_service" "my_backend_service" {
  name             = "my-backend-service"
  backend {
    group = google_compute_region_network_endpoint_group.cloudrun_neg.id
  }
  project = var.project_id
}
resource "google_compute_region_network_endpoint_group" "cloudrun_neg" {
  name                  = "cloudrun-neg"
  network_endpoint_type = "SERVERLESS"
  region                = "us-central1"
  cloud_run {
    service = google_cloud_run_service.my_service.name
  }
}
resource "google_compute_url_map" "my_url_map" {
  name        = "my-url-map"
  default_service = google_compute_backend_service.my_backend_service.self_link
  project     = var.project_id
}
resource "google_compute_target_http_proxy" "my_target_proxy" {
  name          = "my-target-proxy"
  url_map       = google_compute_url_map.my_url_map.self_link
  project       = var.project_id
}
resource "google_compute_global_forwarding_rule" "my_forwarding_rule" {
  name        = "my-forwarding-rule"
  port_range  = "80"
  target      = google_compute_target_http_proxy.my_target_proxy.self_link
  ip_protocol = "TCP"
}


variable "project_id" {
  
}