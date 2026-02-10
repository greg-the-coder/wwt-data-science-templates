# Template Deployment Guide

Complete guide for deploying WWT Data Science templates to a Coder instance.

---

## 📋 Pre-Deployment Checklist

### 1. Prerequisites

- [ ] Coder CLI installed (`coder version` works)
- [ ] Authenticated to Coder deployment (`coder login` completed)
- [ ] Kubernetes cluster access configured
- [ ] Namespace created for workspaces
- [ ] StorageClass available for PVCs
- [ ] Sufficient cluster resources available

### 2. Cluster Requirements

**Minimum Resources:**
- [ ] 12+ CPU cores available
- [ ] 24+ GB RAM available
- [ ] 100+ GB storage for PVCs
- [ ] 2+ worker nodes

**Verify Resources:**
```bash
kubectl top nodes
kubectl get storageclass
kubectl describe namespace <your-namespace>
```

### 3. Network Requirements

- [ ] Pods can pull images from Docker Hub
- [ ] Pods can access internet (for pip installs)
- [ ] Ingress/LoadBalancer configured (if using external access)

---

## 🚀 Deployment Steps

### Step 1: Clone Repository

```bash
# Clone the templates repository
git clone https://github.com/your-org/wwt-data-science-templates
cd wwt-data-science-templates
```

### Step 2: Configure Variables

Create a variables file for your environment:

```bash
# Create variables file
cat > deployment-vars.txt <<EOF
namespace=coder-workspaces
use_kubeconfig=false
EOF
```

### Step 3: Deploy Data Science Template

```bash
# Push the template
coder templates push kubernetes-wwt-datascience \
  --directory ./kubernetes-wwt-datascience \
  --name "WWT Data Science" \
  --message "Initial deployment - v2.0" \
  --variable namespace=coder-workspaces \
  --variable use_kubeconfig=false

# Verify deployment
coder templates show kubernetes-wwt-datascience
```

**Expected Output:**
```
Name:        WWT Data Science
Version:     v1
Created:     <timestamp>
Updated:     <timestamp>
Status:      Active
```

### Step 4: Deploy Data Engineering Template

```bash
# Push the template
coder templates push data-engineering \
  --directory ./data-engineering \
  --name "WWT Data Engineering" \
  --message "Initial deployment - v1.0" \
  --variable namespace=coder-workspaces \
  --variable use_kubeconfig=false

# Verify deployment
coder templates show data-engineering
```

### Step 5: Test Template Deployment

Create a test workspace to verify everything works:

```bash
# Create test data science workspace
coder create test-ds-workspace \
  --template kubernetes-wwt-datascience \
  --parameter cpu=2 \
  --parameter memory=4 \
  --parameter home_disk_size=10

# Wait for workspace to start
coder list

# SSH into workspace
coder ssh test-ds-workspace

# Run validation
bash ~/validate_workspace.sh

# Exit workspace
exit

# Clean up test workspace
coder delete test-ds-workspace
```

---

## ✅ Post-Deployment Validation

### 1. Verify Templates

```bash
# List all templates
coder templates list

# Should show:
# - WWT Data Science
# - WWT Data Engineering
```

### 2. Check Template Details

```bash
# Data Science template
coder templates show kubernetes-wwt-datascience

# Data Engineering template
coder templates show data-engineering
```

### 3. Test Workspace Creation

**Data Science Workspace:**
```bash
coder create validation-ds \
  --template kubernetes-wwt-datascience \
  --parameter cpu=2 \
  --parameter memory=4

# Wait for startup (~5 minutes)
coder ssh validation-ds

# Validate
source $HOME/venv/bin/activate
python -c "import numpy, tensorflow, torch, langchain; print('✅ OK')"
bash ~/validate_workspace.sh

exit
```

**Data Engineering Workspace:**
```bash
coder create validation-de \
  --template data-engineering \
  --parameter cpu=4 \
  --parameter memory=8

# Wait for startup
coder ssh validation-de

# Validate
python -c "from pyspark.sql import SparkSession; spark = SparkSession.builder.getOrCreate(); print('✅ OK')"

exit
```

### 4. Clean Up Test Workspaces

```bash
coder delete validation-ds
coder delete validation-de
```

---

## 🔧 Configuration Options

### Namespace Configuration

**Option 1: Single Namespace (Recommended for small deployments)**
```bash
# Create namespace
kubectl create namespace coder-workspaces

# Deploy templates
coder templates push <template> --variable namespace=coder-workspaces
```

**Option 2: Multiple Namespaces (For isolation)**
```bash
# Create namespaces
kubectl create namespace ds-workspaces
kubectl create namespace de-workspaces

# Deploy with different namespaces
coder templates push kubernetes-wwt-datascience --variable namespace=ds-workspaces
coder templates push data-engineering --variable namespace=de-workspaces
```

