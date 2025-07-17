#!/bin/bash

# Test deployment script for VR AI World
set -e

echo "🔧 Setting up local test environment..."

# Setup Kind cluster
./setup-local-k8s.sh

echo "🔨 Building test Docker images..."

# Build test inference service image (CPU-only)
echo "Building test inference service..."
docker build -f services/inference/Dockerfile.test -t vr-ai-world/inference:test services/inference/

# Build frontend service image  
echo "Building frontend service..."
docker build -t vr-ai-world/frontend:latest services/frontend/

echo "📦 Loading images into Kind cluster..."
kind load docker-image vr-ai-world/inference:test --name vr-ai-world
kind load docker-image vr-ai-world/frontend:latest --name vr-ai-world

echo "🚀 Deploying to Kubernetes..."

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Apply ConfigMap
kubectl apply -f k8s/configmap.yaml

# Deploy inference service
kubectl apply -f k8s/inference-deployment.yaml

# Deploy frontend service
kubectl apply -f k8s/frontend-deployment.yaml

echo "✅ Deployment complete!"

echo "📊 Checking deployment status..."
kubectl get pods -n vr-ai-world
kubectl get services -n vr-ai-world

echo "🔍 Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend-service -n vr-ai-world --timeout=120s
kubectl wait --for=condition=ready pod -l app=inference-service -n vr-ai-world --timeout=120s

echo "✅ All pods are ready!"

echo "🌐 Setting up port forwarding..."
kubectl port-forward service/frontend-service 3000:80 -n vr-ai-world &
PORT_FORWARD_PID=$!

echo "🎉 Application is ready!"
echo "Open http://localhost:3000 in your browser"
echo ""
echo "To stop the application:"
echo "kill $PORT_FORWARD_PID"
echo "kind delete cluster --name vr-ai-world"

# Keep script running
wait