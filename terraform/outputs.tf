output "instance_name" {
  value = google_compute_instance.vm.name
}

output "instance_self_link" {
  value = google_compute_instance.vm.self_link
}

output "internal_ip" {
  value = try(google_compute_instance.vm.network_interface[0].network_ip, null)
}

output "external_ip" {
  value = try(google_compute_instance.vm.network_interface[0].access_config[0].nat_ip, null)
}