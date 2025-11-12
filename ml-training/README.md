# ML Training Workspace Template

This template creates a Kubernetes workspace for machine learning training with PyTorch, MLflow, and other essential ML tools.

## Features

- **PyTorch Environment**: Uses the official PyTorch CUDA container for GPU-accelerated deep learning
- **JupyterLab**: Pre-configured JupyterLab environment for interactive development
- **MLflow Tracking**: Built-in MLflow server for experiment tracking and model management
- **Workspace Resources**: Configurable CPU, memory, and GPU resources
- **Persistent Storage**: Persistent home directory for storing datasets, models, and experiments
- **Validation Script**: Includes a validation script to verify the environment setup

## Usage

After your workspace starts, you'll have access to:

- JupyterLab at the "Jupyter Lab" application tab
- MLflow UI at the "MLflow UI" application tab

To validate your environment setup, run the validation script:

```bash
python validate_environment.py
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cpu` | CPU cores for the workspace | `4` |
| `memory` | Memory in GB | `16` |
| `gpu_count` | Number of NVIDIA GPUs | `0` (CPU only) |
| `home_disk_size` | Size of persistent home directory in GB | `50` |
| `image` | Container image | `pytorch/pytorch:2.1.0-cuda12.1-cudnn8-devel` |

## Libraries Included

- **Core ML**: PyTorch, torchvision, torchaudio
- **NLP**: Transformers, datasets, tokenizers (Hugging Face)
- **Experiment Tracking**: MLflow, Weights & Biases (wandb)
- **Distributed Training**: Ray, PyTorch Lightning
- **Data Processing**: pandas, numpy, scikit-learn, dask
- **Visualization**: matplotlib, seaborn, plotly
- **Jupyter**: JupyterLab with ipywidgets and extensions
- **Utilities**: tqdm, requests, pillow, opencv-python

## Environment Validation

The included `validate_environment.py` script checks:

- System information (CPU, memory, OS)
- GPU availability and configuration
- MLflow server connectivity
- PyTorch operations (CPU and GPU)
- Data loading and processing capabilities
- Common environment issues

## Notes

- The home directory (`/home/coder`) persists across workspace rebuilds
- GPU acceleration requires nodes with NVIDIA GPUs and appropriate drivers
- The container runs as user 1000 (default 'coder' user)
- For production use, consider:
  - Setting up proper authentication for MLflow
  - Configuring persistent storage for MLflow artifacts
  - Implementing resource quotas and limits
  - Setting up monitoring and logging

## Troubleshooting

- If MLflow UI is not accessible, ensure the MLflow server is running:
  ```bash
  mlflow server --host 0.0.0.0 --port 5000 &
  ```
- For GPU-related issues, verify that:
  - NVIDIA drivers are installed on the host
  - The container has access to the GPU devices
  - The CUDA version matches between PyTorch and the host system