### Authentication Configuration

**In-Cluster (Coder running in Kubernetes):**
```bash
--variable use_kubeconfig=false
```

**External (Coder running outside Kubernetes):**
```bash
--variable use_kubeconfig=true
```

### Resource Limits

Set default resource limits in the template or via parameters:

```bash
# Small workspaces
--parameter cpu=2 --parameter memory=4

# Medium workspaces
--parameter cpu=4 --parameter memory=8

# Large workspaces
--parameter cpu=8 --parameter memory=16
```

---

## 📊 Monitoring & Maintenance

### Monitor Template Usage

```bash
# List all workspaces
coder list --all

# Show workspaces by template
coder list --template kubernetes-wwt-datascience
coder list --template data-engineering
```

### Monitor Cluster Resources

```bash
# Check node resources
kubectl top nodes

# Check pod resources in namespace
kubectl top pods -n coder-workspaces

# Check PVC usage
kubectl get pvc -n coder-workspaces
```

### Update Templates

```bash
# Pull latest changes
git pull origin main

# Push updated template
coder templates push kubernetes-wwt-datascience \
  --directory ./kubernetes-wwt-datascience \
  --message "Updated to v2.1 - Added new packages"

# Verify new version
coder templates versions list kubernetes-wwt-datascience
```

### Rollback Templates

```bash
# List versions
coder templates versions list kubernetes-wwt-datascience

# Promote previous version
coder templates versions promote kubernetes-wwt-datascience --version v1
```

---

## 🛡️ Security Considerations

### 1. Network Policies

```yaml
# Example NetworkPolicy for workspace isolation
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: workspace-isolation
  namespace: coder-workspaces
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
  - to:
    - podSelector: {}
```

### 2. Resource Quotas

```yaml
# Example ResourceQuota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: workspace-quota
  namespace: coder-workspaces
spec:
  hard:
    requests.cpu: "100"
    requests.memory: "200Gi"
    persistentvolumeclaims: "50"
```

### 3. Pod Security

```yaml
# Example PodSecurityPolicy
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: workspace-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  runAsUser:
    rule: MustRunAsNonRoot
  fsGroup:
    rule: RunAsAny
  volumes:
  - 'configMap'
  - 'emptyDir'
  - 'persistentVolumeClaim'
  - 'secret'
```

---

## 🆘 Troubleshooting

### Template Push Fails

**Issue:** `Error: Failed to push template`

**Solution:**
```bash
# Check authentication
coder login https://coder.example.com

# Verify template syntax
cd kubernetes-wwt-datascience
terraform init
terraform validate

# Check Coder server logs
kubectl logs -n coder deployment/coder
```

### Workspace Creation Fails

**Issue:** `Error: Failed to create workspace`

**Solution:**
```bash
# Check template status
coder templates show <template-name>

# Check cluster resources
kubectl top nodes
kubectl describe nodes

# Check namespace quota
kubectl describe namespace coder-workspaces

# View workspace build logs
coder logs <workspace-name>
```

### PVC Creation Fails

**Issue:** `PersistentVolumeClaim is pending`

**Solution:**
```bash
# Check StorageClass
kubectl get storageclass

# Check PVC status
kubectl describe pvc -n coder-workspaces

# Verify storage provisioner
kubectl get pods -n kube-system | grep provisioner
```

### Package Installation Fails

**Issue:** Packages fail to install in workspace

**Solution:**
```bash
# Check internet connectivity from pod
coder ssh <workspace-name>
curl -I https://pypi.org

# Check for proxy requirements
# May need to set HTTP_PROXY/HTTPS_PROXY in template

# Check startup logs
coder logs <workspace-name>
```

---

## 📚 Additional Resources

### Documentation
- [Main README](./README.md)
- [Quick Reference](./QUICK_REFERENCE.md)
- [Data Science Template](./kubernetes-wwt-datascience/README.md)
- [Data Engineering Template](./data-engineering/README.md)

### Coder Resources
- [Coder Documentation](https://coder.com/docs)
- [Template Development](https://coder.com/docs/templates)
- [Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)

### Support
- GitHub Issues: [Repository Issues](https://github.com/your-org/wwt-data-science-templates/issues)
- Coder Community: [Discord](https://discord.gg/coder)

---

## ✅ Deployment Checklist Summary

- [ ] Prerequisites verified
- [ ] Cluster resources confirmed
- [ ] Namespace created
- [ ] Templates pushed successfully
- [ ] Test workspaces created and validated
- [ ] Documentation reviewed
- [ ] Users notified of new templates
- [ ] Monitoring configured
- [ ] Backup/rollback plan documented

---

**Deployment Complete!** 🎉

Your Coder templates are now ready for use. Share the [README.md](./README.md) and [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) with your users.
