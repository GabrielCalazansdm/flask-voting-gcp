

# Private IP address for Cloud SQL

resource "google_compute_global_address" "private_ip_address" {
  provider = google-beta
  project = var.project_id
  name = "vort-db-ip-address"
  purpose = "VPC_PEERING"
  address_type = "INTERNAL"
  network = var.network_id
  prefix_length = 16
  labels = {
        "name" = "private_ip_address",
        "company" = "cesar-school",
        "data_last_modified" = "27-04-2024",
        "data_uploaded" = formatdate("DD-MM-YYYY",timestamp()),
        "type" = "network"
    }
}

# Private IP connection for DB
resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta
  network = var.network_id
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Generate a random id
resource "random_id" "db_name_suffix" {
  byte_length = 4
}

# Create Cloud SQL instance
resource "google_sql_database_instance" "cesar-team" {
  name = var.cloud_sql_instance_name
  database_version = var.database_version
  region = var.region
  project = var.project_id

  deletion_protection = false

  settings {
    tier = var.database_tier
    ip_configuration {
      ipv4_enabled    = false
      require_ssl     = false
      private_network = var.network_id
    }
    database_flags {
      name  = "cloudsql_iam_authentication"
      value = "on"
    }
    backup_configuration {
      enabled = true
      binary_log_enabled = true
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Create a database instance
resource "google_sql_database" "database" {
  name = var.database_name
  instance = google_sql_database_instance.cesar-team.name
  project = var.project_id
}

# Set the root password
resource "random_password" "mysql_root" {
    length = 16
    special = true
}

resource "google_sql_user" "root" {
  name = "root"
  instance = google_sql_database_instance.cesar-team.name
  type = "BUILT_IN"
  project = var.project_id
  password = random_password.mysql_root.result
}

# Grant service account access to Cloud SQL as a client
resource "google_sql_user" "cesar-team" {
  name = var.email
  instance = google_sql_database_instance.cesar-team.name
  type = "CLOUD_IAM_SERVICE_ACCOUNT"
  project = var.project_id
}

resource "google_project_iam_member" "sql_client" {
    project = var.project_id
    role = "roles/cloudsql.client"
    member = "serviceAccount:${var.email}"
}

resource "google_project_iam_member" "sql_instance" {
    project = var.project_id
    role = "roles/cloudsql.instanceUser"
    member = "serviceAccount:${var.email}"
}
