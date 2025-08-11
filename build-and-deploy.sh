#!/bin/bash

# Build and Deploy VR AI World to Google Cloud (GKE)
set -e

PROJECT_ID="vraiworld"
CLUSTER_NAME="vr-ai-world"
REGION="us-central1-a"
NAMESPACE="vr-ai-world"

echo "🚀 Building and deploying VR AI World to Google Cloud"
echo "Project: $PROJECT_ID"
echo "Cluster: $CLUSTER_NAME"

# Set the project
gcloud config set project $PROJECT_ID

# Get cluster credentials
echo "🔐 Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$REGION

# Build and push images using Cloud Build
echo "🏗️  Building and pushing Docker images..."
gcloud builds submit --config cloudbuild.yaml .

# Apply Kubernetes manifests
echo "📦 Deploying to Kubernetes..."
kubectl apply -f k8s/

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl rollout status deployment/frontend-service -n $NAMESPACE --timeout=300s
kubectl rollout status deployment/inference-service -n $NAMESPACE --timeout=600s

# Get service URL
echo "🌐 Getting service information..."
kubectl get services -n $NAMESPACE

# Get external IP (if LoadBalancer)
echo "🔍 Checking for external IP..."
EXTERNAL_IP=$(kubectl get service frontend-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")

if [ "$EXTERNAL_IP" != "pending" ] && [ "$EXTERNAL_IP" != "" ]; then
    echo "✅ VR AI World deployed successfully!"
    echo "🌐 Access your app at: http://$EXTERNAL_IP"
else
    echo "✅ VR AI World deployed successfully!"
    echo "⏳ External IP is still being assigned. Check with:"
    echo "   kubectl get service frontend-service -n $NAMESPACE"
fi

echo ""
echo "📊 Monitor with:"
echo "  kubectl get pods -n $NAMESPACE"
echo "  kubectl logs -f deployment/inference-service -n $NAMESPACE"
echo "  kubectl logs -f deployment/frontend-service -n $NAMESPACE"