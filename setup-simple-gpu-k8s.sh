#!/bin/bash

# Setup local Kubernetes cluster with basic GPU support
set -e

echo "🔧 Setting up local Kubernetes cluster for GPU testing..."

# Check if NVIDIA GPUs are available
if ! nvidia-smi > /dev/null 2>&1; then
    echo "❌ Error: NVIDIA drivers not found."
    exit 1
fi

KIND_CMD="./kind"
if command -v kind &> /dev/null; then
    KIND_CMD="kind"
fi

# Create simple kind cluster configuration 
cat <<EOF > kind-simple-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: vr-ai-world-gpu
nodes:
- role: control-plane
  image: kindest/node:v1.31.0
  extraPortMappings:
  - containerPort: 30000
    hostPort: 3000
    protocol: TCP
  - containerPort: 30001  
    hostPort: 8000
    protocol: TCP
- role: worker
  image: kindest/node:v1.31.0
  labels:
    accelerator: nvidia-tesla-gpu
EOF

echo "🚀 Creating Kind cluster..."
$KIND_CMD create cluster --config kind-simple-config.yaml

echo "✅ Cluster created! Setting kubectl context..."
kubectl config use-context kind-vr-ai-world-gpu

echo "🏷️  Labeling nodes for GPU scheduling..."
kubectl label nodes --all accelerator=nvidia-tesla-gpu --overwrite

# For Kind, we'll simulate GPU resources since direct GPU passthrough is complex
echo "🔧 Adding simulated GPU resources to nodes..."
kubectl patch node vr-ai-world-gpu-worker -p '{"status":{"capacity":{"nvidia.com/gpu":"2"},"allocatable":{"nvidia.com/gpu":"2"}}}'

echo "✅ Local Kubernetes cluster ready with simulated GPU resources!"
echo ""
echo "📝 Note: This setup simulates GPU resources for testing the deployment architecture."
echo "The inference service will run in CPU mode but the K8s deployment will be identical to production."
echo ""
echo "📝 Next steps:"
echo "1. Run: ./deploy-gpu-test.sh (deploy with real GPU support)"  
echo "2. Or run: ./deploy-test.sh (deploy CPU-only version)"
echo "3. To cleanup: $KIND_CMD delete cluster --name vr-ai-world-gpu"