
variable "network_id" {
  type = string
}

variable "project_id" {
  type = string
}

variable "cloud_sql_instance_name" {
  type = string
}

variable "prefix" {
  type = string
  description = "Prefix for naming the project and other resources"
  default = "cesar-team"
}

variable "database_version" {
    type = string
    description = "Database version for app"
    default = "MYSQL_5_7"
}

variable "database_tier" {
    type = string
    description = "Database tier for app"
    default = "db-f1-micro"
}

variable "database_name" {
    type = string
    description = "Name of database for app"
    default = "cesar-test"
}

variable "region" {
  type = string
}
variable "email" {
  type = string
}