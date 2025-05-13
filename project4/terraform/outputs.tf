output "vm_external_ip" {
  value = google_compute_instance.gallery_app.network_interface[0].access_config[0].nat_ip
  description = "Flask VM Public IP"
}