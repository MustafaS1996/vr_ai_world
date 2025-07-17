#!/bin/bash

# Monitor VR AI World deployment progress
set -e

NAMESPACE="vr-ai-world"

echo "🔍 Monitoring VR AI World deployment..."

while true; do
    clear
    echo "🕐 $(date)"
    echo "=================================="
    
    echo "📊 Pod Status:"
    kubectl get pods -n $NAMESPACE -o wide
    
    echo ""
    echo "📋 Service Status:"
    kubectl get services -n $NAMESPACE
    
    echo ""
    echo "📝 Recent Events:"
    kubectl get events -n $NAMESPACE --sort-by=.metadata.creationTimestamp | tail -5
    
    echo ""
    echo "🔍 Inference Pod Logs (last 5 lines):"
    INFERENCE_POD=$(kubectl get pods -n $NAMESPACE -l app=inference-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$INFERENCE_POD" ]; then
        kubectl logs $INFERENCE_POD -n $NAMESPACE --tail=5 2>/dev/null || echo "Pod not ready yet"
        
        echo ""
        echo "🧪 Pod Description (if failing):"
        POD_STATUS=$(kubectl get pod $INFERENCE_POD -n $NAMESPACE -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
        if [ "$POD_STATUS" != "Running" ]; then
            kubectl describe pod $INFERENCE_POD -n $NAMESPACE | tail -10
        fi
    else
        echo "No inference pods found"
    fi
    
    echo ""
    echo "Press Ctrl+C to stop monitoring"
    sleep 10
done