#!/usr/bin/env bash
set -euo pipefail

echo "==> Spinning up local dev environment..."

# 1. If using Kind/Minikube locally, ensure cluster is running (optional)
# minikube start || kind create cluster

# 2. Trigger the bootstrap script to install Argo CD & Root App
bash scripts/bootstrap.sh

echo "==> Dev environment is UP and GitOps is active!"