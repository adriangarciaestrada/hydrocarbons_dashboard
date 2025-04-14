variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "hydrocarbons-insights-dev"
}

variable "region" {
  description = "Region for GCS and BigQuery"
  type        = string
  default     = "US"
}

variable "bucket_name" {
  description = "Google Cloud Storage bucket name"
  type        = string
  default     = "hydrocarbons-cnhdata-jage-bucket"
}

variable "dataset_name" {
  description = "BigQuery dataset name"
  type        = string
  default     = "hydrocarbons_dataset"
}
