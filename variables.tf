# variables.tf

variable "project_id" {
  description = "The GCP project ID"
}

variable "region" {
  description = "The GCP region"
  default = "us-central1"
}

variable "bucket_name" {
  description = "The name of the GCS bucket"
}

variable "website_files_path" {
  description = "Path to your local website files"
  default = "website"
}

variable "function_name" {
  description = "The name of the cloud function"
  default = "my-cloud-function"
}

variable "function_entry_point" {
  description = "The entry point of the cloud function"
  default = "hello_world"
}

variable "function_source_dir" {
  description = "Path to the cloud function source code"
  default = "function-source"
}

variable "function_zip_source_dir" {
  description = "Path to the cloud function zipped source code"
  default = "function-source/function.zip"
}

variable runtime {
  description = "Runtime for the cloud function"
  default = "python39"
}

variable "trigger_http" {
  description = "Whether the function is triggered via HTTP"
  default = true
}

variable "function_memory" {
  description = "Memory alloated to the cloud function (in MB)"
  default = 128
}
