from flask import Flask, render_template, request, redirect, url_for
from flask_login import (
    LoginManager,
    login_user,
    login_required,
    logout_user,
    current_user,
)
from config import Config
import db

app = Flask(__name__)
app.config.from_object(Config)
login_manager = LoginManager(app)
login_manager.login_view = "login"


@login_manager.user_loader
def load_user(user_id):
    return db.get_user_by_id(user_id)


@app.route("/login", methods=["GET", "POST"])
def login():
    if current_user.is_authenticated:
        return redirect(url_for("gallery"))

    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]

        user: db.User = db.get_user_by_username_and_password(username, password)

        if user:
            login_user(user)
            return redirect(url_for("gallery"))

    return render_template("login.html")


@app.route("/logout")
@login_required
def logout():
    logout_user()
    return redirect(url_for("login"))


@app.route("/register", methods=["GET", "POST"])
def register():
    if current_user.is_authenticated:
        return redirect(url_for("gallery"))

    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]

        if db.get_user_by_username(username):
            return render_template("register.html", error="Username already exists")

        db.create_user(username, password)

        return redirect(url_for("login"))

    return render_template("register.html")


@app.route("/upload", methods=["GET", "POST"])
@login_required
def upload():
    if request.method == "POST":
        file = request.files["file"]
        description = request.form["description"]

        db.create_photo(file, description, current_user.id)
        return redirect(url_for("gallery"))

    return render_template("upload.html")


@app.route("/")
@login_required
def gallery():
    photos_list = db.get_photos(request.args.get("search", ""))

    return render_template(
        "gallery.html",
        photos=photos_list,
        gcs_bucket_name=app.config["GCS_BUCKET_NAME"],
    )


@app.route("/download/<filename>")
@login_required
def download(filename):
    return redirect(db.get_photo_url(filename))


@app.route("/delete/<photo_id>", methods=["POST"])
@login_required
def delete(photo_id):
    db.delete_photo(photo_id, current_user.id)

    return redirect(url_for("gallery"))


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8080)
