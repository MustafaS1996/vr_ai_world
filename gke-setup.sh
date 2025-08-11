#!/bin/bash

# GKE Cluster Setup Script for VR AI World
# Project: vraiworld
set -e

PROJECT_ID="vraiworld"
CLUSTER_NAME="vr-ai-world"
REGION="us-central1-a"
NAMESPACE="vr-ai-world"

echo "🚀 Setting up GKE cluster for VR AI World"
echo "Project: $PROJECT_ID"
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"

# Set the project
echo "📋 Setting project..."
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "🔧 Enabling required APIs..."
gcloud services enable \
    container.googleapis.com \
    cloudbuild.googleapis.com \
    containerregistry.googleapis.com

# Create GKE cluster with CPU nodes
echo "🏗️  Creating GKE cluster..."
gcloud container clusters create $CLUSTER_NAME \
    --zone=$REGION \
    --machine-type=n1-standard-2 \
    --num-nodes=1 \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=3 \
    --enable-autorepair \
    --enable-autoupgrade \
    --disk-size=50GB \
    --disk-type=pd-ssd \
    --enable-ip-alias

# Add GPU node pool for inference service
echo "🖥️  Adding GPU node pool..."
gcloud container node-pools create gpu-pool \
    --cluster=$CLUSTER_NAME \
    --zone=$REGION \
    --machine-type=n1-standard-4 \
    --accelerator=type=nvidia-tesla-t4,count=1 \
    --num-nodes=1 \
    --enable-autoscaling \
    --min-nodes=0 \
    --max-nodes=2 \
    --disk-size=100GB \
    --disk-type=pd-ssd \
    --enable-autorepair \
    --enable-autoupgrade

# Get cluster credentials
echo "🔐 Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$REGION

# Install NVIDIA device plugin for GPU support
echo "🚀 Installing NVIDIA GPU device plugin..."
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded.yaml

# Create namespace
echo "📦 Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Label GPU nodes
echo "🏷️  Labeling GPU nodes..."
kubectl label nodes -l cloud.google.com/gke-accelerator=nvidia-tesla-t4 accelerator=nvidia-tesla-gpu --overwrite

echo "✅ GKE cluster setup complete!"
echo ""
echo "🎯 Next steps:"
echo "1. Run ./build-and-deploy.sh to deploy your application"
echo "2. Monitor deployment: kubectl get pods -n $NAMESPACE -w"
echo "3. Get service URL: kubectl get service frontend-service -n $NAMESPACE"
echo ""
echo "📊 Useful commands:"
echo "• Cluster info: kubectl cluster-info"
echo "• Node status: kubectl get nodes"
echo "• GPU status: kubectl get nodes -o yaml | grep -A5 nvidia"