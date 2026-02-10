---
display_name: WWT Data Science Workspace
description: Full-featured data science and ML workspace with TensorFlow, PyTorch, LangChain, and more
icon: ../../../site/static/icon/k8s.png
maintainer_github: wwt
verified: true
tags: [kubernetes, data-science, machine-learning, python, jupyter, llm]
---

# WWT Data Science Workspace Template

A production-ready Coder workspace template for data science, machine learning, and LLM development on Kubernetes. Pre-configured with 27+ essential packages including TensorFlow, PyTorch, LangChain, and ChromaDB.

## 🚀 Features

### Pre-installed Python Packages (27+)
- **ML Frameworks**: TensorFlow 2.20, PyTorch 2.10 (CPU), scikit-learn, XGBoost
- **Data Science**: NumPy, Pandas, Polars, SciPy, Statsmodels
- **Visualization**: Matplotlib, Seaborn, Plotly
- **NLP**: spaCy, Transformers, Tokenizers, Datasets
- **LLM Development**: LangChain, LangChain OpenAI, LangGraph
- **Vector Database**: ChromaDB
- **Web Apps**: Streamlit
- **Computer Vision**: OpenCV (headless)
- **Utilities**: Pydantic, python-dotenv, requests, ipykernel

### Development Environment
- **IDE**: VS Code (code-server) with 9 pre-installed extensions
- **Jupyter**: Registered kernel for notebook development
- **Python**: 3.12 in isolated virtual environment
- **Persistent Storage**: Home directory persisted across restarts

### VS Code Extensions
- Python (ms-python.python)
- AREPL (live Python scratchpad)
- AutoDocstring
- Ruff (fast Python linter)
- Rainbow CSV
- Docker support
- Code spell checker
- Python indent helper
- VS Code icons

### Configurable Resources
- **CPU**: 2, 4, 6, or 8 cores
- **Memory**: 2, 4, 8, or 16 GB
- **Storage**: 10-50 GB persistent home directory
- **GPU**: Optional NVIDIA GPU support (0, 1, or 2 GPUs)

## 📋 Prerequisites

### Infrastructure
- **Kubernetes Cluster**: Existing cluster with sufficient resources
- **Namespace**: Pre-created namespace for workspaces
- **Storage**: StorageClass supporting ReadWriteOnce PVCs

### Authentication
This template authenticates using:
- `~/.kube/config` (if `use_kubeconfig = true`)
- ServiceAccount (if Coder runs in-cluster)

## 🏗️ Architecture

### Resources Provisioned
- **Kubernetes Deployment**: Workspace pod with configurable resources
- **Persistent Volume Claim**: Home directory storage (10-50 GB)
- **Coder Agent**: Workspace management and monitoring
- **Code-server**: Web-based VS Code IDE

### Persistence Model
- ✅ **Persistent**: `/home/coder` (all user files, venv, notebooks)
- ⚠️ **Ephemeral**: System packages, OS-level changes

The Python virtual environment and all installed packages are in `/home/coder/venv`, making them persistent across workspace restarts.

## ✅ Workspace Validation

Once your workspace starts, validate the configuration with these commands:

### Quick Health Check (30 seconds)
```bash
# 1. Check Python and venv
source $HOME/venv/bin/activate
python --version
which python  # Should show /home/coder/venv/bin/python

# 2. Verify Jupyter kernel
jupyter kernelspec list | grep venv && echo "✅ Kernel OK" || echo "❌ Not found"

# 3. Test key packages
python -c "import numpy, pandas, tensorflow, torch, langchain, chromadb; print('✅ All packages work!')"
```

### Comprehensive Test (2 minutes)
```bash
# Run full validation
cat > ~/validate_workspace.sh <<'EOF'
#!/bin/bash
set -e
source $HOME/venv/bin/activate

echo "=== Workspace Validation ==="
echo ""

# Test 1: Python environment
echo "✓ Python Environment"
python --version
echo "  Location: $(which python)"
echo ""

# Test 2: Jupyter kernel
echo "✓ Jupyter Kernel"
jupyter kernelspec list
echo ""

# Test 3: Package imports
echo "✓ Package Imports"
python -c "
packages = [
    'numpy', 'pandas', 'matplotlib', 'scipy',
    'tensorflow', 'torch', 'scikit-learn',
    'transformers', 'langchain', 'chromadb', 'streamlit'
]
for pkg in packages:
    try:
        __import__(pkg)
        print(f'  ✅ {pkg}')
    except ImportError:
        print(f'  ❌ {pkg} FAILED')
"
echo ""

# Test 4: VS Code extensions
echo "✓ VS Code Extensions"
/tmp/code-server/bin/code-server --list-extensions | head -5
echo ""

echo "=== Validation Complete ==="
EOF

chmod +x ~/validate_workspace.sh
~/validate_workspace.sh
```

