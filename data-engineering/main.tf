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
 Set this to false if Coder is running as a Pod in the cluster.
 Set this to true if Coder is running outside the cluster.
 EOF
 default     = false
}
variable "namespace" {
 type        = string
 description = "The Kubernetes namespace to create workspaces in"
}
variable "image" {
 type        = string
 description = "Container image for data engineering workspaces"
 default     = "jupyter/pyspark-notebook:latest"
}
data "coder_parameter" "cpu" {
 name         = "cpu"
 display_name = "CPU Cores"
 description  = "Number of CPU cores for Spark workloads"
 default      = "8"
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
 option {
   name  = "32 Cores"
   value = "32"
 }
}
data "coder_parameter" "memory" {
 name         = "memory"
 display_name = "Memory (GB)"
 description  = "Amount of memory in GB"
 default      = "32"
 icon         = "/icon/memory.svg"
 mutable      = true
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
 option {
   name  = "128 GB"
   value = "128"
 }
}
data "coder_parameter" "home_disk_size" {
 name         = "home_disk_size"
 display_name = "Home Disk Size (GB)"
 description  = "Size of persistent home directory"
 default      = "100"
 type         = "number"
 mutable      = false
 validation {
   min = 20
   max = 1000
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
   pip install --quiet great-expectations deltalake kafka-python
   pip install --quiet minio boto3 pyarrow
   pip install --quiet lakefs-client duckdb
   pip install --quiet apache-airflow-client
   
   pkill -f jupyter-lab || true
   nohup jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --ServerApp.token='' --ServerApp.password='' > /tmp/jupyter.log 2>&1 &
 EOT
 env = {
   GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
   GIT_AUTHOR_EMAIL    = data.coder_workspace_owner.me.email
   GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
   GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email
   SPARK_HOME          = "/usr/local/spark"
metadata {
   display_name = "CPU Usage"
   key          = "cpu_usage"
   script       = "coder stat cpu"
   interval     = 10
   timeout      = 1
 }
 metadata {
   display_name = "Memory Usage"
   key          = "mem_usage"
   script       = "coder stat mem"
   interval     = 10
   timeout      = 1
 }
 metadata {
   display_name = "Disk Usage"
   key          = "disk_usage"
   script       = "coder stat disk --path $HOME"
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
resource "kubernetes_persistent_volume_claim" "home" {
 metadata {
   name      = "coder-${data.coder_workspace.me.id}"
   namespace = var.namespace
   labels = {
     "com.coder.resource"       = "true"
     "com.coder.workspace.id"   = data.coder_workspace.me.id
     "com.coder.workspace.name" = data.coder_workspace.me.name
     "com.coder.user.id"        = data.coder_workspace_owner.me.id
     "com.coder.user.username"  = data.coder_workspace_owner.me.name
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
 depends_on = [kubernetes_persistent_volume_claim.home]
 wait_for_rollout = false
 metadata {
   name      = "coder-${data.coder_workspace.me.id}"
   namespace = var.namespace
 }
 spec {
   replicas = 1
   selector {
     match_labels = {
       "com.coder.workspace.id" = data.coder_workspace.me.id
     }
   }
   template {
     metadata {
       labels = {
         "com.coder.workspace.id" = data.coder_workspace.me.id
       }
     }
     spec {
       security_context {
         run_as_user = 1000
         fs_group    = 100
       }
       container {
         name    = "dev"
         image   = var.image
         command = ["sh", "-c", coder_agent.main.init_script]
         env {
           name  = "CODER_AGENT_TOKEN"
           value = coder_agent.main.token
         }
         resources {
           requests = {
             cpu    = data.coder_parameter.cpu.value
             memory = "${data.coder_parameter.memory.value}Gi"
           }
           limits = {
             cpu    = data.coder_parameter.cpu.value
             memory = "${data.coder_parameter.memory.value}Gi"

