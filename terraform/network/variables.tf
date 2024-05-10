
variable "network_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "subnet_ip" {
  type        = string
  default     = "10.12.12.0/24"
}