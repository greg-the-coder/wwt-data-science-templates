# WWT Data Science Templates for Coder

A collection of production-ready Coder workspace templates for data science, machine learning, and data engineering workloads on Kubernetes.

## 📚 Available Templates

### 1. Data Science Workspace (`kubernetes-wwt-datascience`)
**Full-featured ML and LLM development environment**

- **Use Case**: Machine learning, deep learning, NLP, LLM application development
- **Base Image**: `codercom/enterprise-base:ubuntu`
- **Python**: 3.12 with isolated virtual environment
- **IDE**: VS Code (code-server) with 9 extensions
- **Jupyter**: Registered kernel for notebook development

**Pre-installed Packages (27+):**
- ML Frameworks: TensorFlow 2.20, PyTorch 2.10, scikit-learn, XGBoost
- Data Science: NumPy, Pandas, Polars, SciPy, Statsmodels
- Visualization: Matplotlib, Seaborn, Plotly
- NLP: spaCy, Transformers, Tokenizers, Datasets
- LLM: LangChain, LangChain OpenAI, LangGraph, ChromaDB
- Web: Streamlit
- CV: OpenCV (headless)

**Resources:**
- CPU: 2-8 cores (configurable)
- Memory: 2-16 GB (configurable)
- Storage: 10-50 GB persistent home directory
- GPU: Optional (0-2 GPUs)

**Documentation:** [kubernetes-wwt-datascience/README.md](./kubernetes-wwt-datascience/README.md)

---

### 2. Data Engineering Workspace (`data-engineering`)
**PySpark and data pipeline development environment**

- **Use Case**: Data engineering, ETL, streaming, data quality
- **Base Image**: `jupyter/pyspark-notebook:latest`
- **IDE**: JupyterLab
- **Spark**: Pre-configured Apache Spark with UI access

**Pre-installed Packages:**
- Apache Spark (pre-installed)
- Data processing: boto3
- Data lake: deltalake, lakefs-client
- Streaming: kafka-python
- Storage: minio
- Data quality: great-expectations
- Orchestration: apache-airflow
- Model serving: bentoml
- Kubernetes: kfp, kubernetes

**Resources:**
- CPU: 4-8 cores (configurable)
- Memory: 8-16 GB (configurable)
- Storage: 20-100 GB persistent home directory

**Documentation:** [data-engineering/README.md](./data-engineering/README.md)

---

## 🚀 Quick Start

### Prerequisites

1. **Coder CLI installed**
   ```bash
   # Install Coder CLI
   curl -fsSL https://coder.com/install.sh | sh
   
   # Or using Homebrew (macOS/Linux)
   brew install coder
   ```

2. **Coder deployment access**
   ```bash
   # Login to your Coder deployment
   coder login https://coder.example.com
   
   # Verify connection
   coder version
   ```

3. **Kubernetes cluster access** (for template administrators)
   - Cluster with sufficient resources
   - Namespace created for workspaces
   - StorageClass supporting ReadWriteOnce PVCs

---

## 📤 Deploying Templates

### Method 1: Push Templates to Coder (Recommended)

#### Push Data Science Template
```bash
# Navigate to repository
cd wwt-data-science-templates

# Push the data science template
coder templates push kubernetes-wwt-datascience \
  --directory ./kubernetes-wwt-datascience \
  --name "WWT Data Science" \
  --message "Full-featured data science and ML workspace"

# Or with variables
coder templates push kubernetes-wwt-datascience \
  --directory ./kubernetes-wwt-datascience \
  --name "WWT Data Science" \
  --variable namespace=coder-workspaces \
  --variable use_kubeconfig=false
```

#### Push Data Engineering Template
```bash
# Push the data engineering template
coder templates push data-engineering \
  --directory ./data-engineering \
  --name "WWT Data Engineering" \
  --message "PySpark and data pipeline development"

# Or with variables
coder templates push data-engineering \
  --directory ./data-engineering \
  --name "WWT Data Engineering" \
  --variable namespace=coder-workspaces \
  --variable use_kubeconfig=false \
  --variable image=jupyter/pyspark-notebook:latest
```

#### Update Existing Template
```bash
# Update with new version
coder templates push kubernetes-wwt-datascience \
  --directory ./kubernetes-wwt-datascience \
  --name "WWT Data Science" \
  --message "Updated package versions and validation tools"
```

### Method 2: Create Template from Git Repository

```bash
# Create template directly from Git
coder templates create kubernetes-wwt-datascience \
  --name "WWT Data Science" \
  --git-url https://github.com/your-org/wwt-data-science-templates \
  --git-path kubernetes-wwt-datascience \
  --git-branch main

coder templates create data-engineering \
  --name "WWT Data Engineering" \
  --git-url https://github.com/your-org/wwt-data-science-templates \
  --git-path data-engineering \
  --git-branch main
```

