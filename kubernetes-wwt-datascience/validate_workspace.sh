#!/bin/bash
# Workspace Validation Script for WWT Data Science Template
# Run this after workspace creation to verify all components

set -e

echo "=========================================="
echo "WWT Data Science Workspace Validation"
echo "=========================================="
echo ""

# Activate virtual environment
if [ -d "$HOME/venv" ]; then
    source $HOME/venv/bin/activate
else
    echo "❌ Virtual environment not found at $HOME/venv"
    exit 1
fi

# Test 1: Python Environment
echo "✓ Test 1: Python Environment"
echo "------------------------------------------"
PYTHON_VERSION=$(python --version 2>&1)
PYTHON_PATH=$(which python)
echo "Version: $PYTHON_VERSION"
echo "Location: $PYTHON_PATH"

if [[ "$PYTHON_PATH" == *"/home/coder/venv"* ]]; then
    echo "✅ Using virtual environment Python"
else
    echo "⚠️  Warning: Not using venv Python"
fi
echo ""

# Test 2: Jupyter Kernel
echo "✓ Test 2: Jupyter Kernel"
echo "------------------------------------------"
if jupyter kernelspec list | grep -q "venv"; then
    echo "✅ Jupyter kernel 'venv' is registered"
    KERNEL_PATH=$(jupyter kernelspec list | grep venv | awk '{print $2}')
    echo "   Location: $KERNEL_PATH"
else
    echo "❌ Jupyter kernel 'venv' not found"
    echo "   Run: python -m ipykernel install --user --name=venv --display-name 'Python 3.12 Coder (venv)'"
fi
echo ""

# Test 3: Core Packages
echo "✓ Test 3: Core Package Imports"
echo "------------------------------------------"
python -c "
import sys

packages = [
    ('NumPy', 'numpy'),
    ('Pandas', 'pandas'),
    ('Matplotlib', 'matplotlib'),
    ('SciPy', 'scipy'),
    ('TensorFlow', 'tensorflow'),
    ('PyTorch', 'torch'),
    ('scikit-learn', 'sklearn'),
    ('Transformers', 'transformers'),
    ('LangChain', 'langchain'),
    ('ChromaDB', 'chromadb'),
    ('Streamlit', 'streamlit'),
    ('OpenCV', 'cv2'),
]

failed = []
for name, module in packages:
    try:
        mod = __import__(module)
        version = getattr(mod, '__version__', 'N/A')
        print(f'✅ {name:15} {version}')
    except ImportError as e:
        print(f'❌ {name:15} FAILED')
        failed.append(name)

if failed:
    print(f'\n⚠️  {len(failed)} package(s) failed: {failed}')
    sys.exit(1)
" 2>&1 | grep -v "Could not find cuda" | grep -v "GPU will not be used" | grep -v "TensorFlow binary is optimized"
echo ""

# Test 4: VS Code Extensions
echo "✓ Test 4: VS Code Extensions"
echo "------------------------------------------"
if [ -f "/tmp/code-server/bin/code-server" ]; then
    EXTENSION_COUNT=$(/tmp/code-server/bin/code-server --list-extensions 2>/dev/null | wc -l)
    echo "✅ Code-server installed"
    echo "   Extensions: $EXTENSION_COUNT"
    echo ""
    echo "   Installed extensions:"
    /tmp/code-server/bin/code-server --list-extensions 2>/dev/null | sed 's/^/   - /'
else
    echo "⚠️  Code-server not found at /tmp/code-server"
fi
echo ""

# Test 5: Code-server Health
echo "✓ Test 5: Code-server Status"
echo "------------------------------------------"
if curl -s http://localhost:13337/healthz > /dev/null 2>&1; then
    echo "✅ Code-server is running and healthy"
    echo "   URL: http://localhost:13337"
elif ps aux | grep -v grep | grep -q "code-server"; then
    echo "⚠️  Code-server process running but not responding"
    echo "   Check logs: tail -f /tmp/code-server.log"
else
    echo "❌ Code-server is not running"
    echo "   Start with: /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &"
fi
echo ""

# Test 6: Quick Computation
echo "✓ Test 6: Computation Test"
echo "------------------------------------------"
python -c "
import numpy as np
import pandas as pd

# Quick test
arr = np.random.rand(3, 3)
df = pd.DataFrame(arr, columns=['A', 'B', 'C'])
mean_val = df.mean().values[0]

print(f'✅ NumPy array created: {arr.shape}')
print(f'✅ Pandas DataFrame created: {df.shape}')
print(f'✅ Computation successful (mean: {mean_val:.4f})')
"
echo ""

# Test 7: Disk Space
echo "✓ Test 7: Disk Space"
echo "------------------------------------------"
HOME_USAGE=$(df -h $HOME | tail -1 | awk '{print $5}')
HOME_AVAIL=$(df -h $HOME | tail -1 | awk '{print $4}')
echo "Home directory usage: $HOME_USAGE"
echo "Available space: $HOME_AVAIL"

USAGE_NUM=$(echo $HOME_USAGE | sed 's/%//')
if [ "$USAGE_NUM" -lt 80 ]; then
    echo "✅ Sufficient disk space"
else
    echo "⚠️  Disk usage is high (${HOME_USAGE})"
fi
echo ""

# Summary
echo "=========================================="
echo "✅ VALIDATION COMPLETE"
echo "=========================================="
echo ""
echo "Your workspace is ready for:"
echo "  • Data Science & ML development"
echo "  • Jupyter notebook work"
echo "  • LLM application development"
echo "  • Python scripting"
echo ""
echo "Quick start commands:"
echo "  source \$HOME/venv/bin/activate    # Activate Python environment"
echo "  jupyter notebook                   # Start Jupyter"
echo "  python your_script.py              # Run Python scripts"
echo "  streamlit run app.py               # Run Streamlit apps"
echo ""
echo "Access VS Code at: http://localhost:13337"
echo ""
