terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
  required_version = ">= 1.3.0"
}

provider "coder" {
  # Configuration options
}

# Default tags for all resources
locals {
  common_labels = {
    "app.kubernetes.io/name"       = "ml-training"
    "app.kubernetes.io/instance"   = "${data.coder_workspace.me.name}"
    "app.kubernetes.io/part-of"    = "wwt-data-science-templates"
    "app.kubernetes.io/created-by" = "coder"
    "coder.com/workspace-id"       = data.coder_workspace.me.id
    "coder.com/owner"              = data.coder_workspace_owner.me.email
  }
  
  # Default environment variables
  default_env_vars = {
    "PYTHONUNBUFFERED" = "1"
    "PYTHONIOENCODING" = "utf-8"
    "PAGER"            = "cat"
  }
}

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
  description = "Container image for ML workspaces"
  default     = "pytorch/pytorch:2.1.0-cuda12.1-cudnn8-devel"
}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU Cores"
  description  = "Number of CPU cores"
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
  option {
    name  = "64 GB"
    value = "64"
  }
}

data "coder_parameter" "gpu_count" {
  name         = "gpu_count"
  display_name = "GPU Count"
  description  = "Number of NVIDIA GPUs (0 for CPU-only)"
  default      = "0"
  mutable      = true
  option {
    name  = "None"
    value = "0"
  }
  option {
    name  = "1 GPU"
    value = "1"
  }
  option {
    name  = "2 GPUs"
    value = "2"
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
    min = 10
    max = 500
  }
}

provider "kubernetes" {
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"
  
  # Copy validation script to workspace
  dir = "/home/coder"
  
  startup_script = <<-EOT
    #!/bin/bash
    set -euo pipefail
    
    # Create required directories
    mkdir -p ~/.local/bin ~/.config ~/.cache
    
    # Install system dependencies
    echo "Updating package lists and installing system dependencies..."
    apt-get update -qq && apt-get install -y -qq \
      git curl wget vim jq htop \
      build-essential cmake \
      libgl1-mesa-glx libglib2.0-0 \
      > /dev/null 2>&1
    
    # Install and configure pipx
    echo "Setting up Python environment..."
    python3 -m pip install --quiet --user pipx
    export PATH="$HOME/.local/bin:$PATH"
    
    # Install core tools
    echo "Installing core tools..."
    pipx install --pip-args="--quiet" jupyterlab
    pipx inject --pip-args="--quiet" jupyterlab \
      jupyterlab-git \
      jupyterlab-lsp \
      jupyterlab-code-formatter \
      jupyterlab-drawio
    
    # Install Python packages
    echo "Installing Python packages..."
    pip install --quiet --upgrade pip setuptools wheel
    
    # Core data science stack
    pip install --quiet \
      numpy pandas scipy scikit-learn matplotlib seaborn plotly \
      jupyter jupyterlab ipywidgets ipympl \
      tqdm requests pillow opencv-python-headless
    
    # PyTorch ecosystem
    pip install --quiet \
      torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
    
    # ML tools
    pip install --quiet \
      mlflow \
      wandb \
      ray[train,tune,serve] \
      pytorch-lightning \
      transformers datasets tokenizers \
      tensorboard
    
    # Install validation script dependencies
    pip install --quiet psutil py-cpuinfo
    
    # Copy validation script
    cat > /home/coder/validate_environment.py << 'EOF'
    ${file("${path.module}/validate_environment.py")}
    EOF
    
    # Set up JupyterLab
    echo "Configuring JupyterLab..."
    jupyter nbextension enable --py widgetsnbextension --sys-prefix
    jupyter lab build --dev-build=False --minimize=False
    
    # Start services
    echo "Starting services..."
    
    # Start MLflow server
    mkdir -p /home/coder/mlruns
    nohup mlflow server \
      --host 0.0.0.0 \
      --port 5000 \
      --backend-store-uri sqlite:////home/coder/mlruns/mlflow.db \
      --default-artifact-root /home/coder/mlruns \
      > /tmp/mlflow.log 2>&1 &
    
    # Start JupyterLab
    mkdir -p /home/coder/notebooks
    nohup jupyter lab \
      --ip=0.0.0.0 \
      --port=8888 \
      --no-browser \
      --ServerApp.token='' \
      --ServerApp.password='' \
      --ServerApp.root_dir=/home/coder/notebooks \
      --ServerApp.allow_origin='*' \
      --ServerApp.allow_remote_access=True \
      --ServerApp.disable_check_xsrf=True \
      > /tmp/jupyter.log 2>&1 &
    
    # Run validation script
    echo "Running environment validation..."
    python /home/coder/validate_environment.py || echo "Validation completed with warnings"
    
    echo "\n✅ ML Training environment is ready!"
  EOT

  env = merge(
    local.default_env_vars,
    {
      # Git configuration
      GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
      GIT_AUTHOR_EMAIL    = data.coder_workspace_owner.me.email
      GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
      GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email
      
      # Python configuration
      PYTHONPATH          = "/home/coder"
      
      # MLflow configuration
      MLFLOW_TRACKING_URI = "http://localhost:5000"
      
      # Jupyter configuration
      JUPYTER_PATH       = "/home/coder/.local/share/jupyter"
      
      # CUDA paths (if GPU is available)
      LD_LIBRARY_PATH    = "/usr/local/nvidia/lib:/usr/local/nvidia/lib64"
      
      # Workspace information
      WORKSPACE_NAME     = data.coder_workspace.me.name
      WORKSPACE_OWNER    = data.coder_workspace_owner.me.email
    }
  )

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
    script       = "coder stat disk --path $HOME"
    interval     = 60
    timeout      = 1
  }
  metadata {
    display_name = "GPU Memory"
    key          = "3_gpu_mem"
    script       = <<-EOT
      if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits | awk -F', ' '{printf "%.1f/%.1f GB", $1/1024, $2/1024}'
      else
        echo "N/A"
      fi
    EOT
    interval     = 10
    timeout      = 1
  }
  metadata {
    display_name = "GPU Utilization"
    key          = "4_gpu_util"
    script       = <<-EOT
      if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{print $1"%"}'
      else
        echo "N/A"
      fi
    EOT
    interval     = 10
    timeout      = 1
  }
  metadata {
    display_name = "Disk Usage"
    key          = "5_disk_usage"
    script       = "df -h $HOME | awk 'NR==2{print $5}'"
    interval     = 60
    timeout      = 1
  }
  metadata {
    display_name = "CPU (Host)"
    key          = "6_cpu_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }
  metadata {
    display_name = "Memory (Host)"
    key          = "7_mem_host"
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }
  metadata {
    display_name = "Load Avg"
    key          = "8_load_avg"
    script       = "cat /proc/loadavg | awk '{printf \"%.1f/%.1f/%.1f\", $1, $2, $3}'"
    interval     = 60
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

resource "coder_app" "mlflow" {
  agent_id     = coder_agent.main.id
  slug         = "mlflow"
  display_name = "MLflow UI"
  url          = "http://localhost:5000"
  icon         = "/icon/flask.svg"
  subdomain    = false
  share        = "owner"
  healthcheck {
    url       = "http://localhost:5000"
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
          resources {
            requests = {
              "cpu"    = "250m"
              "memory" = "${(tonumber(data.coder_parameter.memory.value) * 0.5)}Gi"
            }
            limits = {
              "cpu"    = "${data.coder_parameter.cpu.value}"
              "memory" = "${data.coder_parameter.memory.value}Gi"
            }
          }
          volume_mount {
            mount_path = "/home/coder"
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