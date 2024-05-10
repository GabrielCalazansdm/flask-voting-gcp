
variable "project_id" {
  type        = string
}
variable "region" {
  type        = string
  default     = "us-central1"
}

variable "zone" {
  type        = string
  default     = "us-central1-a"
}

variable "prefix" {
  type        = string
  default     = "cesar-team"
}

variable "network_name" {
  type        = string
  default     = "cesar-team-network"
}

variable "subnet_ip" {
  type        = string
  default     = "10.10.10.0/24"
}

variable "subnet_name" {
  type        = string
  default     = "cesar-team-subnet"
}

variable "instance_name" {
  type        = string
  default     = "cesar-team"
}

variable "target_size" {
  type        = number
  default     = 1
}

variable "machine_type" {
  type        = string
  default     = "n1-standard-1"
}

variable "source_image_family" {
  type        = string
  default     = "ubuntu-minimal-2204-lts"
}

variable "source_image_project" {
  type        = string
  default     = "ubuntu-os-cloud"
}

variable "source_image" {
  type        = string
  default     = ""
}

variable "cooldown_period" {
  default     = 60
}

# Random id for naming
resource "random_id" "id" {
  byte_length = 4
  prefix      = var.prefix
}

locals {
  instance_name = "cesar-team-runner-vm"
  gcp_service_account_name = "${var.prefix}-votr-app"
  cloud_sql_instance_name = "${random_id.id.hex}-db"
}