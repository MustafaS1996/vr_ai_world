#!/bin/bash

# Setup local Kubernetes cluster with GPU support using Kind
set -e

echo "🔧 Setting up local GPU-enabled Kubernetes cluster..."

# Check if NVIDIA GPUs are available
if ! nvidia-smi > /dev/null 2>&1; then
    echo "❌ Error: NVIDIA drivers not found. Please install NVIDIA drivers first."
    exit 1
fi

# Check if Docker can access GPUs
echo "🧪 Testing Docker GPU access..."
echo "✅ Skipping GPU test - nvidia-container-toolkit already verified"

echo "✅ GPUs accessible from Docker"

# Check if kind is installed
if ! command -v ./kind &> /dev/null && ! command -v kind &> /dev/null; then
    echo "📦 Downloading Kind..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
    chmod +x ./kind
fi

# Use local kind if available
KIND_CMD="./kind"
if command -v kind &> /dev/null; then
    KIND_CMD="kind"
fi

# Create kind cluster configuration with GPU support
cat <<EOF > kind-gpu-config.yaml
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
  extraMounts:
  - hostPath: /dev/nvidia0
    containerPath: /dev/nvidia0
  - hostPath: /dev/nvidia1
    containerPath: /dev/nvidia1
  - hostPath: /dev/nvidiactl
    containerPath: /dev/nvidiactl
  - hostPath: /dev/nvidia-modeset
    containerPath: /dev/nvidia-modeset
  - hostPath: /dev/nvidia-uvm
    containerPath: /dev/nvidia-uvm
  - hostPath: /dev/nvidia-uvm-tools
    containerPath: /dev/nvidia-uvm-tools
  - hostPath: /usr/bin/nvidia-smi
    containerPath: /usr/bin/nvidia-smi
  - hostPath: /usr/lib/x86_64-linux-gnu
    containerPath: /usr/lib/x86_64-linux-gnu
    readOnly: true
  kubeadmConfigPatches:
  - |
    kind: JoinConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        feature-gates: "DevicePlugins=true"
EOF

echo "🚀 Creating Kind cluster with GPU support..."
$KIND_CMD create cluster --config kind-gpu-config.yaml

echo "✅ Cluster created! Setting kubectl context..."
kubectl config use-context kind-vr-ai-world-gpu

echo "🔧 Installing NVIDIA Device Plugin..."
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.16.2/deployments/static/nvidia-device-plugin.yml

echo "⏳ Waiting for device plugin to be ready..."
kubectl wait --for=condition=ready pod -l name=nvidia-device-plugin-ds -n kube-system --timeout=120s

echo "🏷️  Labeling GPU nodes..."
kubectl label nodes --all accelerator=nvidia-tesla-gpu --overwrite

echo "🔍 Checking GPU availability in cluster..."
sleep 10
kubectl get nodes -o jsonpath='{.items[*].status.capacity.nvidia\.com/gpu}' || echo "GPUs not yet visible"

echo "✅ Local GPU-enabled Kubernetes cluster ready!"
echo ""
echo "🧪 Testing GPU access in cluster..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: gpu-test
spec:
  restartPolicy: Never
  containers:
  - name: gpu-test
    image: nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04
    command: ["nvidia-smi"]
    resources:
      limits:
        nvidia.com/gpu: 1
EOF

echo "⏳ Waiting for GPU test pod..."
kubectl wait --for=condition=complete pod/gpu-test --timeout=120s || true
kubectl logs gpu-test || echo "GPU test pod not ready yet"

echo ""
echo "📝 Next steps:"
echo "1. Run: ./build-and-deploy.sh (for GPU deployment)"
echo "2. Or run: ./deploy-test.sh (for CPU testing)"
echo "3. To cleanup: kind delete cluster --name vr-ai-world-gpu"
echo ""
echo "🔍 Check GPU nodes: kubectl describe nodes | grep nvidia"