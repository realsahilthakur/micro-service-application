# Production Troubleshooting Guide

## 🔧 Common Issues and Solutions

### 1. Pods Not Starting

**Check pod status:**
```bash
kubectl get pods --all-namespaces
kubectl describe pod <pod-name> -n <namespace>
```

**Common causes:**
- Image pull errors
- Resource constraints
- Configuration issues

### 2. Services Not Accessible

**Check services:**
```bash
kubectl get svc --all-namespaces
kubectl describe svc <service-name> -n <namespace>
```

**For LoadBalancer issues:**
```bash
# Check if LoadBalancer is supported
kubectl get svc frontend-service -n frontend -w
```

### 3. ArgoCD Applications Not Syncing

**Check application status:**
```bash
kubectl get applications -n argocd
kubectl describe application <app-name> -n argocd
```

**Manual sync:**
```bash
kubectl patch application <app-name> -n argocd --type merge -p '{"operation":{"sync":{}}}'
```

### 4. Database Connection Issues

**Check backend logs:**
```bash
kubectl logs -n backend deployment/backend
```

**Check database connectivity:**
```bash
kubectl exec -n backend deployment/backend -- ping postgres-service.database.svc.cluster.local
```

### 5. Frontend Not Loading CSS/JS

**Check nginx logs:**
```bash
kubectl logs -n frontend deployment/frontend
```

**Verify files in container:**
```bash
kubectl exec -n frontend deployment/frontend -- ls -la /usr/share/nginx/html/
```

## 🚨 Emergency Commands

### Restart All Services
```bash
kubectl rollout restart deployment/frontend -n frontend
kubectl rollout restart deployment/backend -n backend
kubectl rollout restart deployment/postgres -n database
```

### Check Resource Usage
```bash
kubectl top nodes
kubectl top pods --all-namespaces
```

### View All Events
```bash
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

### Backup Database (if needed)
```bash
kubectl exec -n database deployment/postgres -- pg_dump -U user mydb > backup.sql
```

## 📞 Health Checks

### Quick Health Check Script
```bash
#!/bin/bash
echo "Health Check Results:"
echo "Frontend: $(curl -s -o /dev/null -w "%{http_code}" http://$(kubectl get svc frontend-service -n frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}'))"
echo "Backend API: $(curl -s -o /dev/null -w "%{http_code}" http://$(kubectl get svc frontend-service -n frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/api/todos)"
```

## 🔄 Rollback Procedures

### Rollback Application
```bash
# Check rollout history
kubectl rollout history deployment/<deployment-name> -n <namespace>

# Rollback to previous version
kubectl rollout undo deployment/<deployment-name> -n <namespace>
```

### Rollback ArgoCD Application
```bash
# In ArgoCD UI, go to application → History and Rollback
# Or use CLI:
argocd app rollback <app-name> <revision-id>
```