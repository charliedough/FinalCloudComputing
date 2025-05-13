terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.34.1"
    }
  }
  backend "gcs" {
    bucket = "gallery-app-terraform-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = "gallery-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
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
resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
  description   = "Allow HTTP, HTTPS, and Flask port access"
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
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Cloud SQL Instance
resource "google_sql_database_instance" "gallery_db" {
  name             = "gallery-db"
  database_version = "MYSQL_8_0"
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-n1-standard-1"
    ip_configuration {
      ipv4_enabled = true
      private_network = google_compute_network.vpc_network.id
    }
    backup_configuration {
      enabled = true
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]

  lifecycle {
    create_before_destroy = true
  }
}

# Database
resource "google_sql_database" "gallery" {
  name     = "gallery"
  instance = google_sql_database_instance.gallery_db.name

  lifecycle {
    create_before_destroy = true
  }
}

# Database User
resource "google_sql_user" "gallery_user" {
  name     = var.db_username
  password = var.db_password
  instance = google_sql_database_instance.gallery_db.name

  lifecycle {
    create_before_destroy = true
  }
}

# Cloud Storage Bucket
resource "google_storage_bucket" "gallery_bucket" {
  name          = "gallery-db"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle {
    create_before_destroy = true
  }
}

# Compute Instance
resource "google_compute_instance" "gallery_app" {
  name         = "gallery-app"
  machine_type = "e2-standard-2"
  zone         = var.zone
  tags         = ["https-server", "gallery-app"]

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
      bucket_name          = google_storage_bucket.gallery_bucket.name
      app_repo_url         = var.app_repo_url
      app_repo_branch      = var.app_repo_branch
      db_username          = var.db_username
      db_password          = var.db_password
      region              = var.region
    })
  }

  network_interface {
    subnetwork = google_compute_subnetwork.default.id
    access_config {
      // Ephemeral public IP
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Outputs
output "app_url" {
  value = "http://${google_compute_instance.gallery_app.network_interface[0].access_config[0].nat_ip}:8080"
}

output "bucket_name" {
  value = google_storage_bucket.gallery_bucket.name
} 