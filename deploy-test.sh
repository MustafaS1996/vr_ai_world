#!/bin/bash

# Deploy VR AI World to Kubernetes cluster for testing (CPU-only)
set -e

echo "🔍 Checking Kubernetes cluster..."

# Check if kubectl is working
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ Error: kubectl cannot connect to cluster."
    echo "Setting up local Kind cluster for testing..."
    ./setup-local-k8s.sh
fi

echo "🔨 Building Docker images for testing..."

# Build test inference service image (CPU-only)
echo "Building test inference service..."
docker build -f services/inference/Dockerfile.test -t vr-ai-world/inference:test services/inference/

# Build frontend service image  
echo "Building frontend service..."
docker build -t vr-ai-world/frontend:latest services/frontend/

# Create test deployment config
echo "📝 Creating test deployment configuration..."
cp k8s/inference-deployment.yaml k8s/inference-deployment-test.yaml

# Modify for test environment
sed -i 's/image: vr-ai-world\/inference:latest/image: vr-ai-world\/inference:test/g' k8s/inference-deployment-test.yaml
sed -i '/nvidia\.com\/gpu:/d' k8s/inference-deployment-test.yaml
sed -i '/CUDA_VISIBLE_DEVICES/,+1d' k8s/inference-deployment-test.yaml
sed -i 's/accelerator: nvidia-tesla-gpu/kubernetes.io\/arch: amd64/g' k8s/inference-deployment-test.yaml
sed -i '/tolerations:/,+3d' k8s/inference-deployment-test.yaml
sed -i 's/memory: "4Gi"/memory: "512Mi"/g' k8s/inference-deployment-test.yaml
sed -i 's/memory: "8Gi"/memory: "1Gi"/g' k8s/inference-deployment-test.yaml
sed -i 's/cpu: "1000m"/cpu: "250m"/g' k8s/inference-deployment-test.yaml
sed -i 's/cpu: "2000m"/cpu: "500m"/g' k8s/inference-deployment-test.yaml

# If using Kind, load images
if kubectl config current-context | grep -q "kind"; then
    echo "📦 Loading images into Kind cluster..."
    kind load docker-image vr-ai-world/inference:test
    kind load docker-image vr-ai-world/frontend:latest
fi

echo "🚀 Deploying to Kubernetes..."

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Apply ConfigMap
kubectl apply -f k8s/configmap.yaml

# Deploy test inference service
kubectl apply -f k8s/inference-deployment-test.yaml

# Deploy frontend service
kubectl apply -f k8s/frontend-deployment.yaml

echo "✅ Deployment complete!"

echo "📊 Checking deployment status..."
kubectl get pods -n vr-ai-world -o wide
kubectl get services -n vr-ai-world

echo "🔍 Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend-service -n vr-ai-world --timeout=300s
kubectl wait --for=condition=ready pod -l app=inference-service -n vr-ai-world --timeout=300s

echo "✅ All pods are ready!"

echo "🌐 Setting up port forwarding..."
kubectl port-forward service/frontend-service 3000:80 -n vr-ai-world &
PORT_FORWARD_PID=$!

echo "🎉 Test application is ready!"
echo "Open http://localhost:3000 in your browser"
echo "Note: This test version generates simple cube models instead of AI-generated ones"
echo ""
echo "📋 Useful commands:"
echo "  View logs: kubectl logs -f deployment/inference-service -n vr-ai-world"
echo "  Stop port forwarding: kill $PORT_FORWARD_PID"
echo "  Delete deployment: kubectl delete namespace vr-ai-world"

# Clean up test file
rm -f k8s/inference-deployment-test.yaml