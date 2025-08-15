# Complete Deployment Guide

## Overview

This project demonstrates a microservices application with multiple deployment strategies:

- Local Docker deployment
- Kubernetes orchestration
- GitOps with ArgoCD

## Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Frontend  │───▶│   Backend   │───▶│  Database   │
│   (Nginx)   │    │   (Flask)   │    │(PostgreSQL) │
│   Port 80   │    │  Port 5000  │    │  Port 5432  │
└─────────────┘    └─────────────┘    └─────────────┘
```

## 1. Containerization

### Dockerfiles Created:

- `src/FRONTEND/Dockerfile` - Nginx-based frontend
- `src/BACKEND/Dockerfile` - Python Flask backend

### Images Built:

```bash
# Frontend
docker build -t realsahilthakur/frontend-app:latest src/FRONTEND/
docker push realsahilthakur/frontend-app:latest

# Backend
docker build -t realsahilthakur/backend-app:latest src/BACKEND/
docker push realsahilthakur/backend-app:latest
```

## 2. Local Docker Deployment

### Using Docker Compose:

```bash
# Start all services
docker-compose up --build

# Access points:
# Frontend: http://localhost:3000
# Backend: http://localhost:5000
# Database: localhost:5432
```

### Docker Compose Configuration:

- File: `docker-compose.yml`
- Services: frontend, backend, database
- Network: Internal communication
- Volumes: Database persistence


## 3. Kubernetes Orchestration

### Helm Charts Structure:

```
helm-charts/
├── frontend-chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── backend-proxy.yaml
├── backend-chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       └── service.yaml
└── database-chart/
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── deployment.yaml
        └── service.yaml
```

### Manual Deployment:

```bash
# Create namespaces
kubectl create namespace frontend
kubectl create namespace backend
kubectl create namespace database

# Deploy services
helm install database-app helm-charts/database-chart -n database
helm install backend-app helm-charts/backend-chart -n backend
helm install frontend-app helm-charts/frontend-chart -n frontend

# Check deployments
kubectl get pods --all-namespaces
```

## 4. GitOps with ArgoCD

### ArgoCD Installation:

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Expose ArgoCD server
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'
```

### ArgoCD Applications:

```bash
# Deploy applications
kubectl apply -f argocd-apps/database-app.yaml
kubectl apply -f argocd-apps/backend-app.yaml
kubectl apply -f argocd-apps/frontend-app.yaml

# Check applications
kubectl get applications -n argocd
```

### GitOps Workflow:

1. Developer pushes code to GitHub
2. ArgoCD detects changes automatically
3. ArgoCD syncs Helm charts
4. Applications deploy to Kubernetes
5. Services update automatically

## 5. Access Points

### Local Docker:

- Frontend: http://localhost:3000
- Backend: http://localhost:5000

### Docker Swarm:

- Frontend: http://localhost:8080
- Backend: http://localhost:5000

### Kubernetes:

- Frontend: http://localhost:[NodePort] (check with `kubectl get svc -n frontend`)
- ArgoCD UI: https://localhost:[NodePort] (check with `kubectl get svc -n argocd`)

## 6. Verification Commands

### Docker:

```bash
docker ps                    # Check running containers
docker-compose logs         # Check logs
```

### Docker Swarm:

```bash
docker service ls           # List services
docker service logs [service] # Check service logs
docker stack ps microservices-stack # Check stack status
```

### Kubernetes:

```bash
kubectl get pods --all-namespaces    # All pods
kubectl get applications -n argocd   # ArgoCD apps
kubectl logs -n [namespace] [pod]    # Pod logs
```

## 7. Troubleshooting

### Common Issues:

1. **Port conflicts**: Change ports in compose/stack files
2. **Image not found**: Ensure images are pushed to registry
3. **Database connection**: Check environment variables
4. **ArgoCD sync issues**: Verify GitHub repository access

### Health Checks:

```bash
# Test backend API
curl http://localhost:5000

# Test frontend
curl http://localhost:3000

# Test database connection (from backend pod)
kubectl exec -n backend [pod-name] -- curl localhost:5000
```
