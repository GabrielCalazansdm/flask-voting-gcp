output "private_ip_address" {
  value = google_sql_database_instance.cesar-team.private_ip_address
}

output "random_password" {
  value = random_password.mysql_root.result
}
output "database_name" {
  value = var.database_name
}