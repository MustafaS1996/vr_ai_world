#!/bin/bash

# Deploy VR AI World with GPU support in local Kind cluster
set -e

echo "🔧 Deploying VR AI World with GPU support to local cluster..."

KIND_CMD="kind"

# Check if cluster exists
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "No cluster found. Setting up local cluster..."
    ./setup-simple-gpu-k8s.sh
fi

echo "🔨 Building Docker images with GPU support..."

# Build inference service image (GPU-enabled)
echo "Building GPU inference service..."
docker build -t vr-ai-world/inference:latest services/inference/

# Build frontend service image  
echo "Building frontend service..."
docker build -t vr-ai-world/frontend:latest services/frontend/

echo "📦 Loading images into Kind cluster..."
echo "Loading inference image (this may take a few minutes for large GPU image)..."
$KIND_CMD load docker-image vr-ai-world/inference:latest --name vr-ai-world-gpu
echo "Loading frontend image..."
$KIND_CMD load docker-image vr-ai-world/frontend:latest --name vr-ai-world-gpu

# Create GPU-enabled deployment with host GPU access
echo "📝 Creating GPU deployment configuration..."
cat <<EOF > k8s/inference-deployment-gpu-test.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inference-service
  namespace: vr-ai-world
  labels:
    app: inference-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: inference-service
  template:
    metadata:
      labels:
        app: inference-service
    spec:
      containers:
      - name: inference
        image: vr-ai-world/inference:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 8000
        resources:
          requests:
            memory: "4Gi"
            cpu: "1000m"
          limits:
            memory: "8Gi"
            cpu: "2000m"
        env:
        - name: CUDA_VISIBLE_DEVICES
          value: "0"
        volumeMounts:
        - name: nvidia-dev
          mountPath: /dev/nvidia0
        - name: nvidia-ctl
          mountPath: /dev/nvidiactl
        - name: nvidia-uvm
          mountPath: /dev/nvidia-uvm
        - name: nvidia-uvm-tools
          mountPath: /dev/nvidia-uvm-tools
        - name: nvidia-modeset
          mountPath: /dev/nvidia-modeset
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 300
          periodSeconds: 60
          timeoutSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 300
          periodSeconds: 30
          timeoutSeconds: 10
        securityContext:
          privileged: true  # Required for GPU access
      volumes:
      - name: nvidia-dev
        hostPath:
          path: /dev/nvidia0
      - name: nvidia-ctl
        hostPath:
          path: /dev/nvidiactl
      - name: nvidia-uvm
        hostPath:
          path: /dev/nvidia-uvm
      - name: nvidia-uvm-tools
        hostPath:
          path: /dev/nvidia-uvm-tools
      - name: nvidia-modeset
        hostPath:
          path: /dev/nvidia-modeset
      nodeSelector:
        accelerator: nvidia-tesla-gpu
---
apiVersion: v1
kind: Service
metadata:
  name: inference-service
  namespace: vr-ai-world
  labels:
    app: inference-service
spec:
  selector:
    app: inference-service
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
  type: ClusterIP
EOF

echo "🚀 Deploying to Kubernetes..."

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Apply ConfigMap
kubectl apply -f k8s/configmap.yaml

# Deploy GPU inference service
kubectl apply -f k8s/inference-deployment-gpu-test.yaml

# Deploy frontend service
kubectl apply -f k8s/frontend-deployment.yaml

echo "✅ Deployment complete!"

echo "📊 Checking deployment status..."
kubectl get pods -n vr-ai-world -o wide
kubectl get services -n vr-ai-world

echo "🔍 Waiting for pods to be ready..."
echo "Frontend pods (should be quick)..."
kubectl wait --for=condition=ready pod -l app=frontend-service -n vr-ai-world --timeout=300s

echo "Inference pods (may take up to 20 minutes to download models on slower networks)..."
kubectl wait --for=condition=ready pod -l app=inference-service -n vr-ai-world --timeout=1200s

echo "✅ All pods are ready!"

echo "🧪 Testing GPU access in inference pod..."
INFERENCE_POD=$(kubectl get pods -n vr-ai-world -l app=inference-service -o jsonpath='{.items[0].metadata.name}')
echo "Running nvidia-smi in inference pod:"
kubectl exec $INFERENCE_POD -n vr-ai-world -- nvidia-smi || echo "GPU test failed"

echo "🌐 Setting up port forwarding..."
kubectl port-forward service/frontend-service 3000:80 -n vr-ai-world &
PORT_FORWARD_PID=$!

echo "🎉 GPU-enabled VR AI World is ready!"
echo "Open http://localhost:3000 in your browser"
echo ""
echo "📋 Useful commands:"
echo "  View inference logs: kubectl logs -f deployment/inference-service -n vr-ai-world"
echo "  Test GPU in pod: kubectl exec -it $INFERENCE_POD -n vr-ai-world -- nvidia-smi"
echo "  Stop port forwarding: kill $PORT_FORWARD_PID"
echo "  Delete deployment: kubectl delete namespace vr-ai-world"

# Clean up temporary file
rm -f k8s/inference-deployment-gpu-test.yaml