# Ensure you are in the correct directory with your terraform files
Set-Location "C:\users\dorts\422\FinalCloudComputing\project4\terraform"

# Destroy Compute Instance
Write-Host "Destroying Compute Instance..."
terraform destroy --target=google_compute_instance.gallery_app -auto-approve

# Destroy Cloud SQL Database
Write-Host "Destroying Cloud SQL Database..."
terraform destroy --target=google_sql_database.gallery -auto-approve

# Destroy Cloud SQL User
Write-Host "Destroying Cloud SQL User..."
terraform destroy --target=google_sql_user.gallery_user -auto-approve

# Destroy Cloud SQL Instance
Write-Host "Destroying Cloud SQL Instance..."
terraform destroy --target=google_sql_database_instance.gallery_db -auto-approve

# Destroy Service Networking Connection
Write-Host "Destroying Service Networking Connection..."
terraform destroy --target=google_service_networking_connection.private_vpc_connection -auto-approve

# Destroy all remaining resources
Write-Host "Destroying all remaining resources..."
terraform destroy --auto-approve

Write-Host "Terraform destroy completed."