### Method 3: Interactive Template Creation

```bash
# Interactive template creation
coder templates create

# Follow the prompts to:
# 1. Select template directory
# 2. Name the template
# 3. Configure variables
# 4. Set permissions
```

---

## 🔧 Template Management

### List Templates
```bash
# List all templates in your deployment
coder templates list

# Get detailed info about a template
coder templates show kubernetes-wwt-datascience
```

### Update Template Variables
```bash
# Update template with new variables
coder templates push kubernetes-wwt-datascience \
  --directory ./kubernetes-wwt-datascience \
  --variable namespace=new-namespace \
  --variable use_kubeconfig=true
```

### Version Management
```bash
# List template versions
coder templates versions list kubernetes-wwt-datascience

# Promote a specific version to active
coder templates versions promote kubernetes-wwt-datascience --version v2

# Rollback to previous version
coder templates versions promote kubernetes-wwt-datascience --version v1
```

### Delete Template
```bash
# Delete a template (requires no active workspaces)
coder templates delete kubernetes-wwt-datascience

# Force delete (stops all workspaces)
coder templates delete kubernetes-wwt-datascience --force
```

---

## 👥 Creating Workspaces

### Create Workspace from Template

```bash
# Create a data science workspace
coder create my-ml-workspace \
  --template kubernetes-wwt-datascience \
  --parameter cpu=4 \
  --parameter memory=8 \
  --parameter home_disk_size=20

# Create a data engineering workspace
coder create my-de-workspace \
  --template data-engineering \
  --parameter cpu=8 \
  --parameter memory=16 \
  --parameter home_disk_size=50
```

### Access Workspace

```bash
# SSH into workspace
coder ssh my-ml-workspace

# Open VS Code in browser
coder open my-ml-workspace

# Port forward
coder port-forward my-ml-workspace --tcp 8888:8888
```

### Manage Workspaces

```bash
# List your workspaces
coder list

# Start/stop workspace
coder start my-ml-workspace
coder stop my-ml-workspace

# Delete workspace
coder delete my-ml-workspace
```

---

## ✅ Template Validation

### Data Science Template Validation

After creating a workspace from the data science template:

```bash
# SSH into workspace
coder ssh my-ml-workspace

# Quick validation (30 seconds)
source $HOME/venv/bin/activate
python -c "import numpy, tensorflow, torch, langchain; print('✅ OK')"

# Full validation (2 minutes)
bash ~/validate_workspace.sh

# View quick start guide
cat ~/QUICK_START.txt
```

### Data Engineering Template Validation

After creating a workspace from the data engineering template:

```bash
# SSH into workspace
coder ssh my-de-workspace

# Test PySpark
python -c "from pyspark.sql import SparkSession; spark = SparkSession.builder.getOrCreate(); print('✅ Spark OK')"

# Access JupyterLab
# Click "Jupyter Lab" in the Coder dashboard
```

---

## 🔐 Template Variables

### Common Variables

Both templates support these variables:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `namespace` | Kubernetes namespace for workspaces | `coder` | Yes |
| `use_kubeconfig` | Use ~/.kube/config for auth | `false` | No |

### Data Science Template Variables

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `cpu` | CPU cores | `2` | 2, 4, 6, 8 |
| `memory` | Memory in GB | `2` | 2, 4, 8, 16 |
| `home_disk_size` | Storage in GB | `10` | 10-50 |
| `gpu_count` | Number of GPUs | `0` | 0, 1, 2 |

### Data Engineering Template Variables

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `cpu` | CPU cores | `4` | 4, 8 |
| `memory` | Memory in GB | `8` | 8, 16 |
| `home_disk_size` | Storage in GB | `30` | 20-100 |
| `image` | Container image | `jupyter/pyspark-notebook:latest` | Any valid image |

---

## 📊 Resource Requirements

### Minimum Cluster Requirements

For running both templates simultaneously:

- **CPU**: 12+ cores available
- **Memory**: 24+ GB available
- **Storage**: 100+ GB for PVCs
- **Nodes**: 2+ worker nodes recommended

### Per-Workspace Requirements

**Data Science Workspace:**
- Minimum: 2 CPU, 2 GB RAM, 10 GB storage
- Recommended: 4 CPU, 8 GB RAM, 20 GB storage
- Heavy ML: 8 CPU, 16 GB RAM, 50 GB storage

**Data Engineering Workspace:**
- Minimum: 4 CPU, 8 GB RAM, 30 GB storage
- Recommended: 8 CPU, 16 GB RAM, 50 GB storage

---

## 🛠️ Customization

