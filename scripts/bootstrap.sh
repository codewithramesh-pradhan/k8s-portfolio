#!/usr/bin/env bash
set -euo pipefail

REPO_USER="codewithramesh-pradhan"
REPO_URL="https://github.com/${REPO_USER}/k8s-portfolio.git"

echo "==> 1. Installing Argo CD..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set server.service.type=ClusterIP \
  --wait

echo "==> 2. Applying Root GitOps Application..."
kubectl apply -f bootstrap/root-app.yaml

echo "==> 3. Setting Up Background Port-Forwards..."
sleep 10
# Portfolio
kubectl port-forward --address 0.0.0.0 svc/static-website-svc -n portfolio 8080:80 > /dev/null 2>&1 &
# ArgoCD
kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8081:80 > /dev/null 2>&1 &
# Grafana
kubectl port-forward --address 0.0.0.0 svc/monitoring-grafana -n monitoring 8082:80 > /dev/null 2>&1 &

echo "Setup complete! Argo CD is reconciling all infrastructure and apps."