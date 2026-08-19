#!/usr/bin/env bash
set -e

echo "==> Creating k3d cluster..."
k3d cluster create portfolio-dev --agents 1

echo "==> Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "==> Installing kube-prometheus-stack..."
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f infrastructure/monitoring/values-kube-prometheus.yaml

echo "==> Installing ArgoCD..."
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace

echo "==> Deploying portfolio application..."
kubectl apply -f apps/portfolio/ -n portfolio

echo "==> Environment ready! Access services with kubectl port-forward."
