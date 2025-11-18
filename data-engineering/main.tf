terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "coder" {}

variable "use_kubeconfig" {
  type        = bool
  description = <<-EOF
  Use host kubeconfig? (true/false)

  Set this to false if the Coder host is itself running as a Pod on the same
  Kubernetes cluster as you are deploying workspaces to.

  Set this to true if the Coder host is running outside the Kubernetes cluster
  for workspaces.  A valid "~/.kube/config" must be present on the Coder host.
  EOF
  default     = false
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace to create workspaces in (must exist prior to creating workspaces)."
  default     = "coder"
}

variable "image" {
  type        = string
  description = "Container image for data engineering workspaces"
  default     = "jupyter/pyspark-notebook:latest"
}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU Cores"
  description  = "Number of CPU cores for data processing workloads"
  default      = "4"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "4 Cores"
    value = "4"
  }
  option {
    name  = "8 Cores"
    value = "8"
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory (GB)"
  description  = "Amount of memory in GB"
  default      = "8"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "8 GB"
    value = "8"
  }
  option {
    name  = "16 GB"
    value = "16"
  }
}

data "coder_parameter" "home_disk_size" {
  name         = "home_disk_size"
  display_name = "Home Disk Size (GB)"
  description  = "Size of persistent home directory"
  default      = "30"
  type         = "number"
  mutable      = false
  validation {
    min = 20
    max = 100
  }
}

