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

provider "coder" {
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
  description = "The Kubernetes namespace to create workspaces in (must exist prior to creating workspaces). If the Coder host is itself running as a Pod on the same Kubernetes cluster as you are deploying workspaces to, set this to the same namespace."
}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  description  = "The number of CPU cores"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "2 Cores"
    value = "2"
  }
  option {
    name  = "4 Cores"
    value = "4"
  }
  option {
    name  = "6 Cores"
    value = "6"
  }
  option {
    name  = "8 Cores"
    value = "8"
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory"
  description  = "The amount of memory in GB"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "2 GB"
    value = "2"
  }
  option {
    name  = "4 GB"
    value = "4"
  }
  option {
    name  = "8 GB"
    value = "8"
  }
  option {
    name  = "16 GB"
    value = "16"
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
  display_name = "Home disk size"
  description  = "The size of the home disk in GB"
  default      = "10"
  type         = "number"
  icon         = "/emojis/1f4be.png"
  mutable      = false
  validation {
    min = 10
    max = 50
  }
}

provider "kubernetes" {
  # Authenticate via ~/.kube/config or a Coder-specific ServiceAccount, depending on admin preferences
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  os             = "linux"
  arch           = "amd64"
  startup_script = <<-EOT
    set -e
    set -o pipefail

    sudo apt-get update

    # Create and activate a virtual environment
    python3 -m venv $HOME/venv
    . $HOME/venv/bin/activate
    
    # Upgrade pip, setuptools, and wheel first
    pip install --upgrade pip setuptools wheel

    # Install packages in optimized order to minimize conflicts
    echo "Installing core numerical libraries..."
    pip install numpy scipy

    echo "Installing data manipulation libraries..."
    pip install pandas polars

    echo "Installing visualization libraries..."
    pip install matplotlib seaborn plotly

    echo "Installing PyTorch (CPU version)..."
    pip install torch --index-url https://download.pytorch.org/whl/cpu

    echo "Installing TensorFlow..."
    pip install tensorflow

    echo "Installing ML tools..."
    pip install scikit-learn xgboost statsmodels

    echo "Installing computer vision..."
    pip install opencv-python-headless

    echo "Installing NLP libraries..."
    pip install spacy transformers tokenizers datasets

    echo "Installing LLM frameworks..."
    pip install langchain langchain_openai langchain_community langgraph

    echo "Installing vector database..."
    pip install chromadb

    echo "Installing web frameworks..."
    pip install streamlit

    echo "Installing utilities..."
    pip install pydantic python-dotenv requests ipykernel

    echo "All Python packages installed successfully!"

    # Verify critical packages
    python -c "import tensorflow, torch, langchain, chromadb; print('Critical packages verified OK')"

    # Register the venv as a Jupyter kernel
    python -m ipykernel install --user --name=venv --display-name "Python 3.12 Coder (venv)"

    # Create workspace validation script
    cat > $HOME/validate_workspace.sh <<'VALIDATE_EOF'
#!/bin/bash
# Quick workspace validation
set -e
source $HOME/venv/bin/activate
echo "=== Workspace Validation ==="
echo "Python: $(python --version)"
echo "Location: $(which python)"
echo ""
echo "Jupyter Kernel:"
jupyter kernelspec list | grep venv && echo "✅ Kernel OK" || echo "❌ Not found"
echo ""
echo "Package Test:"
python -c "
packages = ['numpy', 'pandas', 'tensorflow', 'torch', 'langchain', 'chromadb']
for p in packages:
    try:
        __import__(p)
        print(f'  ✅ {p}')
    except:
        print(f'  ❌ {p}')
"
echo ""
echo "✅ Validation complete!"
VALIDATE_EOF
    chmod +x $HOME/validate_workspace.sh

    # Create quick start guide
    cat > $HOME/QUICK_START.txt <<'QUICKSTART_EOF'
╔════════════════════════════════════════════════════════════╗
║     WWT Data Science Workspace - Quick Start              ║
╚════════════════════════════════════════════════════════════╝

🚀 FIRST STEPS:
  1. Activate Python: source $HOME/venv/bin/activate
  2. Validate setup: bash ~/validate_workspace.sh
  3. Access VS Code: http://localhost:13337

📦 INSTALLED PACKAGES:
  • ML: TensorFlow, PyTorch, scikit-learn, XGBoost
  • Data: NumPy, Pandas, Polars, SciPy
  • Viz: Matplotlib, Seaborn, Plotly
  • NLP: Transformers, spaCy, Datasets
  • LLM: LangChain, ChromaDB
  • Web: Streamlit, Jupyter

🎯 COMMON COMMANDS:
  source $HOME/venv/bin/activate  # Always do this first!
  python script.py                # Run Python
  jupyter console --kernel=venv   # Jupyter console
  streamlit run app.py            # Run Streamlit
  pip install package-name        # Install packages

✅ VALIDATION:
  bash ~/validate_workspace.sh    # Full validation
  python -c "import tensorflow, torch, langchain; print('OK')"

📚 MORE INFO:
  See README.md in the template repository
  Run: cat ~/QUICK_START.txt (this file)

QUICKSTART_EOF

    echo ""
    echo "=========================================="
    echo "✅ Workspace setup complete!"
    echo "=========================================="
    echo ""
    echo "Quick start: cat ~/QUICK_START.txt"
    echo "Validation:  bash ~/validate_workspace.sh"
    echo ""

    # Install the latest code-server.
    # Append "--version x.x.x" to install a specific version of code-server.
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server

    # Install VS Code extensions
    /tmp/code-server/bin/code-server --install-extension almenon.arepl --force \
    --install-extension njpwerner.autodocstring --force \
    --install-extension ms-python.python --force \
    --install-extension vscode-icons-team.vscode-icons --force \
    --install-extension mechatroner.rainbow-csv --force \
    --install-extension ms-azuretools.vscode-docker --force \
    --install-extension charliermarsh.ruff --force \
    --install-extension streetsidesoftware.code-spell-checker --force \
    --install-extension kevinrose.vsc-python-indent --force
    
    # Start code-server in the background.
    /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &

    

  EOT

  # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  # For basic resources, you can use the `coder stat` command.
  # If you need more control, you can write your own script.
  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "CPU Usage (Host)"
    key          = "4_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage (Host)"
    key          = "5_mem_usage_host"
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Load Average (Host)"
    key          = "6_load_host"
    # get load avg scaled by number of cores
    script   = <<EOT
      echo "`cat /proc/loadavg | awk '{ print $1 }'` `nproc`" | awk '{ printf "%0.2f", $1/$2 }'
    EOT
    interval = 60
    timeout  = 1
  }
}

