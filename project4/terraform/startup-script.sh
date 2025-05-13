#!/bin/bash

# Update system and install dependencies
apt-get update
apt-get install -y python3-pip python3-venv git wget

# Create application directory
mkdir -p /opt/gallery-app
cd /opt/gallery-app

# Install Cloud SQL Auth proxy
wget https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.1/cloud-sql-proxy.linux.amd64 -O /usr/local/bin/cloud-sql-proxy
chmod +x /usr/local/bin/cloud-sql-proxy

# Clone the application repository
git clone ${app_repo_url} .
git checkout ${app_repo_branch}

# Move files from project4 to root directory
mv project4/* .
mv project4/.* . 2>/dev/null || true
rmdir project4

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install application dependencies
pip install -r requirements.txt

# Create environment file
cat > .env << EOL
GOOGLE_CLOUD_PROJECT=${project_id}
GCS_BUCKET_NAME=${bucket_name}
FLASK_SECRET_KEY=$(openssl rand -hex 32)
CLOUD_SQL_USERNAME=${db_username}
CLOUD_SQL_PASSWORD=${db_password}
CLOUD_SQL_DATABASE_NAME=gallery
CLOUD_SQL_CONNECTION_NAME=$(gcloud sql instances describe gallery-db-20250512103216 \
  --project=${project_id} \
  --format="value(connectionName)")
DB_HOST=127.0.0.1
DB_PORT=3306
EOL

# Create Cloud SQL proxy service
cat > /etc/systemd/system/cloud-sql-proxy.service << EOL
[Unit]
Description=Cloud SQL Auth Proxy
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloud-sql-proxy --unix-socket /var/run/cloud-sql-proxy.sock ${project_id}:us-central1:gallery-db-20250512103216
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Create systemd service
cat > /etc/systemd/system/gallery-app.service << EOL
[Unit]
Description=Gallery Application
After=network.target cloud-sql-proxy.service
Requires=cloud-sql-proxy.service

[Service]
User=root
WorkingDirectory=/opt/gallery-app
Environment="PATH=/opt/gallery-app/venv/bin"
ExecStart=/opt/gallery-app/venv/bin/python main.py
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Enable and start services
systemctl enable cloud-sql-proxy
systemctl start cloud-sql-proxy
systemctl enable gallery-app
systemctl start gallery-app

# Add health check endpoint
cat > /opt/gallery-app/health.py << EOL
from flask import Flask
from google.cloud import storage
import os

app = Flask(__name__)

@app.route('/health')
def health_check():
    try:
        # Test storage connection
        storage_client = storage.Client()
        bucket = storage_client.bucket(os.getenv('GCS_BUCKET_NAME'))
        bucket.exists()

        return 'OK', 200
    except Exception as e:
        return str(e), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8081)
EOL

# Create health check service
cat > /etc/systemd/system/gallery-health.service << EOL
[Unit]
Description=Gallery Application Health Check
After=network.target

[Service]
User=root
WorkingDirectory=/opt/gallery-app
Environment="PATH=/opt/gallery-app/venv/bin"
Environment="VIRTUAL_ENV=/opt/gallery-app/venv"
ExecStart=/opt/gallery-app/venv/bin/python /opt/gallery-app/health.py
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Enable and start health check service
systemctl enable gallery-health
systemctl start gallery-health 