### Modifying Templates

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/wwt-data-science-templates
   cd wwt-data-science-templates
   ```

2. **Edit template files**
   ```bash
   # Edit main.tf for infrastructure changes
   vim kubernetes-wwt-datascience/main.tf
   
   # Edit README.md for documentation
   vim kubernetes-wwt-datascience/README.md
   ```

3. **Test locally** (optional)
   ```bash
   cd kubernetes-wwt-datascience
   terraform init
   terraform plan
   ```

4. **Push updated template**
   ```bash
   coder templates push kubernetes-wwt-datascience \
     --directory ./kubernetes-wwt-datascience \
     --message "Updated Python packages"
   ```

### Adding New Packages

**Data Science Template:**
Edit the `startup_script` in `kubernetes-wwt-datascience/main.tf`:

```hcl
startup_script = <<-EOT
  # ... existing packages ...
  
  echo "Installing custom packages..."
  pip install your-package-name
EOT
```

**Data Engineering Template:**
Edit the `startup_script` in `data-engineering/main.tf`:

```hcl
startup_script = <<-EOT
  # ... existing setup ...
  
  pip install your-data-package
EOT
```

---

## 🔍 Troubleshooting

### Template Push Issues

```bash
# Check Coder connection
coder version

# Verify authentication
coder login https://coder.example.com

# Check template syntax
cd kubernetes-wwt-datascience
terraform init
terraform validate
```

### Workspace Creation Issues

```bash
# Check template status
coder templates show kubernetes-wwt-datascience

# View workspace build logs
coder logs my-ml-workspace

# Check workspace status
coder list
```

### Common Issues

**Issue: "Template not found"**
```bash
# List available templates
coder templates list

# Verify template name matches
coder templates show <template-name>
```

**Issue: "Insufficient resources"**
```bash
# Check cluster resources
kubectl top nodes
kubectl describe nodes

# Reduce workspace resources
coder create my-workspace --parameter cpu=2 --parameter memory=2
```

**Issue: "PVC creation failed"**
```bash
# Check StorageClass
kubectl get storageclass

# Verify namespace has quota
kubectl describe namespace coder-workspaces
```

---

## 📚 Additional Resources

### Documentation
- [Coder Documentation](https://coder.com/docs)
- [Coder CLI Reference](https://coder.com/docs/cli)
- [Template Development Guide](https://coder.com/docs/templates)
- [Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)

### Template-Specific Docs
- [Data Science Template README](./kubernetes-wwt-datascience/README.md)
- [Data Engineering Template README](./data-engineering/README.md)

### Support
- **Template Issues**: Open an issue in this repository
- **Coder Issues**: [Coder GitHub](https://github.com/coder/coder)
- **Community**: [Coder Discord](https://discord.gg/coder)

---

## 🤝 Contributing

### Adding New Templates

1. Create a new directory for your template
2. Add `main.tf` with Terraform configuration
3. Add `README.md` with template documentation
4. Test the template in a development environment
5. Update this README with template information
6. Submit a pull request

### Template Structure

```
template-name/
├── main.tf           # Terraform configuration
├── README.md         # Template documentation
├── .terraform.lock.hcl  # Terraform lock file (optional)
└── validate.sh       # Validation script (optional)
```

### Best Practices

- ✅ Use descriptive template names
- ✅ Document all parameters and variables
- ✅ Include validation scripts
- ✅ Test with minimum and maximum resources
- ✅ Provide troubleshooting guidance
- ✅ Keep dependencies up to date
- ✅ Use semantic versioning for updates

---

## 📝 Version History

### Data Science Template
- **v2.0** (2026-02-10): Optimized package installation, added validation tools, comprehensive documentation
- **v1.0** (Initial): Basic data science environment

### Data Engineering Template
- **v1.0** (Initial): PySpark environment with JupyterLab

---

## 📄 License

See [LICENSE](./LICENSE) file for details.

---

## 🏢 Maintained By

World Wide Technology (WWT)

For questions or support, contact your Coder administrator or open an issue in this repository.

---

## Quick Reference Card

```bash
# TEMPLATE MANAGEMENT
coder templates list                                    # List templates
coder templates push <name> --directory <path>          # Push template
coder templates show <name>                             # Show template details
coder templates delete <name>                           # Delete template

# WORKSPACE MANAGEMENT
coder create <workspace> --template <template>          # Create workspace
coder list                                              # List workspaces
coder ssh <workspace>                                   # SSH into workspace
coder start/stop <workspace>                            # Start/stop workspace
coder delete <workspace>                                # Delete workspace

# VALIDATION
bash ~/validate_workspace.sh                            # Validate data science workspace
cat ~/QUICK_START.txt                                   # View quick start guide
```

---

**Ready to get started?** Choose a template above and follow the deployment instructions!
