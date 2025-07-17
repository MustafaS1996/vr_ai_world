#!/bin/bash

# Deploy VR AI World to Kubernetes cluster with GPU support
set -e

echo "🔍 Checking Kubernetes cluster and GPU availability..."

# Check if kubectl is working
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ Error: kubectl cannot connect to cluster. Please configure your cluster connection."
    echo "For cloud providers:"
    echo "  - GKE: gcloud container clusters get-credentials CLUSTER_NAME --zone=ZONE"
    echo "  - EKS: aws eks update-kubeconfig --region REGION --name CLUSTER_NAME"
    echo "  - AKS: az aks get-credentials --resource-group RG --name CLUSTER_NAME"
    exit 1
fi

# Check for GPU nodes
echo "Checking for GPU-enabled nodes..."
GPU_NODES=$(kubectl get nodes -o jsonpath='{.items[*].status.capacity.nvidia\.com/gpu}' | grep -v '^$' | wc -w)

if [ "$GPU_NODES" -eq 0 ]; then
    echo "⚠️  Warning: No GPU nodes found in cluster!"
    echo "GPU nodes are required for the inference service."
    echo "Consider using deploy-test.sh for CPU-only testing."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ Found $GPU_NODES GPU-enabled nodes"
fi

echo "🔨 Building Docker images..."

# Build inference service image
echo "Building inference service..."
docker build -t vr-ai-world/inference:latest services/inference/

# Build frontend service image  
echo "Building frontend service..."
docker build -t vr-ai-world/frontend:latest services/frontend/

echo "📦 Pushing images to cluster..."
# Note: For cloud deployments, you'd push to a registry like:
# docker tag vr-ai-world/inference:latest gcr.io/PROJECT/inference:latest
# docker push gcr.io/PROJECT/inference:latest

echo "🚀 Deploying to Kubernetes..."

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Apply ConfigMap
kubectl apply -f k8s/configmap.yaml

# Deploy inference service (with GPU)
kubectl apply -f k8s/inference-deployment.yaml

# Deploy frontend service
kubectl apply -f k8s/frontend-deployment.yaml

echo "✅ Deployment complete!"

echo "📊 Checking deployment status..."
kubectl get pods -n vr-ai-world -o wide
kubectl get services -n vr-ai-world

echo "🔍 Waiting for pods to be ready..."
echo "This may take several minutes for the inference service to download models..."

kubectl wait --for=condition=ready pod -l app=frontend-service -n vr-ai-world --timeout=300s
kubectl wait --for=condition=ready pod -l app=inference-service -n vr-ai-world --timeout=600s

echo "✅ All pods are ready!"

# Check if LoadBalancer service got external IP
EXTERNAL_IP=$(kubectl get service frontend-service -n vr-ai-world -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -z "$EXTERNAL_IP" ]; then
    echo "🌐 Setting up port forwarding (LoadBalancer external IP not available)..."
    kubectl port-forward service/frontend-service 3000:80 -n vr-ai-world &
    PORT_FORWARD_PID=$!
    echo "🎉 Application available at: http://localhost:3000"
    echo "To stop port forwarding: kill $PORT_FORWARD_PID"
else
    echo "🎉 Application available at: http://$EXTERNAL_IP"
fi

echo ""
echo "📋 Useful commands:"
echo "  View logs: kubectl logs -f deployment/inference-service -n vr-ai-world"
echo "  Scale frontend: kubectl scale deployment frontend-service --replicas=3 -n vr-ai-world"
echo "  Delete deployment: kubectl delete namespace vr-ai-world"