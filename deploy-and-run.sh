#!/bin/bash

# Deploy and run VR AI World with GPU support
set -e

echo "🚀 Deploying and running VR AI World..."

# Run the deployment
./deploy-gpu-test.sh

echo "🔄 Updating frontend with longer timeout..."
# Rebuild and redeploy frontend with longer timeout
docker build -t vr-ai-world/frontend:latest services/frontend/
kind load docker-image vr-ai-world/frontend:latest --name vr-ai-world-gpu
kubectl rollout restart deployment/frontend-service -n vr-ai-world

echo "⏳ Waiting for frontend to restart..."
kubectl rollout status deployment/frontend-service -n vr-ai-world --timeout=120s

echo "✅ All services are running!"
echo ""
echo "🌐 Setting up port forwarding..."
echo "Frontend will be available at: http://localhost:8080"
echo "Inference API will be available at: http://localhost:8000"
echo ""

# Kill any existing port forwards
pkill -f "port-forward" 2>/dev/null || true

# Start port forwarding in background
kubectl port-forward service/frontend-service 8080:80 -n vr-ai-world &
FRONTEND_PID=$!

kubectl port-forward service/inference-service 8000:8000 -n vr-ai-world &
INFERENCE_PID=$!

echo "🎉 VR AI World is ready!"
echo ""
echo "📱 Frontend: http://localhost:8080"
echo "🤖 Inference API: http://localhost:8000/docs"
echo ""
echo "📊 Monitor with:"
echo "  kubectl get pods -n vr-ai-world"
echo "  kubectl logs -f deployment/inference-service -n vr-ai-world"
echo "  kubectl logs -f deployment/frontend-service -n vr-ai-world"
echo ""
echo "🛑 To stop everything:"
echo "  kill $FRONTEND_PID $INFERENCE_PID"
echo "  kubectl delete namespace vr-ai-world"
echo "  kind delete cluster --name vr-ai-world-gpu"
echo ""
echo "Press Ctrl+C to stop port forwarding (services will keep running)"

# Wait for user to stop
trap "echo 'Stopping port forwarding...'; kill $FRONTEND_PID $INFERENCE_PID 2>/dev/null || true; exit 0" SIGINT

# Keep script running
while true; do
    sleep 10
    # Check if port forwards are still alive
    if ! kill -0 $FRONTEND_PID 2>/dev/null || ! kill -0 $INFERENCE_PID 2>/dev/null; then
        echo "Port forwarding stopped. Restarting..."
        pkill -f "port-forward" 2>/dev/null || true
        kubectl port-forward service/frontend-service 8080:80 -n vr-ai-world &
        FRONTEND_PID=$!
        kubectl port-forward service/inference-service 8000:8000 -n vr-ai-world &
        INFERENCE_PID=$!
    fi
done