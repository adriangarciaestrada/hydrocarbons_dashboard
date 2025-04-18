variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "your_project_ID" #YOUR GCP PROJECT ID HERE
}

variable "region" {
  description = "Region for GCS and BigQuery"
  type        = string
  default     = "your_region" #YOUR BIGQUERY DATASET HERE
}

variable "bucket_name" {
  description = "Google Cloud Storage bucket name"
  type        = string
  default     = "your_bucket_name" #YOUR BUCKET NAME HERE (MAKE SURE ITS GLOBALLY UNIQUE)
}

variable "dataset_name" {
  description = "BigQuery dataset name"
  type        = string
  default     = "your_dataset" #YOUR DATASET NAME HERE
}
