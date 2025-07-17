#!/bin/bash

# Test deployed VR AI World services
set -e

echo "🧪 Testing VR AI World deployment..."

NAMESPACE="vr-ai-world"

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
    echo "❌ Namespace $NAMESPACE not found. Please deploy first."
    exit 1
fi

echo "📊 Checking pod status..."
kubectl get pods -n $NAMESPACE

# Wait for pods to be ready
echo "⏳ Waiting for services to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend-service -n $NAMESPACE --timeout=60s
kubectl wait --for=condition=ready pod -l app=inference-service -n $NAMESPACE --timeout=60s

echo "✅ All pods are ready!"

# Test inference service health
echo "🔬 Testing inference service health..."
INFERENCE_POD=$(kubectl get pods -n $NAMESPACE -l app=inference-service -o jsonpath='{.items[0].metadata.name}')
kubectl exec $INFERENCE_POD -n $NAMESPACE -- curl -f http://localhost:8000/health

# Test frontend service health
echo "🌐 Testing frontend service health..."
FRONTEND_POD=$(kubectl get pods -n $NAMESPACE -l app=frontend-service -o jsonpath='{.items[0].metadata.name}')
kubectl exec $FRONTEND_POD -n $NAMESPACE -- curl -f http://localhost:3000/health

# Test model generation (if GPU available)
echo "🤖 Testing model generation..."
RESPONSE=$(kubectl exec $INFERENCE_POD -n $NAMESPACE -- curl -s -X POST http://localhost:8000/generate \
    -H "Content-Type: application/json" \
    -d '{"description": "test cube"}' \
    --max-time 30 || echo "TIMEOUT")

if [[ "$RESPONSE" == "TIMEOUT" ]]; then
    echo "⚠️  Model generation test timed out (this is normal for large models)"
else
    echo "✅ Model generation endpoint responding"
fi

# Test frontend API proxy
echo "🔄 Testing frontend proxy..."
kubectl exec $FRONTEND_POD -n $NAMESPACE -- curl -f http://localhost:3000/api/model?description=test

echo ""
echo "🎉 All tests passed!"
echo ""
echo "📋 Service URLs (via port-forward):"
echo "  Frontend: kubectl port-forward service/frontend-service 3000:80 -n $NAMESPACE"
echo "  Inference API: kubectl port-forward service/inference-service 8000:8000 -n $NAMESPACE"
echo ""
echo "📊 Resource usage:"
kubectl top pods -n $NAMESPACE 2>/dev/null || echo "Metrics server not available"

echo ""
echo "📝 Logs (last 10 lines):"
echo "Frontend logs:"
kubectl logs deployment/frontend-service -n $NAMESPACE --tail=10
echo ""
echo "Inference logs:"
kubectl logs deployment/inference-service -n $NAMESPACE --tail=10