terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# GCS Bucket for data lake
resource "google_storage_bucket" "data_lake" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
}

# BigQuery dataset for warehouse
resource "google_bigquery_dataset" "warehouse" {
  dataset_id                  = var.dataset_name
  location                    = var.region
  delete_contents_on_destroy = true
}