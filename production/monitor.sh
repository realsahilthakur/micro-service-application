#!/bin/bash

# Production Monitoring Script
# Check the status of all services

echo "🔍 Todo List Microservices - Production Status"
echo "=============================================="

# Check K3s status
echo "☸️ Kubernetes Cluster Status:"
kubectl get nodes
echo ""

# Check ArgoCD applications
echo "🔄 ArgoCD Applications:"
kubectl get applications -n argocd
echo ""

# Check all pods
echo "📦 All Pods Status:"
kubectl get pods --all-namespaces
echo ""

# Check services and external IPs
echo "🌐 Services and External Access:"
kubectl get svc --all-namespaces
echo ""

# Check specific service endpoints
echo "📱 Application Endpoints:"
FRONTEND_IP=$(kubectl get svc frontend-service -n frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
ARGOCD_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")

echo "  Todo List App: http://${FRONTEND_IP}"
echo "  ArgoCD UI: http://${ARGOCD_IP}:8080"
echo ""

# Check resource usage
echo "💾 Resource Usage:"
kubectl top nodes 2>/dev/null || echo "Metrics server not available"
echo ""

# Check recent events
echo "📋 Recent Events:"
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -10
echo ""

echo "✅ Monitoring complete!"
echo "💡 Tip: Run 'watch -n 5 ./monitor.sh' for continuous monitoring"