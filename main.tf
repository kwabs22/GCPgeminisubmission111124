# main.tf

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 4.0" #Adjust the version as needed
    }
  }
}

provider "google" {
  project = var.project_id
  region = var.region
}

resource "google_storage_bucket" "website_bucket" {
  name = var.bucket_name
  location = var.region
  storage_class = "STANDARD"
  force_destroy = true
  uniform_bucket_level_access = true
  
  website {
    main_page_suffix = "index.html"
    not_found_page = "404.html"
  }
}

resource "google_storage_bucket_iam_member" "public_access" {
  bucket = google_storage_bucket.website_bucket.name
  role = "roles/storage.objectViewer"
  member = "allUsers"
}

# Daya source to get the list of files
data "local_file" "website_files" {
  for_each = fileset(var.website_files_path, "**/*.*")

  filename = "${var.website_files_path}/${each.value}"
}

#Force index as text/htl
resource "google_storage_bucket_object" "index_html" {
  name = "index.html"
  bucket = google_storage_bucket.website_bucket.name
  source = "${var.website_files_path}/index.html"
  content_type = "text/html"
}

#Upload webfie files
resource "google_storage_bucket_object" "website_files" {
  for_each = data.local_file.website_files

  name = each.key
  bucket = google_storage_bucket.website_bucket.name
  source = each.value.filename

  #Set the content type based on file extention
  content_type = lookup({
    "html" = "text/html"
    "css" = "text/css"
    "js" = "application/javascript"
    "png" = "image/png"
    "jpg" = "image/jpeg"
    "jpeg" = "image/jpeg"
    "gif" = "image/gif"
    "svg" = "image/svg+xml"
  }, lower(replace(each.key, ".*\\.", "")), "application/octet-stream")
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "function.zip"
  bucket = google_storage_bucket.website_bucket.name
  source = var.function_zip_source_dir  # Local path to your zip file
}

resource "google_cloudfunctions_function" "function" {
  name = var.function_name
  description = "A Cloud Function"
  runtime = var.runtime
  available_memory_mb = var.function_memory
  entry_point = var.function_entry_point

  source_archive_bucket = google_storage_bucket.website_bucket.name
  source_archive_object = google_storage_bucket_object.function_zip.name

  trigger_http = var.trigger_http

  #Set the HTTPS trigger URL as the output
  depends_on = [google_project_service.enable_cloud_functions]
}

#Enable Cloud Functions API
resource "google_project_service" "enable_cloud_functions" {
  service = "cloudfunctions.googleapis.com"
}

resource "google_project_service" "enable_cloud_build" {
  service = "cloudbuild.googleapis.com"
}

#Output the cloud function URL
output "function_url" {
  value = google_cloudfunctions_function.function.https_trigger_url
}

# Allow unauthenticated invocations
resource "google_cloudfunctions_function_iam_member" "noauth_invoker" {
  project = google_cloudfunctions_function.function.project
  region = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role = "roles/cloudfunctions.invoker"
  member = "allUsers"
}
