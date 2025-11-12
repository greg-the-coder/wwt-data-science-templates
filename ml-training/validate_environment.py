"""
ML Training Environment Validation Script

This script validates that the ML training environment is properly configured
with all required dependencies and hardware acceleration.
"""

import platform
import sys
import psutil
import cpuinfo
import torch
import mlflow
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime
import os
from pathlib import Path

print("=" * 80)
print("ML Training Environment Validation")
print("=" * 80)
print()

# 1. System Information
print("1. System Information")
print("-" * 30)
print(f"Python version: {sys.version}")
print(f"Platform: {platform.platform()}")
print(f"CPU: {cpuinfo.get_cpu_info()['brand_raw']}")
print(f"Physical cores: {psutil.cpu_count(logical=False)}")
print(f"Total memory: {psutil.virtual_memory().total / (1024**3):.1f} GB")
print()

# 2. GPU Information
print("2. GPU Information")
print("-" * 30)
print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")

if torch.cuda.is_available():
    print(f"CUDA version: {torch.version.cuda}")
    print(f"Number of GPUs: {torch.cuda.device_count()}")
    for i in range(torch.cuda.device_count()):
        print(f"  GPU {i}: {torch.cuda.get_device_name(i)}")
        print(f"    Memory: {torch.cuda.get_device_properties(i).total_memory / 1024**3:.1f} GB")
else:
    print("No GPU available, using CPU")
print()

# 3. Verify MLflow Integration
print("3. MLflow Integration")
print("-" * 30)
try:
    mlflow.set_tracking_uri("http://localhost:5000")
    print(f"MLflow version: {mlflow.__version__}")
    print(f"MLflow tracking URI: {mlflow.get_tracking_uri()}")
    
    # Log a simple test run
    with mlflow.start_run(run_name="Environment Validation"):
        mlflow.log_param("test_param", 42)
        mlflow.log_metric("test_metric", 0.95)
        
        # Log a simple artifact
        test_data = {"test": [1, 2, 3], "values": [0.1, 0.2, 0.3]}
        df = pd.DataFrame(test_data)
        artifact_dir = "mlruns/artifacts"
        os.makedirs(artifact_dir, exist_ok=True)
        artifact_path = os.path.join(artifact_dir, "test_data.csv")
        df.to_csv(artifact_path, index=False)
        
        mlflow.log_artifact(artifact_path)
        print("✅ Successfully logged to MLflow")
        print(f"   View at: {mlflow.get_tracking_uri()}")
        
except Exception as e:
    print(f"❌ MLflow test failed: {str(e)}")
    print("   Make sure the MLflow server is running at http://localhost:5000")
print()

# 4. Test PyTorch Operations
print("4. PyTorch Operations")
print("-" * 30)
try:
    # Create random data
    x = torch.randn(3, 3)
    print("Random tensor (CPU):")
    print(x)
    
    if torch.cuda.is_available():
        # Move tensor to GPU if available
        x = x.cuda()
        print("\nRandom tensor (GPU):")
        print(x)
        
        # Perform a simple matrix multiplication on GPU
        y = torch.mm(x, x)
        print("\nMatrix multiplication result (GPU):")
        print(y)
    
    print("✅ PyTorch operations completed successfully")
except Exception as e:
    print(f"❌ PyTorch test failed: {str(e)}")
print()

# 5. Test Data Loading and Processing
print("5. Data Loading and Processing")
print("-" * 30)
try:
    from torchvision import datasets, transforms
    from torch.utils.data import DataLoader
    
    # Create a simple dataset
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.5,), (0.5,))
    ])
    
    # Test if we can load a small dataset (using CIFAR10 as an example)
    test_dataset = datasets.CIFAR10(
        root='./data', 
        train=False, 
        download=True, 
        transform=transform
    )
    
    test_loader = DataLoader(
        test_dataset, 
        batch_size=4, 
        shuffle=True, 
        num_workers=2
    )
    
    print(f"Successfully loaded {len(test_dataset)} test samples")
    print(f"Batch size: {next(iter(test_loader))[0].shape}")
    print("✅ Data loading and processing tests passed")
    
except Exception as e:
    print(f"❌ Data loading test failed: {str(e)}")
print()

# 6. Environment Summary
print("=" * 80)
print("Environment Validation Summary")
print("=" * 80)
print(f"Validation completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print()

# Check for common issues
issues = []
warnings = []

if not torch.cuda.is_available():
    warnings.append("No GPU detected. Training will be performed on CPU which may be slow.")

if not os.path.exists("mlruns"):
    warnings.append("MLflow run directory not found. Make sure MLflow server is running.")

# Print any warnings
if warnings:
    print("⚠️  Warnings:")
    for warning in warnings:
        print(f"   - {warning}")

# Print any critical issues
if issues:
    print("\n❌ Critical issues found:")
    for issue in issues:
        print(f"   - {issue}")
    print("\nPlease fix the above issues before proceeding with ML training.")
else:
    print("\n✅ Environment is properly configured for ML training!")
    print("   You can now start working with PyTorch and MLflow.")
