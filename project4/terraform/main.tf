provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = "gallery-vpc"
  description             = "Custom VPC for Gallery App"
}

# Subnet
resource "google_compute_subnetwork" "default" {
  name                     = "gallery-subnet"
  ip_cidr_range           = "10.0.0.0/16"
  region                  = var.region
  network                 = google_compute_network.vpc_network.id
  private_ip_google_access = true
}

# Firewall Rules
resource "google_compute_firewall" "allow_http_ssh" {
  name    = "allow-http-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh", "http-server"]
  description   = "Allow HTTP and SSH port access"
}

# Service Account
resource "google_service_account" "gallery_app" {
  account_id   = "gallery-app-sa"
  display_name = "Gallery Application Service Account"
}

# IAM Roles for Service Account
resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.gallery_app.email}"
}

resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.gallery_app.email}"
}

# VPC Peering for Service Networking
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  depends_on = [
    google_compute_global_address.private_ip_address, # Reserve IP range first
    google_project_service.sql_admin # Ensure API is enabled
  ]
  provider                = google
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Cloud SQL Instance
resource "google_sql_database_instance" "gallery_sql_db" {
  depends_on = [
    google_service_networking_connection.private_vpc_connection, # VPC peering must exist first
    google_project_service.sql_admin # Ensure SQL Admin API is enabled
  ]
  name             = "gallery-sql-db"
  database_version = "MYSQL_8_0"
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled = false
      enable_private_path_for_google_cloud_services = true

      private_network = google_compute_network.vpc_network.self_link
    }
    backup_configuration {
      enabled = true
    }
  }
}

# Database
resource "google_sql_database" "gallery_db" {
  name     = "gallery"
  instance = google_sql_database_instance.gallery_sql_db.name
}

# Database User
resource "google_sql_user" "gallery_user" {
  name     = var.db_username
  password = var.db_password
  instance = google_sql_database_instance.gallery_sql_db.name
}

# Admin User
resource "google_project_service" "sql_admin" {
  project = var.project_id
  service = "sqladmin.googleapis.com"
}

# Cloud Storage Bucket
resource "google_storage_bucket" "flask_gallery_bucket" {
  name          = "gallery-bucket-${random_id.suffix.hex}"
  location      = var.region
  force_destroy = true
  storage_class = "STANDARD"
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "google_storage_bucket_iam_member" "public" {
  bucket = google_storage_bucket.flask_gallery_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Compute Instance
resource "google_compute_instance" "gallery_app" {
  name         = "gallery-app-flask"
  machine_type = "e2-standard-2"
  zone         = var.zone
  tags         = ["https-server", "gallery-app", "http-server"]
  deletion_protection = false

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  service_account {
    email  = google_service_account.gallery_app.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    startup-script = templatefile("${path.module}/startup-script.sh", {
      project_id           = var.project_id
      bucket_name          = google_storage_bucket.flask_gallery_bucket.name
      app_repo_url         = var.app_repo_url
      app_repo_branch      = var.app_repo_branch
      db_username          = var.db_username
      db_password          = var.db_password
      region              = var.region
    })
  }

  network_interface {
    network = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.default.id
    access_config {
      // Ephemeral public IP
    }
  }
}

# Outputs
output "app_url" {
  value = "http://${google_compute_instance.gallery_app.network_interface[0].access_config[0].nat_ip}:8080"
}

output "bucket_name" {
  value = google_storage_bucket.flask_gallery_bucket.name
} 