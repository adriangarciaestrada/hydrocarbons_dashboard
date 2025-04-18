#!/bin/bash

echo "✅ Running dbt setup..."

# Make sure the project directory exists
mkdir -p /opt/airflow/dbt

# Create the dbt profile directory and file
mkdir -p /home/airflow/.dbt

# Create the dbt profile (matches dbt_project.yml: profile: 'hydrocarbons_dashboard')
echo "hydrocarbons_dashboard:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: your_project_ID 
      dataset: your_dataset
      threads: 4
      keyfile: /opt/airflow/google/google_credentials.json
" > /home/airflow/.dbt/profiles.yml

echo "✅ dbt profile created for hydrocarbons_dashboard"


#### Change the fields "project" with your GCP project ID and "dataset" with your BigQuery dataset