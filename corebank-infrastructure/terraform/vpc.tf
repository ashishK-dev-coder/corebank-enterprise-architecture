resource "google_compute_network" "gke_vpc" {
  name                    = "corebank-prod-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke_subnet" {
  name          = "corebank-gke-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = "asia-south1"
  network       = google_compute_network.gke_vpc.id

  # Secondary IP ranges are required for GKE native routing (Alias IPs)
  secondary_ip_range {
    range_name    = "k8s-pod-range"
    ip_cidr_range = "10.1.0.0/16"
  }
  secondary_ip_range {
    range_name    = "k8s-service-range"
    ip_cidr_range = "10.2.0.0/20"
  }
}
