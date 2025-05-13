output "vm_external_ip" {
  value = google_compute_instance.flask-vm.network_interface[0].access_config[0].nat_ip
  description = "Flask VM Public IP"
}