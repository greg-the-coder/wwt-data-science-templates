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
  description = "Container image for data engineering and LLM workspaces"
  default     = "quay.io/jupyter/pytorch-notebook:cuda12-python-3.11.8"
}

data "coder_parameter" "use_gpu" {
  name         = "use_gpu"
  display_name = "Use GPU"
  description  = "Whether to use GPU acceleration for LLM tasks"
  default      = "false"
  mutable      = true
  option {
    name  = "No GPU"
    value = "false"
  }
  option {
    name  = "Use GPU"
    value = "true"
  }
}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU Cores"
  description  = "Number of CPU cores for workloads"
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
  option {
    name  = "16 Cores"
    value = "16"
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
  option {
    name  = "32 GB"
    value = "32"
  }
}

data "coder_parameter" "home_disk_size" {
  name         = "home_disk_size"
  display_name = "Home Disk Size (GB)"
  description  = "Size of persistent home directory"
  default      = "50"
  type         = "number"
  mutable      = false
  validation {
    min = 20
    max = 200
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
    set -e

    # Install additional packages using pip for latest versions
    # LLM & AI/ML libraries
    pip install --upgrade \
      transformers \
      datasets \
      accelerate \
      torch \
      langchain \
      langchain-community \
      langchainhub \
      peft \
      bitsandbytes \
      deepspeed \
      optimum \
      sentencepiece \
      safetensors \
      gradio \
      tokenizers \
      einops \
      tiktoken \
      vllm \
      trl

    # Data engineering libraries
    pip install --upgrade \
      great-expectations \
      deltalake \
      pyarrow \
      boto3 \
      duckdb \
      kafka-python \
      lakefs-client \
      apache-airflow-client \
      minio \
      pandas \
      polars \
      pyodbc \
      snowflake-connector-python \
      dbt-core

    # Vector database and retrieval
    pip install --upgrade \
      faiss-cpu \
      qdrant-client \
      chromadb \
      pinecone-client \
      pymilvus \
      pgvector

    # Configure Git for the user
    git config --global user.name "${coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)}"
    git config --global user.email "${data.coder_workspace_owner.me.email}"

    # Set up Jupyter environment
    jupyter labextension install @jupyter-widgets/jupyterlab-manager

    # Create notebook example directories
    mkdir -p ~/llm-examples ~/data-engineering

    # Create a sample LLM notebook
    cat > ~/llm-examples/transformers_quickstart.ipynb << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Transformers Quickstart\n",
    "\n",
    "This notebook demonstrates how to use the Transformers library to work with Large Language Models."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "from transformers import pipeline, AutoTokenizer, AutoModelForCausalLM\n",
    "import torch"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Check if GPU is available\n",
    "print(f\"GPU available: {torch.cuda.is_available()}\")\n",
    "if torch.cuda.is_available():\n",
    "    print(f\"GPU device: {torch.cuda.get_device_name()}\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Simple pipeline for sentiment analysis\n",
    "classifier = pipeline(\"sentiment-analysis\")\n",
    "result = classifier(\"This LLM workspace is amazing!\")\n",
    "print(result)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Text generation with a small model\n",
    "generator = pipeline(\"text-generation\", model=\"distilgpt2\")\n",
    "result = generator(\"The data science team has developed\", max_length=30)\n",
    "print(result[0]['generated_text'])"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  }
 }
}
EOF

    # Create data engineering sample notebook
    cat > ~/data-engineering/spark_polars_comparison.ipynb << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Data Processing: PySpark vs Polars\n",
    "\n",
    "This notebook compares data processing approaches using PySpark and Polars."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "import pyspark.sql.functions as F\n",
    "from pyspark.sql import SparkSession\n",
    "import polars as pl\n",
    "import pandas as pd\n",
    "import numpy as np\n",
    "import time"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Create a local Spark session\n",
    "spark = SparkSession.builder \\\n",
    "    .appName(\"SparkPolarsComparison\") \\\n",
    "    .master(\"local[*]\") \\\n",
    "    .getOrCreate()\n",
    "\n",
    "print(f\"Spark version: {spark.version}\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Generate sample data\n",
    "def create_data(rows=100000):\n",
    "    df_pd = pd.DataFrame({\n",
    "        'id': np.arange(1, rows+1),\n",
    "        'value': np.random.rand(rows) * 100,\n",
    "        'category': np.random.choice(['A', 'B', 'C', 'D'], size=rows)\n",
    "    })\n",
    "    return df_pd\n",
    "\n",
    "sample_data = create_data()\n",
    "sample_data.head()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Convert to Spark DataFrame\n",
    "df_spark = spark.createDataFrame(sample_data)\n",
    "\n",
    "# Convert to Polars DataFrame\n",
    "df_polars = pl.from_pandas(sample_data)\n",
    "\n",
    "print(f\"Data loaded into Spark and Polars\")"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  }
 }
}
EOF

    # Export port 4040 for Spark UI
    echo "Spark UI will be available at http://localhost:4040 when a Spark session is running"

    # Stop any running JupyterLab instances
    pkill -f jupyter-lab || true

    # Start JupyterLab server with optimized configuration
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --ServerApp.token='' --ServerApp.password='' --ServerApp.terminado_settings='{"shell_command": ["/bin/bash"]}' > /tmp/jupyter.log 2>&1 &

    echo "Workspace ready! JupyterLab available at port 8888"
  EOT
  env = {
    # Git configuration
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = data.coder_workspace_owner.me.email
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email

    # Python and PIP configuration
    PIP_DISABLE_PIP_VERSION_CHECK = "1"
    PYTHONUNBUFFERED              = "1"

    # Jupyter configuration
    JUPYTER_RUNTIME_DIR = "/home/jovyan/.local/share/jupyter/runtime"
    JUPYTER_DATA_DIR    = "/home/jovyan/.local/share/jupyter"

    # Torch/CUDA configuration - will be used if GPU is available
    NVIDIA_VISIBLE_DEVICES     = "all"
    CUDA_DEVICE_ORDER          = "PCI_BUS_ID"
    TORCH_CUDA_ARCH_LIST       = "8.0"
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
    display_name = "GPU Usage"
    key          = "3_gpu_usage"
    script       = "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{print $1\"%\"}' || echo 'No GPU'"
    interval     = 10
    timeout      = 1
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
          fs_group    = 100
        }
        service_account_name = "coder"
        container {
          name              = "dev"
          image             = var.image
          image_pull_policy = "IfNotPresent"
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

          # Enable GPU if requested
          dynamic "resources" {
            for_each = data.coder_parameter.use_gpu.value == "true" ? [1] : []
            content {
              limits = {
                "nvidia.com/gpu" = "1"
                "cpu"           = "${data.coder_parameter.cpu.value}"
                "memory"        = "${data.coder_parameter.memory.value}Gi"
              }
              requests = {
                "nvidia.com/gpu" = "1"
                "cpu"           = "${(tonumber(data.coder_parameter.cpu.value) * 0.5)}m"
                "memory"        = "${(tonumber(data.coder_parameter.memory.value) * 0.5)}Gi"
              }
            }
          }

          # CPU-only resources if GPU not requested
          dynamic "resources" {
            for_each = data.coder_parameter.use_gpu.value == "true" ? [] : [1]
            content {
              limits = {
                "cpu"    = "${data.coder_parameter.cpu.value}"
                "memory" = "${data.coder_parameter.memory.value}Gi"
              }
              requests = {
                "cpu"    = "${(tonumber(data.coder_parameter.cpu.value) * 0.5)}m"
                "memory" = "${(tonumber(data.coder_parameter.memory.value) * 0.5)}Gi"
              }
            }
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