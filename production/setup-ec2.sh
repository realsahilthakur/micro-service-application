#!/bin/bash

# Production EC2 Setup Script for Todo List Microservices
# Run this script on your EC2 instance as ubuntu user

set -e

echo "🚀 Setting up Todo List Microservices on EC2..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "📦 Installing required packages..."
sudo apt install -y curl wget git htop

# Install K3s
echo "☸️ Installing K3s (Lightweight Kubernetes)..."
curl -sfL https://get.k3s.io | sh -

# Configure kubectl for ubuntu user
echo "🔧 Configuring kubectl..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown ubuntu:ubuntu ~/.kube/config
export KUBECONFIG=~/.kube/config

# Add to bashrc for persistence
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc

# Wait for K3s to be ready
echo "⏳ Waiting for K3s to be ready..."
sleep 30

# Verify K3s installation
echo "✅ Verifying K3s installation..."
kubectl get nodes

# Install ArgoCD
echo "🔄 Installing ArgoCD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD pods to be ready
echo "⏳ Waiting for ArgoCD to be ready (this may take a few minutes)..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=600s

# Expose ArgoCD server as LoadBalancer
echo "🌐 Exposing ArgoCD server..."
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"LoadBalancer"}}'

# Get ArgoCD admin password
echo "🔑 Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Deploy applications
echo "🚀 Deploying Todo List applications..."
kubectl apply -f https://raw.githubusercontent.com/realsahilthakur/micro-service-application/master/production/argocd-apps/database-app.yaml
kubectl apply -f https://raw.githubusercontent.com/realsahilthakur/micro-service-application/master/production/argocd-apps/backend-app.yaml
kubectl apply -f https://raw.githubusercontent.com/realsahilthakur/micro-service-application/master/production/argocd-apps/frontend-app.yaml

# Wait for applications to sync
echo "⏳ Waiting for applications to sync..."
sleep 60

# Get service information
echo "📋 Getting service information..."
FRONTEND_IP=$(kubectl get svc frontend-service -n frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")
ARGOCD_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")

echo ""
echo "🎉 Setup Complete!"
echo "=================================="
echo "📱 Todo List App: http://${FRONTEND_IP:-[Pending]}"
echo "🔄 ArgoCD UI: http://${ARGOCD_IP:-[Pending]}:8080"
echo "👤 ArgoCD Username: admin"
echo "🔑 ArgoCD Password: $ARGOCD_PASSWORD"
echo ""
echo "📝 Note: LoadBalancer IPs may take a few minutes to be assigned."
echo "📝 Check status with: kubectl get svc --all-namespaces"
echo ""
echo "🔍 Monitor applications:"
echo "  kubectl get applications -n argocd"
echo "  kubectl get pods --all-namespaces"
echo ""
echo "✅ Your Todo List microservices are now running in production!"