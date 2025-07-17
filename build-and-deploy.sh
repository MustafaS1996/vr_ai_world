#!/bin/bash

# Build and Deploy VR AI World to Kubernetes (GPU Production Version)
set -e

echo "🔍 This script deploys the GPU-enabled production version."
echo "For testing without GPU, use: ./deploy-test.sh"
echo "For cloud setup guide, see: setup-cloud-k8s.md"
echo ""

# Use the GPU deployment script
./deploy-gpu.sh