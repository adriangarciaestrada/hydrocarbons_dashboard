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
      project: hydrocarbons-insights-dev
      dataset: hydrocarbons_dataset
      threads: 4
      keyfile: /opt/airflow/google/google_credentials.json
" > /home/airflow/.dbt/profiles.yml

echo "✅ dbt profile created for hydrocarbons_dashboard"
