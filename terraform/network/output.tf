output "id" {
  value = google_compute_network.cesar-team-network.id
}
output "name" {
  value = google_compute_network.cesar-team-network.name
}
output "nat_name" {
  value = google_compute_router.cesar-team-nat.name
}
output "subnetwork_name" {
  value = google_compute_subnetwork.cesar-team-subnetwork.name
}