### Individual Component Tests

#### Test Python Packages
```bash
source $HOME/venv/bin/activate

# Test ML frameworks
python -c "import tensorflow as tf; print(f'TensorFlow: {tf.__version__}')"
python -c "import torch; print(f'PyTorch: {torch.__version__}')"

# Test LLM tools
python -c "import langchain; print(f'LangChain: {langchain.__version__}')"
python -c "import chromadb; print(f'ChromaDB: {chromadb.__version__}')"

# Test data science
python -c "import numpy, pandas; print('NumPy & Pandas OK')"
```

#### Test Jupyter Kernel
```bash
# List kernels
jupyter kernelspec list

# View kernel config
cat ~/.local/share/jupyter/kernels/venv/kernel.json

# Start interactive console
jupyter console --kernel=venv
# (Type 'exit()' to quit)
```

#### Test VS Code Extensions
```bash
# List installed extensions
/tmp/code-server/bin/code-server --list-extensions

# Check code-server is running
curl -s http://localhost:13337/healthz && echo "✅ Code-server OK"
```

#### Test Computation
```bash
source $HOME/venv/bin/activate
python -c "
import numpy as np
import pandas as pd

# Quick computation test
arr = np.random.rand(5, 5)
df = pd.DataFrame(arr)
print('Sample DataFrame:')
print(df.head())
print(f'\nMean: {df.mean().values}')
print('✅ Computation successful')
"
```

## 🔧 Troubleshooting

### Virtual Environment Issues
```bash
# Recreate venv if needed
rm -rf $HOME/venv
python3 -m venv $HOME/venv
source $HOME/venv/bin/activate
pip install --upgrade pip

# Reinstall packages (see startup_script in main.tf)
```

### Jupyter Kernel Not Found
```bash
# Re-register kernel
source $HOME/venv/bin/activate
python -m ipykernel install --user --name=venv --display-name "Python 3.12 Coder (venv)"

# Verify
jupyter kernelspec list
```

### Package Import Errors
```bash
# Check if package is installed
source $HOME/venv/bin/activate
pip list | grep tensorflow

# Reinstall specific package
pip install --force-reinstall tensorflow
```

### Code-server Not Accessible
```bash
# Check if running
ps aux | grep code-server

# Check logs
tail -f /tmp/code-server.log

# Restart manually
/tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &
```

## 📊 Resource Monitoring

The workspace includes built-in monitoring:

```bash
# CPU usage
coder stat cpu

# Memory usage
coder stat mem

# Disk usage
coder stat disk --path $HOME

# Host metrics
coder stat cpu --host
coder stat mem --host
```

## 🎯 Common Use Cases

### Data Science Workflow
```bash
source $HOME/venv/bin/activate

# Create a new notebook
jupyter notebook  # Or use VS Code UI

# Run analysis
python analysis.py

# Visualize results
streamlit run dashboard.py
```

### Machine Learning Development
```bash
source $HOME/venv/bin/activate

# Train a model
python train_model.py

# Evaluate
python evaluate.py

# Export
python export_model.py
```

### LLM Application Development
```bash
source $HOME/venv/bin/activate

# Test LangChain
python -c "
from langchain.llms import OpenAI
from langchain.chains import LLMChain
print('LangChain ready!')
"

# Use ChromaDB
python -c "
import chromadb
client = chromadb.Client()
print('ChromaDB ready!')
"
```

## 🔄 Updating the Template

To modify installed packages, edit the `startup_script` in `main.tf`:

```hcl
resource "coder_agent" "main" {
  startup_script = <<-EOT
    # Add your custom packages here
    pip install your-package
  EOT
}
```

## 📚 Additional Resources

- [Coder Documentation](https://coder.com/docs)
- [Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Python Virtual Environments](https://docs.python.org/3/library/venv.html)
- [Jupyter Kernels](https://jupyter-client.readthedocs.io/en/stable/kernels.html)

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review workspace logs: `tail -f /tmp/code-server.log`
3. Contact your Coder administrator

## 📝 Version Information

- **Python**: 3.12
- **TensorFlow**: 2.20.0
- **PyTorch**: 2.10.0 (CPU)
- **LangChain**: 1.2.10
- **Base Image**: codercom/enterprise-base:ubuntu

---

**Note**: This template installs CPU-only versions of ML frameworks. For GPU support, modify the PyTorch installation and ensure GPU resources are available in your cluster.
