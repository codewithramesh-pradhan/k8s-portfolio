#!/usr/bin/env bash
set -e

REPO_USER="codewithramesh-pradhan"   # Change this to your GitHub username if different
REPO_URL="https://github.com/${REPO_USER}/k8s-portfolio.git"

echo "=========================================="
echo "==> 1. Initializing Helm Repositories..."
echo "=========================================="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "=========================================="
echo "==> 2. Installing kube-prometheus-stack..."
echo "=========================================="
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword="admin" \
  --set grafana.service.type=ClusterIP

echo "=========================================="
echo "==> 3. Installing ArgoCD..."
echo "=========================================="
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set server.service.type=ClusterIP

echo "=========================================="
echo "==> 4. Waiting for ArgoCD Server Pod..."
echo "=========================================="
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=180s

echo "=========================================="
echo "==> 5. Applying GitOps Root Application..."
echo "=========================================="
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: portfolio-application
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: '${REPO_URL}'
    targetRevision: HEAD
    path: apps/portfolio
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: portfolio
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

echo "=========================================="
echo "==> 6. Setting Up Background Port-Forwards"
echo "=========================================="
# Static website
kubectl port-forward --address 0.0.0.0 svc/static-website-svc -n portfolio 8080:80 > /dev/null 2>&1 &
# ArgoCD UI
kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8081:80 > /dev/null 2>&1 &
# Grafana UI
kubectl port-forward --address 0.0.0.0 svc/monitoring-grafana -n monitoring 8082:80 > /dev/null 2>&1 &

echo "=========================================="
echo "==> Cluster Setup Complete!"
echo "=========================================="
echo "Access ports in iximiuz via 'Expose Port' buttons:"
echo " - Static Website : Port 8080"
echo " - ArgoCD Web UI  : Port 8081 (User: admin / Initial Secret: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
echo " - Grafana Web UI : Port 8082 (User: admin / Password: admin)"