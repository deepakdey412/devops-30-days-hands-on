#!/bin/bash

set -e

echo "📦 Creating argocd namespace..."
kubectl create namespace argocd || true

echo "🚀 Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Waiting for Argo CD pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s || true

echo "📊 Checking pods..."
kubectl get pods -n argocd

echo "🌐 Exposing Argo CD server (LoadBalancer)..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo "📡 Services:"
kubectl get svc -n argocd

echo "🔑 Fetching admin password..."
echo "--------------------------------------"
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d
echo ""
echo "--------------------------------------"

echo "✔ Argo CD installation completed!"
echo "👉 Username: admin"
echo "👉 Password: (above)"