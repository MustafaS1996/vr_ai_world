# Setting up Kubernetes Cluster with GPU Support

This guide shows how to set up a Kubernetes cluster with GPU nodes for deploying VR AI World.

## Cloud Provider Setup

### Google Kubernetes Engine (GKE)

```bash
# Create cluster with GPU nodes
gcloud container clusters create vr-ai-world \
    --zone=us-central1-a \
    --machine-type=n1-standard-4 \
    --num-nodes=1 \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=3

# Add GPU node pool
gcloud container node-pools create gpu-pool \
    --cluster=vr-ai-world \
    --zone=us-central1-a \
    --machine-type=n1-standard-4 \
    --accelerator=type=nvidia-tesla-t4,count=1 \
    --num-nodes=1 \
    --enable-autoscaling \
    --min-nodes=0 \
    --max-nodes=2

# Get credentials
gcloud container clusters get-credentials vr-ai-world --zone=us-central1-a

# Install NVIDIA device plugin
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded.yaml
```

### Amazon EKS

```bash
# Create cluster
eksctl create cluster \
    --name vr-ai-world \
    --version 1.24 \
    --region us-west-2 \
    --nodegroup-name standard-workers \
    --node-type m5.large \
    --nodes 1 \
    --nodes-min 1 \
    --nodes-max 3

# Add GPU node group
eksctl create nodegroup \
    --cluster vr-ai-world \
    --region us-west-2 \
    --name gpu-workers \
    --node-type g4dn.xlarge \
    --nodes 1 \
    --nodes-min 0 \
    --nodes-max 2

# Get credentials
aws eks update-kubeconfig --region us-west-2 --name vr-ai-world

# Install NVIDIA device plugin
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.13.0/nvidia-device-plugin.yml
```

### Azure Kubernetes Service (AKS)

```bash
# Create resource group
az group create --name vr-ai-world --location eastus

# Create cluster with GPU nodes
az aks create \
    --resource-group vr-ai-world \
    --name vr-ai-world \
    --node-count 1 \
    --enable-addons monitoring \
    --generate-ssh-keys

# Add GPU node pool
az aks nodepool add \
    --resource-group vr-ai-world \
    --cluster-name vr-ai-world \
    --name gpunodepool \
    --node-count 1 \
    --node-vm-size Standard_NC6s_v3 \
    --enable-cluster-autoscaler \
    --min-count 0 \
    --max-count 2

# Get credentials
az aks get-credentials --resource-group vr-ai-world --name vr-ai-world

# Install NVIDIA device plugin
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.13.0/nvidia-device-plugin.yml
```

## Local Setup with Kind (for testing)

```bash
# Run the setup script
./setup-local-k8s.sh

# Use test deployment
./deploy-test.sh
```

## Verify GPU Setup

```bash
# Check for GPU nodes
kubectl get nodes -o jsonpath='{.items[*].status.capacity.nvidia\.com/gpu}'

# Check NVIDIA device plugin
kubectl get pods -n kube-system | grep nvidia

# Label GPU nodes (if needed)
kubectl label nodes NODE_NAME accelerator=nvidia-tesla-gpu
```

## Deploy Application

For GPU deployment:
```bash
./deploy-gpu.sh
```

For testing (CPU-only):
```bash
./deploy-test.sh
```

## Monitoring and Troubleshooting

```bash
# Check pod status
kubectl get pods -n vr-ai-world -o wide

# View logs
kubectl logs -f deployment/inference-service -n vr-ai-world

# Describe problematic pods
kubectl describe pod POD_NAME -n vr-ai-world

# Check resource usage
kubectl top pods -n vr-ai-world
kubectl top nodes
```

## Cost Optimization

- Use node autoscaling to scale GPU nodes to zero when not in use
- Use preemptible/spot instances for development
- Set resource requests/limits appropriately
- Consider using smaller GPU instances for development (T4 vs V100)