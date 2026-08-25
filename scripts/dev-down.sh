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

# 4. If using local cluster teardown (optional)
# minikube delete || kind delete cluster

echo "==> Dev environment is DOWN and clean."