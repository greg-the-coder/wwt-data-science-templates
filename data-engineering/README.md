# Data Engineering Workspace Template

This template creates a Kubernetes workspace for data engineering with PySpark and various data processing tools.

## Features

- **PySpark Environment**: Uses the Jupyter PySpark container with Spark pre-configured
- **JupyterLab**: Pre-configured JupyterLab environment for interactive development
- **Data Tools**: Includes a variety of data engineering packages for ETL, streaming, and data quality
- **Spark UI**: Access the Spark UI directly from the workspace
- **Workspace Resources**: Configurable CPU and memory resources
- **Persistent Storage**: Persistent home directory for storing datasets and workflows

## Usage

After your workspace starts, you'll have access to:

- JupyterLab at the "Jupyter Lab" application tab
- Spark UI at the "Spark UI" application tab (when a Spark session is active)

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cpu` | CPU cores for the workspace | `4` |
| `memory` | Memory in GB | `8` |
| `home_disk_size` | Size of persistent home directory in GB | `30` |
| `image` | Container image | `jupyter/pyspark-notebook:latest` |

## Libraries Included

- Apache Spark (pre-installed in the image)
- Data processing: boto3
- Data lake: deltalake, lakefs-client
- Streaming: kafka-python
- Storage: minio
- Data quality: great-expectations
- Orchestration: apache-airflow
- Model serving: bentoml
- Kubernetes: kfp, kubernetes
- JupyterLab with ipywidgets

## Notes

- The home directory persists across workspace rebuilds
- The container runs as user `jovyan` (UID 1000), which is the standard user for Jupyter containers
- The Spark UI is only available when a Spark session is active
- Environment variables are configured for Spark integration
- The workspace automatically configures Git with the user's name and email