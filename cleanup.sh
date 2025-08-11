#!/bin/bash

# Cleanup Google Cloud resources
set -e

PROJECT_ID="vraiworld"
CLUSTER_NAME="vr-ai-world"
REGION="us-central1-a"

echo "🧹 Cleaning up Google Cloud resources"
echo "Project: $PROJECT_ID"
echo "Cluster: $CLUSTER_NAME"

read -p "Are you sure you want to delete the cluster and all resources? (y/N): " confirm

if [[ $confirm != [yY] ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Delete GKE cluster
echo "🗑️  Deleting GKE cluster..."
gcloud container clusters delete $CLUSTER_NAME --zone=$REGION --quiet

# Delete container images
echo "🗑️  Deleting container images..."
gcloud container images delete gcr.io/$PROJECT_ID/frontend:latest --quiet --force-delete-tags || true
gcloud container images delete gcr.io/$PROJECT_ID/inference:latest --quiet --force-delete-tags || true

echo "✅ Cleanup complete!"
echo "💰 This should significantly reduce your cloud costs."