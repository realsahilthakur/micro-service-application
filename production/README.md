# Production Deployment Guide

## 🚀 EC2 Production Setup

### Prerequisites
- AWS Account with EC2 access
- Domain name (optional, for SSL)
- SSH key pair for EC2 access

### EC2 Instance Requirements
- **Instance Type**: t3.medium or larger (2 vCPU, 4GB RAM minimum)
- **OS**: Ubuntu 22.04 LTS
- **Storage**: 20GB+ SSD
- **Security Groups**: 
  - SSH (22) - Your IP only
  - HTTP (80) - 0.0.0.0/0
  - HTTPS (443) - 0.0.0.0/0
  - Kubernetes API (6443) - Your IP only
  - ArgoCD (8080) - Your IP only

### Installation Steps

#### 1. Launch EC2 Instance
```bash
# Connect to your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip
```

#### 2. Install K3s (Lightweight Kubernetes)
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install K3s
curl -sfL https://get.k3s.io | sh -

# Configure kubectl for ubuntu user
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown ubuntu:ubuntu ~/.kube/config
export KUBECONFIG=~/.kube/config

# Verify installation
kubectl get nodes
```

#### 3. Install ArgoCD
```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Expose ArgoCD server
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"LoadBalancer"}}'
```

#### 4. Get ArgoCD Admin Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

#### 5. Deploy Applications
```bash
# Apply ArgoCD applications
kubectl apply -f https://raw.githubusercontent.com/realsahilthakur/micro-service-application/master/production/argocd-apps/
```

### Access Points
- **Todo App**: http://your-ec2-ip
- **ArgoCD UI**: http://your-ec2-ip:8080

### Security Considerations
- Use HTTPS in production
- Restrict security group access
- Use IAM roles instead of access keys
- Enable CloudWatch monitoring
- Set up automated backups