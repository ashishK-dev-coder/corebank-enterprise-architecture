resource "google_container_cluster" "primary" {
  name     = "corebank-production-cluster"
  location = "asia-south1-a" # Using a specific zone saves multi-zone egress costs on your credits

  network    = google_compute_network.gke_vpc.id
  subnetwork = google_compute_subnetwork.gke_subnet.id

  # Deleting the default pool is a GKE security best practice to ensure clear separation
  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = "k8s-pod-range"
    services_secondary_range_name = "k8s-service-range"
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

resource "google_container_node_pool" "production_nodes" {
  name       = "corebank-optimized-node-pool"
  location   = "asia-south1-a"
  cluster    = google_container_cluster.primary.name
  node_count = 3 # Evaluates to exactly 3 robust worker nodes for HA scaling

  node_config {
    preemptible  = false
    machine_type = "e2-standard-2" # 2 vCPU, 8GB RAM per node - mandatory for processing sidecar overlays

    labels = {
      environment = "production"
    }

    tags = ["gke-corebank-node"]

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
