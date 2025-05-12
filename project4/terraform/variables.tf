variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone to deploy resources"
  type        = string
  default     = "us-central1-a"
}

variable "db_username" {
  description = "The username for the Cloud SQL database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the Cloud SQL database"
  type        = string
  sensitive   = true
}

variable "app_repo_url" {
  description = "The URL of the application repository"
  type        = string
  default     = "https://github.com/charliedough/FinalCloudComputing.git"
}

variable "app_repo_branch" {
  description = "The branch of the application repository to use"
  type        = string
  default     = "main"
} 