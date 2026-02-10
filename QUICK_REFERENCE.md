# Coder Templates - Quick Reference

## 🚀 Essential Commands

### Template Deployment

```bash
# Push Data Science Template
coder templates push kubernetes-wwt-datascience \
  --directory ./kubernetes-wwt-datascience \
  --name "WWT Data Science" \
  --variable namespace=coder-workspaces

# Push Data Engineering Template
coder templates push data-engineering \
  --directory ./data-engineering \
  --name "WWT Data Engineering" \
  --variable namespace=coder-workspaces

# Update Existing Template
coder templates push <template-name> \
  --directory ./<template-dir> \
  --message "Update description"
```

### Template Management

```bash
# List all templates
coder templates list

# Show template details
coder templates show <template-name>

# List template versions
coder templates versions list <template-name>

# Delete template
coder templates delete <template-name>
```

### Workspace Operations

```bash
# Create workspace
coder create <workspace-name> \
  --template <template-name> \
  --parameter cpu=4 \
  --parameter memory=8

# List workspaces
coder list

# SSH into workspace
coder ssh <workspace-name>

# Start/stop workspace
coder start <workspace-name>
coder stop <workspace-name>

# Delete workspace
coder delete <workspace-name>
```

---

## 📋 Template Parameters

### Data Science Template

| Parameter | Values | Default |
|-----------|--------|---------|
| cpu | 2, 4, 6, 8 | 2 |
| memory | 2, 4, 8, 16 | 2 |
| home_disk_size | 10-50 | 10 |
| gpu_count | 0, 1, 2 | 0 |

**Example:**
```bash
coder create ml-workspace \
  --template kubernetes-wwt-datascience \
  --parameter cpu=4 \
  --parameter memory=8 \
  --parameter home_disk_size=20
```

### Data Engineering Template

| Parameter | Values | Default |
|-----------|--------|---------|
| cpu | 4, 8 | 4 |
| memory | 8, 16 | 8 |
| home_disk_size | 20-100 | 30 |

**Example:**
```bash
coder create de-workspace \
  --template data-engineering \
  --parameter cpu=8 \
  --parameter memory=16 \
  --parameter home_disk_size=50
```

---

## ✅ Validation Commands

### Data Science Workspace

```bash
# Quick check
source $HOME/venv/bin/activate
python -c "import numpy, tensorflow, torch, langchain; print('✅ OK')"

# Full validation
bash ~/validate_workspace.sh

# View quick start
cat ~/QUICK_START.txt
```

### Data Engineering Workspace

```bash
# Test PySpark
python -c "from pyspark.sql import SparkSession; spark = SparkSession.builder.getOrCreate(); print('✅ OK')"

# Access JupyterLab
# Click "Jupyter Lab" in Coder dashboard
```

---

## 🔧 Common Variables

```bash
# Set namespace
--variable namespace=coder-workspaces

# Use kubeconfig
--variable use_kubeconfig=true

# Custom image (data engineering)
--variable image=jupyter/pyspark-notebook:latest
```

---

## 📊 Resource Recommendations

### Light Workload
```bash
--parameter cpu=2 --parameter memory=4
```

### Standard Workload
```bash
--parameter cpu=4 --parameter memory=8
```

### Heavy Workload
```bash
--parameter cpu=8 --parameter memory=16
```

---

## 🆘 Troubleshooting

```bash
# Check connection
coder version

# View workspace logs
coder logs <workspace-name>

# Check template
coder templates show <template-name>

# Validate Terraform
cd <template-dir>
terraform init
terraform validate
```

---

## 📚 Quick Links

- **Main README**: [README.md](./README.md)
- **Data Science Template**: [kubernetes-wwt-datascience/README.md](./kubernetes-wwt-datascience/README.md)
- **Data Engineering Template**: [data-engineering/README.md](./data-engineering/README.md)
- **Coder Docs**: https://coder.com/docs
- **CLI Reference**: https://coder.com/docs/cli

---

## 💡 Pro Tips

1. **Always test templates** in a dev environment first
2. **Use version messages** when pushing updates
3. **Set appropriate resources** based on workload
4. **Monitor cluster resources** before creating workspaces
5. **Use validation scripts** after workspace creation
6. **Keep templates updated** with latest package versions

---

**Need help?** See the main [README.md](./README.md) for detailed documentation.
