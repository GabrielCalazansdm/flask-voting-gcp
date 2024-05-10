
# Create a VPC for the application
resource "google_compute_network" "cesar-team-network" {
  name = var.network_name
  project = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "cesar-team-subnetwork" {
  project = var.project_id
  name = var.subnet_name
  ip_cidr_range = var.subnet_ip
  region = var.region
  network = google_compute_network.cesar-team-network.name
  
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "cesar-team-nat" {
  name    = "${var.network_name}-router"
  network = google_compute_network.cesar-team-network.self_link
  region  = var.region
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  project = var.project_id
  name = "${var.network_name}-nat"
  router = google_compute_router.cesar-team-nat.name
  region = google_compute_router.cesar-team-nat.region
  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "https" {
  project = var.project_id
  name = "${var.network_name}-https-allow"
  network = google_compute_network.cesar-team-network.name

  allow {
    protocol = "tcp"
    ports = ["80", "443"]
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  target_tags = ["https-server"]
}

resource "google_compute_firewall" "health-check" {
  project = var.project_id
  name = "${var.network_name}-allow-health-check"
  direction = "INGRESS"
  network = google_compute_network.cesar-team-network.name
  priority = 1000
  source_ranges = ["130.211.0.0/22", "35.235.240.0/20", "35.191.0.0/16", "35.190.0.0/16"]
  target_tags = ["allow-health-check"]
  allow {
    ports = ["80", "20", "22"]
    protocol = "tcp"
  }
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}