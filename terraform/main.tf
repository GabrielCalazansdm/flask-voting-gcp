# Create a service account

resource "google_service_account" "service_account" {
  account_id   = local.gcp_service_account_name
  display_name = local.gcp_service_account_name
  project      = var.project_id
}

# RSA key of size 4096 bits
resource "tls_private_key" "rsa-4096" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "google_project_service" "project_service" {
  project = var.project_id
  service = "iap.googleapis.com"
}


resource "tls_self_signed_cert" "self_signed_cert" {
  private_key_pem = tls_private_key.rsa-4096.private_key_pem

  subject {
    common_name  = "certificate"
    organization = "Cesar"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

module "network" {
  source = "./network"
  network_name = var.network_name
  project_id = var.project_id
  subnet_name = var.subnet_name
  region = var.region
}

module "dataset" {
  source = "./database"
  network_id = module.network.id
  project_id = var.project_id
  prefix = var.prefix
  region = var.region
  email = google_service_account.service_account.email
  cloud_sql_instance_name = local.cloud_sql_instance_name
}

module "secret" {
  source = "./secret-manager"
  project_id = var.project_id
  region = var.region
  db-user = "root"
  db-pass = module.dataset.random_password
  db-name = module.dataset.database_name
  db-host = "${module.dataset.private_ip_address}:3306"
  email = google_service_account.service_account.email
}

module "mig_template" {
  source = "terraform-google-modules/vm/google//modules/instance_template"
  version = "~> 7.0"
  project_id = var.project_id
  machine_type = var.machine_type
  network = var.network_name
  subnetwork = var.subnet_name
  region = var.region
  subnetwork_project = var.project_id
  service_account = {
    email = google_service_account.service_account.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
  disk_size_gb = 10
  disk_type = "pd-ssd"
  auto_delete = true
  name_prefix = var.instance_name
  source_image_family  = var.source_image_family
  source_image_project = var.source_image_project
  startup_script = file("${path.module}/scripts/startup.sh")
  source_image = var.source_image
  metadata = {
    "secret-id" = module.secret.name
  }
  tags = [
    "cesar-team-runner-vm", "https-server", "allow-health-check"
  ]
  labels = {
        "name" = "grupo-gerenciado-de-instancias",
        "company" = "cesar-school",
        "data_last_modified" = "27-04-2024",
        "data_uploaded" = formatdate("DD-MM-YYYY",timestamp()),
        "type" = "template"
    }
}

module "mig" {
  source = "terraform-google-modules/vm/google//modules/mig"
  version = "~> 7.0"
  project_id = var.project_id
  subnetwork_project = var.project_id
  hostname = var.instance_name
  region = var.region
  instance_template = module.mig_template.self_link
  target_size = var.target_size
  health_check = { 
    "check_interval_sec": 30,
     "enable_logging": true, 
     "healthy_threshold": 1, 
     "host": "", 
     "initial_delay_sec": 30, 
     "port": 50, 
     "proxy_header": "NONE", 
     "request": "", 
     "request_path": "/",
     "response": "", 
     "timeout_sec": 10, "type": "", 
     "unhealthy_threshold": 5 
  }
  autoscaling_enabled = true
  cooldown_period     = var.cooldown_period
}

# Load Balancer

module "lb-http" {
    source  = "GoogleCloudPlatform/lb-http/google"
  version = "~> 5.0"
  name    = var.prefix
  project = var.project_id
  target_tags = [
    module.network.nat_name,
    module.network.subnetwork_name
  ]
  ssl = true
  private_key = tls_private_key.rsa-4096.private_key_pem
  certificate = tls_self_signed_cert.self_signed_cert.cert_pem
  firewall_networks = [module.network.name]
  backends = {
    default = {
      description                     = null
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 10
      connection_draining_timeout_sec = null
      enable_cdn                      = false
      security_policy                 = null
      session_affinity                = null
      affinity_cookie_ttl_sec         = null
      custom_request_headers          = null
      custom_response_headers         = null

      health_check = {
        check_interval_sec  = null
        timeout_sec         = null
        healthy_threshold   = null
        unhealthy_threshold = null
        request_path        = "/"
        port                = 80
        host                = null
        logging             = null
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          group                        = module.mig.instance_group
          balancing_mode               = null
          capacity_scaler              = null
          description                  = null
          max_connections              = null
          max_connections_per_instance = null
          max_connections_per_endpoint = null
          max_rate                     = null
          max_rate_per_instance        = null
          max_rate_per_endpoint        = null
          max_utilization              = null
        },
      ]

      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
    }
  }
}