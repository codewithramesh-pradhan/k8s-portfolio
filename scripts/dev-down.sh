#!/usr/bin/env bash
set -euo pipefail

echo "==> Tearing down dev environment..."

# 1. Kill background port-forwards
echo "Killing active port-forward processes..."
pkill -f "kubectl port-forward" || true

# 2. Delete the Root App (Cascades deletion to all apps and namespaces)
if kubectl get app root-app -n argocd &>/dev/null; then
  echo "Deleting Argo CD root application (cascading prune)..."
  kubectl delete app root-app -n argocd --cascade=foreground --timeout=60s || true
fi

# 3. Optional: Delete namespaces manually if destroying everything
kubectl delete namespace portfolio monitoring argocd --ignore-not-found=true

# 4. Delete the Kind cluster
if kind get clusters 2>/dev/null | grep -q "k8s-portfolio"; then
  echo "Deleting Kind cluster: k8s-portfolio..."
  kind delete cluster --name k8s-portfolio
fi

# 5. Delete the k3d cluster
if k3d cluster list 2>/dev/null | grep -q "portfolio-dev"; then
  echo "Deleting k3d cluster: portfolio-dev..."
  k3d cluster delete portfolio-dev
fi

echo "==> Dev environment is DOWN and clean."