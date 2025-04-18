#!/bin/bash

# Optional: only run terraform if directory exists
if [ -d "/app/terraform" ]; then
    echo "Terraform directory found. Running Terraform..."
    cd /app/terraform
    terraform init
    terraform apply -auto-approve
else
    echo "Terraform directory not found. Skipping Terraform setup."
fi

# DBT setup 👇
if [ ! -f /opt/airflow/dbt/hydrocarbons_dbt/dbt_project.yml ]; then
    echo "Running dbt setup..."
    /app/scripts/dbt_setup.sh
fi

# Set GCP credentials environment variable for all subprocesses
export GOOGLE_APPLICATION_CREDENTIALS="/opt/airflow/google/google_credentials.json"
export GCP_PROJECT_ID="your_project_ID" #YOUR GCP PROJECT ID HERE

# Initialize or migrate the Airflow DB
airflow db migrate

# If this container is the webserver, create the admin user
if [[ "$1" == "webserver" ]]; then
    echo "Creating Airflow admin user..."
    airflow users create \
        --username admin \
        --firstname Admin \
        --lastname User \
        --role Admin \
        --email admin@example.com \
        --password admin

    echo "Ensuring default pool exists..."
    airflow pools set default_pool 128 "Default pool for DAGs"
fi

# Run the actual Airflow command passed as CMD (e.g., webserver/scheduler)
exec airflow "$@"