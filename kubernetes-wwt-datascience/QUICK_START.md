# WWT Data Science Workspace - Quick Start Guide

## 🚀 First Steps

### 1. Activate Python Environment
```bash
source $HOME/venv/bin/activate
```

### 2. Validate Workspace
```bash
# Quick check (30 seconds)
python -c "import numpy, pandas, tensorflow, torch, langchain; print('✅ Ready!')"

# Full validation (2 minutes)
bash ~/validate_workspace.sh
```

### 3. Access VS Code
Open in browser: `http://localhost:13337`

---

## 📦 Installed Packages

### Machine Learning
- TensorFlow 2.20 (CPU)
- PyTorch 2.10 (CPU)
- scikit-learn 1.8
- XGBoost 3.2

### Data Science
- NumPy 2.4
- Pandas 2.3
- Polars 1.38
- SciPy 1.17

### Visualization
- Matplotlib 3.10
- Seaborn 0.13
- Plotly 6.5

### NLP & LLM
- Transformers 5.1
- spaCy 3.8
- LangChain 1.2
- ChromaDB 1.5

### Web & Utilities
- Streamlit 1.54
- Jupyter/IPython
- OpenCV (headless)
- Pydantic, requests

---

## 🎯 Common Commands

### Python Development
```bash
# Activate environment (always do this first!)
source $HOME/venv/bin/activate

# Run a script
python my_script.py

# Install additional packages
pip install package-name

# List installed packages
pip list
```

### Jupyter Notebooks
```bash
# List available kernels
jupyter kernelspec list

# Start Jupyter console
jupyter console --kernel=venv

# Create a notebook (use VS Code UI or)
jupyter notebook
```

### Data Science Workflow
```bash
# Quick data analysis
python -c "
import pandas as pd
df = pd.read_csv('data.csv')
print(df.describe())
"

# Run Streamlit app
streamlit run dashboard.py
```

### Machine Learning
```bash
# Test TensorFlow
python -c "import tensorflow as tf; print(tf.__version__)"

# Test PyTorch
python -c "import torch; print(torch.__version__)"

# Train a model
python train.py
```

### LLM Development
```bash
# Test LangChain
python -c "
from langchain.llms import OpenAI
print('LangChain ready!')
"

# Test ChromaDB
python -c "
import chromadb
client = chromadb.Client()
print('ChromaDB ready!')
"
```

---

## 🔍 Validation Commands

### Quick Health Check
```bash
# One-liner validation
source $HOME/venv/bin/activate && \
python -c "import numpy, tensorflow, torch, langchain; print('✅ All OK')"
```

### Check Specific Components
```bash
# Python version
python --version

# Jupyter kernel
jupyter kernelspec list | grep venv

# VS Code status
curl -s http://localhost:13337/healthz && echo "✅ VS Code OK"

# Package versions
python -c "
import numpy, pandas, tensorflow, torch, langchain
print(f'NumPy: {numpy.__version__}')
print(f'Pandas: {pandas.__version__}')
print(f'TensorFlow: {tensorflow.__version__}')
print(f'PyTorch: {torch.__version__}')
print(f'LangChain: {langchain.__version__}')
"
```

---

## 🛠️ Troubleshooting

### Virtual Environment Not Active
```bash
# Activate it
source $HOME/venv/bin/activate

# Verify
which python  # Should show /home/coder/venv/bin/python
```

### Package Not Found
```bash
# Check if installed
pip list | grep package-name

# Install if missing
pip install package-name
```

### Jupyter Kernel Missing
```bash
# Re-register kernel
source $HOME/venv/bin/activate
python -m ipykernel install --user --name=venv --display-name "Python 3.12 Coder (venv)"
```

### VS Code Not Accessible
```bash
# Check if running
ps aux | grep code-server

# Check logs
tail -f /tmp/code-server.log

# Restart if needed
/tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &
```

---

## 📊 Resource Monitoring

```bash
# CPU usage
coder stat cpu

# Memory usage
coder stat mem

# Disk usage
coder stat disk --path $HOME
```

---

## 💡 Tips & Best Practices

### Always Activate venv
Add to your `~/.bashrc`:
```bash
# Auto-activate venv
if [ -d "$HOME/venv" ] && [ -z "$VIRTUAL_ENV" ]; then
    source $HOME/venv/bin/activate
fi
```

### Save Your Work
Everything in `/home/coder` is persistent. Save your work there:
```bash
~/projects/       # Your projects
~/notebooks/      # Jupyter notebooks
~/data/          # Datasets
~/models/        # Trained models
```

### Use Jupyter in VS Code
1. Open a `.ipynb` file
2. Click kernel selector (top right)
3. Choose "Python 3.12 Coder (venv)"
4. Start coding!

### Install Additional Packages
```bash
source $HOME/venv/bin/activate
pip install your-package

# For permanent installation, add to main.tf startup_script
```

---

## 📚 Resources

- **Workspace README**: See full documentation in README.md
- **Validation Script**: Run `bash ~/validate_workspace.sh`
- **Coder Docs**: https://coder.com/docs
- **Python Docs**: https://docs.python.org/3.12/

---

## 🆘 Getting Help

1. Run validation: `bash ~/validate_workspace.sh`
2. Check logs: `tail -f /tmp/code-server.log`
3. Contact your Coder administrator

---

**Remember**: Always activate the virtual environment first!
```bash
source $HOME/venv/bin/activate
```
