flowchart RL
  %% Nodes
  google_compute_firewall_allow_http_ssh["google_compute_firewall.allow_http_ssh"]
  google_compute_global_address_private_ip_address["google_compute_global_address.private_ip_address"]
  google_compute_instance_gallery_app["google_compute_instance.gallery_app"]
  google_compute_network_vpc_network["google_compute_network.vpc_network"]
  google_compute_subnetwork_default["google_compute_subnetwork.default"]
  google_project_iam_member_cloudsql_client["google_project_iam_member.cloudsql_client"]
  google_project_iam_member_storage_admin["google_project_iam_member.storage_admin"]
  google_project_service_sql_admin["google_project_service.sql_admin"]
  google_service_account_gallery_app["google_service_account.gallery_app"]
  google_service_networking_connection_private_vpc_connection["google_service_networking_connection.private_vpc_connection"]
  google_sql_database_gallery_db["google_sql_database.gallery_db"]
  google_sql_database_instance_gallery_sql_db["google_sql_database_instance.gallery_sql_db"]
  google_sql_user_gallery_user["google_sql_user.gallery_user"]
  google_storage_bucket_flask_gallery_bucket["google_storage_bucket.flask_gallery_bucket"]
  google_storage_bucket_iam_member_public["google_storage_bucket_iam_member.public"]
  random_id_suffix["random_id.suffix"]

  %% Edges
  google_compute_firewall_allow_http_ssh --> google_compute_network_vpc_network
  google_compute_global_address_private_ip_address --> google_compute_network_vpc_network
  google_compute_instance_gallery_app --> google_compute_subnetwork_default
  google_compute_instance_gallery_app --> google_service_account_gallery_app
  google_compute_instance_gallery_app --> google_storage_bucket_flask_gallery_bucket
  google_compute_subnetwork_default --> google_compute_network_vpc_network
  google_project_iam_member_cloudsql_client --> google_service_account_gallery_app
  google_project_iam_member_storage_admin --> google_service_account_gallery_app
  google_service_networking_connection_private_vpc_connection --> google_compute_global_address_private_ip_address
  google_service_networking_connection_private_vpc_connection --> google_project_service_sql_admin
  google_sql_database_gallery_db --> google_sql_database_instance_gallery_sql_db
  google_sql_database_instance_gallery_sql_db --> google_service_networking_connection_private_vpc_connection
  google_sql_user_gallery_user --> google_sql_database_instance_gallery_sql_db
  google_storage_bucket_flask_gallery_bucket --> random_id_suffix
  google_storage_bucket_iam_member_public --> google_storage_bucket_flask_gallery_bucket
