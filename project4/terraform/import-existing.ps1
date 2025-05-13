# Set your project ID
$projectId = "finalcloudcomputing-459617"

# Import Cloud SQL instance if it exists
$sqlInstanceName = "gallery-sql-db"
$sqlInstanceCheck = gcloud sql instances list --filter="name=$sqlInstanceName" --format="value(name)"

if ($sqlInstanceCheck) {
    Write-Host "Importing Cloud SQL instance..."
    terraform import google_sql_database_instance.gallery_sql_db "projects/$projectId/instances/$sqlInstanceName"
}

# Import Firewall rule if it exists
$firewallName = "allow-http-https"
$firewallCheck = gcloud compute firewall-rules list --filter="name=$firewallName" --format="value(name)"

if ($firewallCheck) {
    Write-Host "Importing Firewall rule..."
    terraform import google_compute_firewall.allow_http_ssh "projects/$projectId/global/firewalls/$firewallName"
}
