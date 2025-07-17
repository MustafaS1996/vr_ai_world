#!/bin/bash

# Setup local Kubernetes cluster for testing VR AI World
set -e

echo "🔧 Setting up local Kubernetes cluster with Kind..."

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "Installing Kind (Kubernetes in Docker)..."
    # Download kind
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
fi

# Create kind cluster configuration for GPU support (simulation)
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: vr-ai-world
nodes:
- role: control-plane
  image: kindest/node:v1.31.0
  extraPortMappings:
  - containerPort: 30000
    hostPort: 3000
    protocol: TCP
- role: worker
  image: kindest/node:v1.31.0
  labels:
    accelerator: nvidia-tesla-gpu  # Simulate GPU node
- role: worker  
  image: kindest/node:v1.31.0
  labels:
    kubernetes.io/arch: amd64  # CPU-only node
EOF

echo "🚀 Creating Kind cluster..."
kind create cluster --config kind-config.yaml

echo "✅ Cluster created! Testing connection..."
kubectl cluster-info --context kind-vr-ai-world

echo "📦 Loading Docker images into Kind cluster..."
kind load docker-image vr-ai-world/inference:latest --name vr-ai-world || echo "Inference image not built yet"
kind load docker-image vr-ai-world/frontend:latest --name vr-ai-world || echo "Frontend image not built yet"

echo "🔧 Setting up kubectl context..."
kubectl config use-context kind-vr-ai-world

echo "✅ Local Kubernetes cluster ready!"
echo "Next steps:"
echo "1. Run ./build-and-deploy.sh to build and deploy the application"
echo "2. Use 'kubectl port-forward service/frontend-service 3000:80 -n vr-ai-world' to access the app"
echo "3. To cleanup: kind delete cluster --name vr-ai-world"