# code-server
resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  icon         = "/icon/code.svg"
  url          = "http://localhost:13337?folder=/home/coder"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }
}

resource "kubernetes_persistent_volume_claim_v1" "home" {
  metadata {
    name      = "coder-${data.coder_workspace.me.id}-home"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-pvc"
      "app.kubernetes.io/instance" = "coder-pvc-${data.coder_workspace.me.id}"
      "app.kubernetes.io/part-of"  = "coder"
      //Coder-specific labels.
      "com.coder.resource"       = "true"
      "com.coder.workspace.id"   = data.coder_workspace.me.id
      "com.coder.workspace.name" = data.coder_workspace.me.name
      "com.coder.user.id"        = data.coder_workspace_owner.me.id
      "com.coder.user.username"  = data.coder_workspace_owner.me.name
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

resource "kubernetes_deployment_v1" "main" {
  count = data.coder_workspace.me.start_count
  depends_on = [
    kubernetes_persistent_volume_claim_v1.home
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
          run_as_user     = 1000
          fs_group        = 1000
          run_as_non_root = true
        }

        container {
          name              = "dev"
          image             = "codercom/enterprise-base:ubuntu"
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
              "memory" = "512Mi"
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
            claim_name = kubernetes_persistent_volume_claim_v1.home.metadata.0.name
            read_only  = false
          }
        }

        affinity {
          // This affinity attempts to spread out all workspace pods evenly across
          // nodes.
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
