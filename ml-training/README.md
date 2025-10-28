# ML Training Workspace Template

This template creates a Kubernetes workspace for machine learning training with PyTorch and MLflow.

## Features

- **PyTorch Environment**: Uses the PyTorch CUDA container for GPU-accelerated workloads
- **JupyterLab**: Pre-configured JupyterLab environment for interactive development
- **MLflow Tracking**: Built-in MLflow server for experiment tracking and visualization
- **Workspace Resources**: Configurable CPU, memory, and GPU resources
- **Persistent Storage**: Persistent home directory for storing datasets and models

## Usage

After your workspace starts, you'll have access to:

- JupyterLab at the "Jupyter Lab" application tab
- MLflow UI at the "MLflow UI" application tab

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cpu` | CPU cores for the workspace | `4` |
| `memory` | Memory in GB | `16` |
| `gpu_count` | Number of NVIDIA GPUs | `0` (CPU only) |
| `home_disk_size` | Size of persistent home directory in GB | `50` |
| `image` | Container image | `pytorch/pytorch:2.1.0-cuda12.1-cudnn8-devel` |

## Libraries Included

- PyTorch and torchvision
- Transformers and datasets (Hugging Face)
- MLflow
- Ray (for distributed training)
- scikit-learn
- pandas, numpy, matplotlib, seaborn
- JupyterLab with ipywidgets

## Notes

- The home directory persists across workspace rebuilds
- GPU acceleration requires nodes with NVIDIA GPUs and appropriate drivers
- The container runs as user 1000, which is the default 'coder' user