provider "kubernetes" {
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  os             = "linux"
  arch           = "amd64"
  startup_script = <<-EOT
    #!/bin/bash
    # We'll use set -e but with controlled error handling for pip installs
    # set -e

    echo "Starting data engineering workspace setup..."

    # Configure Git first (no dependencies)
    git config --global user.name "${coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)}"
    git config --global user.email "${data.coder_workspace_owner.me.email}"

    # Function to install packages with error handling
    install_package() {
      local package=$1
      echo "Installing $package..."
      if pip install --no-cache-dir --user "$package"; then
        echo "✓ Successfully installed $package"
      else
        echo "⚠ Failed to install $package, continuing..."
      fi
    }

    # Core data processing packages (skip pyarrow - already in base image)
    echo "Installing core data processing packages..."
    install_package "boto3"

    # Data lake and streaming packages
    echo "Installing data lake and streaming packages..."
    install_package "deltalake"
    install_package "kafka-python"
    install_package "minio"
    install_package "lakefs-client"

    # Data quality and validation
    echo "Installing data quality packages..."
    install_package "great-expectations"

    # Distributed computing and orchestration
    echo "Installing distributed computing packages..."
    pip uninstall apache-airflow -y
    pip install apache-airflow --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.5.3/constraints-3.8.txt"
    pip uninstall structlog -y
    pip install "structlog==25.4.0"

    # Vector database and model serving
    echo "Installing model serving and vector DB packages..."
    install_package "bentoml"

    # Kubernetes and workflow tools
    echo "Installing workflow and deployment packages..."
    install_package "kubernetes"
    install_package "kubeflow-training"

    # Ensure Jupyter widgets are available
    echo "Setting up Jupyter environment..."
    install_package "ipywidgets"

    # Clean up any existing Jupyter processes
    #echo "Cleaning up existing Jupyter processes..."
    #pkill -f jupyter-lab || true
    #sleep 3

    #Upgrade Jupyter dependencies
    pip install --upgrade jsonschema
    pip install --upgrade requests

    # Start JupyterLab with comprehensive configuration
    # Note: Security settings below are optimized for Coder workspace usage
    # where authentication is handled by Coder and access is proxied
    echo "Starting JupyterLab..."
    jupyter lab \
      --ip=0.0.0.0 \
      --port=8888 \
      --no-browser \
      --ServerApp.token='' \
      --ServerApp.password='' \
      --ServerApp.allow_origin='*' \
      --ServerApp.allow_remote_access=True \
      --ServerApp.disable_check_xsrf=True \
      > /tmp/jupyter.log 2>&1 &

    # Wait and verify Jupyter started
    echo "Waiting for JupyterLab to start..."
    sleep 5

    if pgrep -f jupyter-lab > /dev/null; then
      echo "✓ JupyterLab started successfully on port 8888"
      echo "✓ Data Engineering workspace ready!"
    else
      echo "✗ JupyterLab failed to start. Attempting restart..."
      cat /tmp/jupyter.log
      
      # Try a simpler startup
      jupyter lab --ip=0.0.0.0 --port=8888 --no-browser > /tmp/jupyter-simple.log 2>&1 &
      sleep 3
      
      if pgrep -f jupyter-lab > /dev/null; then
        echo "✓ JupyterLab started with basic configuration"
      else
        echo "✗ JupyterLab startup failed completely"
        cat /tmp/jupyter-simple.log
      fi
    fi

    echo ""
    echo "Available services:"
    echo "- JupyterLab: http://localhost:8888"
    echo "- Spark UI: http://localhost:4040 (when Spark session is active)"
    echo ""
    echo "Installed packages:"
    pip list | grep -E "(boto3|duckdb|polars|deltalake|kafka|minio|great-expectations|lakefs|torch|transformers|mlflow|ray|airflow|pymilvus|bentoml|kfp)" || echo "Package list unavailable"
  EOT
  env = {
    # Git configuration
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = data.coder_workspace_owner.me.email
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email

    # Spark configuration
    SPARK_HOME          = "/usr/local/spark"
    PYTHONPATH          = "$PYTHONPATH:/usr/local/spark/python"

    # Python configuration
    PIP_DISABLE_PIP_VERSION_CHECK = "1"
    PYTHONUNBUFFERED              = "1"
  }

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }
  metadata {
    display_name = "Memory Usage"
    key          = "1_mem_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }
  metadata {
    display_name = "Disk Usage"
    key          = "2_disk_usage"
    script       = "coder stat disk --path /home/jovyan"
    interval     = 60
    timeout      = 1
  }
  metadata {
    display_name = "CPU Usage (Host)"
    key          = "3_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }
  metadata {
    display_name = "Memory Usage (Host)"
    key          = "4_mem_usage_host"
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }
  metadata {
    display_name = "Load Average (Host)"
    key          = "5_load_host"
    # get load avg scaled by number of cores
    script   = <<EOT
      echo "`cat /proc/loadavg | awk '{ print $1 }'` `nproc`" | awk '{ printf "%0.2f", $1/$2 }'
    EOT
    interval = 60
    timeout  = 1
  }
  display_apps {
    vscode                 = true
    vscode_insiders        = false
    ssh_helper             = false
    port_forwarding_helper = true
    web_terminal           = true
  }
}

resource "coder_app" "jupyter" {
  agent_id     = coder_agent.main.id
  slug         = "jupyter"
  display_name = "Jupyter Lab"
  url          = "http://localhost:8888"
  icon         = "/icon/jupyter.svg"
  subdomain    = true
  share        = "owner"
  healthcheck {
    url       = "http://localhost:8888/api"
    interval  = 5
    threshold = 10
  }
}

resource "coder_app" "spark_ui" {
  agent_id     = coder_agent.main.id
  slug         = "spark-ui"
  display_name = "Spark UI"
  url          = "http://localhost:4040"
  icon         = "/icon/spark.svg"
  subdomain    = false
  share        = "owner"
  healthcheck {
    url       = "http://localhost:4040"
    interval  = 5
    threshold = 10
  }
}

resource "kubernetes_persistent_volume_claim" "home" {
  metadata {
    name      = "coder-${data.coder_workspace.me.id}-home"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-pvc"
      "app.kubernetes.io/instance" = "coder-pvc-${data.coder_workspace.me.id}"
      "app.kubernetes.io/part-of"  = "coder"
      "com.coder.resource"         = "true"
      "com.coder.workspace.id"     = data.coder_workspace.me.id
      "com.coder.workspace.name"   = data.coder_workspace.me.name
      "com.coder.user.id"          = data.coder_workspace_owner.me.id
      "com.coder.user.username"    = data.coder_workspace_owner.me.name
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace_owner.me.email
    }
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.coder_parameter.home_disk_size.value}Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "main" {
  count = data.coder_workspace.me.start_count
  depends_on = [
    kubernetes_persistent_volume_claim.home
  ]
  wait_for_rollout = false
  metadata {
    name      = "coder-${data.coder_workspace.me.id}"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
      "app.kubernetes.io/part-of"  = "coder"
      "com.coder.resource"         = "true"
      "com.coder.workspace.id"     = data.coder_workspace.me.id
      "com.coder.workspace.name"   = data.coder_workspace.me.name
      "com.coder.user.id"          = data.coder_workspace_owner.me.id
      "com.coder.user.username"    = data.coder_workspace_owner.me.name
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace_owner.me.email
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "coder-workspace"
        "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
        "app.kubernetes.io/part-of"  = "coder"
        "com.coder.resource"         = "true"
        "com.coder.workspace.id"     = data.coder_workspace.me.id
        "com.coder.workspace.name"   = data.coder_workspace.me.name
        "com.coder.user.id"          = data.coder_workspace_owner.me.id
        "com.coder.user.username"    = data.coder_workspace_owner.me.name
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"     = "coder-workspace"
          "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
          "app.kubernetes.io/part-of"  = "coder"
          "com.coder.resource"         = "true"
          "com.coder.workspace.id"     = data.coder_workspace.me.id
          "com.coder.workspace.name"   = data.coder_workspace.me.name
          "com.coder.user.id"          = data.coder_workspace_owner.me.id
          "com.coder.user.username"    = data.coder_workspace_owner.me.name
        }
      }
      spec {
        # Use the default jovyan user ID (1000) that comes with Jupyter images
        security_context {
          run_as_user = 1000
          fs_group    = 1000
        }
        service_account_name = "coder"
        container {
          name              = "dev"
          image             = var.image
          image_pull_policy = "Always"
          command           = ["sh", "-c", coder_agent.main.init_script]
          security_context {
            run_as_user = "1000"
          }
          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.main.token
          }
          env {
            name  = "HOME"
            value = "/home/jovyan"
          }
          env {
            name  = "NB_USER"
            value = "jovyan"
          }

          # Expose ports
          port {
            container_port = 8888
            name           = "jupyter"
          }
          port {
            container_port = 4040
            name           = "spark-ui"
          }

          resources {
            limits = {
              "cpu"    = "${data.coder_parameter.cpu.value}"
              "memory" = "${data.coder_parameter.memory.value}Gi"
            }
            requests = {
              "cpu"    = "250m"
              "memory" = "${(tonumber(data.coder_parameter.memory.value) * 0.5)}Gi"
            }
          }

          volume_mount {
            mount_path = "/home/jovyan"
            name       = "home"
            read_only  = false
          }
        }

        volume {
          name = "home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.home.metadata.0.name
            read_only  = false
          }
        }

        # Add pod anti-affinity for better distribution across nodes
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1
              pod_affinity_term {
                topology_key = "kubernetes.io/hostname"
                label_selector {
                  match_expressions {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["coder-workspace"]
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

# Add windsurf module for improved terminal experience
module "windsurf" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/windsurf/coder"
  version  = "1.1.0"
  agent_id = coder_agent.main.id
}