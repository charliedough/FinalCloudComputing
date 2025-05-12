import os
from dotenv import load_dotenv

load_dotenv()

# Google Cloud SQL Connection
DB_USER = os.environ.get("CLOUD_SQL_USERNAME")
DB_PASSWORD = os.environ.get("CLOUD_SQL_PASSWORD")

DB_NAME = os.environ.get("CLOUD_SQL_DATABASE_NAME")
DB_INSTANCE_CONNECTION_NAME = os.environ.get("CLOUD_SQL_CONNECTION_NAME")

# Google Cloud Storage
GOOGLE_CLOUD_PROJECT = os.environ.get("GOOGLE_CLOUD_PROJECT")
GCS_BUCKET_NAME = os.environ.get("GCS_BUCKET_NAME")


class Config:
    # Google Cloud SQL Connection
    DB_USER = DB_USER
    DB_PASSWORD = DB_PASSWORD

    DB_NAME = DB_NAME
    DB_INSTANCE_CONNECTION_NAME = DB_INSTANCE_CONNECTION_NAME

    # Google Cloud Storage
    GOOGLE_CLOUD_PROJECT = GOOGLE_CLOUD_PROJECT
    GCS_BUCKET_NAME = GCS_BUCKET_NAME
