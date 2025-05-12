import os
import uuid
import sqlalchemy
import config
from sqlalchemy import Column, String, Text, ForeignKey
from sqlalchemy.orm import relationship, sessionmaker, scoped_session
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
from werkzeug.exceptions import BadRequest
from flask_login import UserMixin
from sqlalchemy.ext.declarative import declarative_base
from google.cloud import storage

# When deployed to App Engine, the `GAE_ENV` environment variable will be
if os.environ.get("GAE_ENV") == "standard":
    # If deployed, use the local socket interface for accessing Cloud SQL
    unix_socket = f"/cloudsql/{config.DB_INSTANCE_CONNECTION_NAME}"
    engine_url = "mysql+pymysql://{}:{}@/{}?unix_socket={}".format(
        config.DB_USER, config.DB_PASSWORD, config.DB_NAME, unix_socket
    )
else:
    # If running locally, use the TCP connections instead
    # Set up Cloud SQL Proxy (cloud.google.com/sql/docs/mysql/sql-proxy)
    # so that your application can use 127.0.0.1:3306 to connect to your
    # Cloud SQL instance
    host = "127.0.0.1"
    engine_url = "mysql+pymysql://{}:{}@{}/{}".format(
        config.DB_USER, config.DB_PASSWORD, host, config.DB_NAME
    )

# Initialize Google Cloud SQL
engine = sqlalchemy.create_engine(engine_url, pool_size=3)
Session = scoped_session(sessionmaker(bind=engine))
Base = declarative_base()

# Initialize Google Cloud Storage
Bucket = storage.Client().bucket(config.GCS_BUCKET_NAME)


# region Database Models
class User(Base, UserMixin):
    __tablename__ = "users"
    id = Column(
        sqlalchemy.Integer, primary_key=True, autoincrement=True
    )  # Change to int
    username = Column(String(50), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)  # Adjusted to match DB schema


class Photo(Base):
    __tablename__ = "photos"
    id = Column(sqlalchemy.Integer, primary_key=True, autoincrement=True)
    filename = Column(String(255), nullable=False)
    description = Column(Text)
    user_id = Column(sqlalchemy.Integer, ForeignKey("users.id"), nullable=False)

    # Add relationship to User
    user = relationship("User", backref="photos")


# endregion

# region User Methods


def get_user_by_id(id):
    return Session.query(User).get(id)


def get_user_by_username(username):
    return Session.query(User).filter_by(username=username).first()


def create_user(username, password):
    new_user = User(username=username, password_hash=generate_password_hash(password))

    Session.add(new_user)
    Session.commit()


def get_user_by_username_and_password(username, password):
    user: User = get_user_by_username(username)

    if user and check_password_hash(user.password_hash, password):
        return user


# endregion


# region Photo Methods
def create_photo(file, description, user_id):
    if "." not in file.filename or file.filename.rsplit(".", 1)[1].lower() not in {
        "jpg",
        "jpeg",
        "png",
        "gif",
    }:
        raise BadRequest("File type not allowed")

    new_photo = Photo(
        filename=f"{uuid.uuid4().hex}_{secure_filename(file.filename)}",
        description=description,
        user_id=user_id,
    )

    Bucket.blob(new_photo.filename).upload_from_file(file)

    Session.add(new_photo)
    Session.commit()


def get_photos(search_filter):
    if search_filter:
        return Session.query(Photo).filter(
            Photo.description.ilike(f"%{search_filter}%")
        )

    return Session.query(Photo).all()


def get_photo_url(filename):
    return Bucket.blob(filename).public_url


def delete_photo(photo_id, user_id):
    photo: Photo = Session.query(Photo).get(photo_id)

    if photo and photo.user_id == user_id:
        Session.delete(photo)
        Session.commit()

        if Bucket.blob(photo.filename).exists:
            Bucket.blob(photo.filename).delete()


# endregion
