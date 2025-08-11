#!/bin/bash

# Quick deployment script (assumes cluster already exists)
set -e

PROJECT_ID="vraiworld"
CLUSTER_NAME="vr-ai-world"
REGION="us-central1-a"
NAMESPACE="vr-ai-world"

echo "⚡ Quick deploy to existing GKE cluster"

# Set project and get credentials
gcloud config set project $PROJECT_ID
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$REGION

# Build and deploy
gcloud builds submit --config cloudbuild.yaml .
kubectl apply -f k8s/

# Check status
kubectl get pods -n $NAMESPACE
kubectl get services -n $NAMESPACE

echo "✅ Quick deployment complete!"