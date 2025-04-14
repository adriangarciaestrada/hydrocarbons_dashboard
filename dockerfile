FROM apache/airflow:2.8.1-python3.10

# Start as root to install system packages and Terraform
USER root

# Install required system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    wget \
    gnupg \
    file \
    openjdk-17-jre-headless \
    gcc \
    g++ \
 && rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip && \
    unzip terraform_1.6.6_linux_amd64.zip && \
    mv terraform /usr/local/bin/terraform && \
    chmod +x /usr/local/bin/terraform && \
    rm terraform_1.6.6_linux_amd64.zip

# Optional: create terraform working directory
RUN mkdir -p /app/terraform && chown -R airflow: /app/terraform

# Copy entrypoint and make it executable
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh && chown airflow: /app/entrypoint.sh

COPY scripts/dbt_setup.sh /app/scripts/dbt_setup.sh
RUN chmod +x /app/scripts/dbt_setup.sh

# Switch to airflow user before pip install
USER airflow

# Install Python packages (must be done as airflow)
RUN pip install --no-cache-dir \
    pandas \
    openpyxl \
    dbt-bigquery \
    unidecode \
    apache-airflow-providers-google

ENTRYPOINT ["/app/entrypoint.sh"]
