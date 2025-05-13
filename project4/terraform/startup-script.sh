#!/bin/bash

# Update system and install dependencies
apt-get update
apt-get install -y python3-pip python3-venv git wget

# Create application directory
mkdir -p /opt/gallery-app
cd /opt/gallery-app

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
CLOUD_SQL_CONNECTION_NAME=${project_id}:us-central1:gallery-sql-db
DB_HOST=127.0.0.1
DB_PORT=3306
EOL

# Create systemd service
cat > /etc/systemd/system/gallery-app.service << EOL
[Unit]
Description=Gallery Application

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
systemctl enable gallery-app
systemctl start gallery-app