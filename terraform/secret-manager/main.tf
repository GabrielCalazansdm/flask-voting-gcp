
resource "google_secret_manager_secret" "cesar-team-secret" {
  provider = google-beta
  project = var.project_id
  secret_id = "cesar-team-token"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
      replicas {
        location = "us-east1"
      }
    }
  }
  labels = {
        label = "cesar-team-sql-connect"
        "name" = "runner-secrets",
        "company" = "cesar-school",
        "data_last_modified" = "27-04-2024",
        "data_uploaded" = formatdate("DD-MM-YYYY",timestamp()),
        "type" = "secret"
    }
}

variable "subnet_ip" {
  type        = string
  default     = "10.12.12.0/24"
}
resource "google_secret_manager_secret_version" "cesar-team-secret-version" {
  provider = google-beta
  secret   = google_secret_manager_secret.cesar-team-secret.id
  secret_data = jsonencode({
    "DB_USER" = var.db-user
    "DB_PASS" = var.db-pass
    "DB_NAME" = var.db-name
    "DB_HOST" = var.db-host
  })
}

resource "google_secret_manager_secret_iam_member" "cesar-team-secret-member" {
  provider  = google-beta
  project   = var.project_id
  secret_id = google_secret_manager_secret.cesar-team-secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.email}"
}