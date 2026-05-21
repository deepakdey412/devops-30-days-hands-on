#!/bin/bash

set -e

echo "🚀 Creating namespace..."
kubectl create namespace argocd || true

echo "🚀 Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

echo "🌐 Exposing Argo CD Server (NodePort)..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

echo "🔑 Fetching admin password..."
echo "Username: admin"
echo -n "Password: "
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

echo "✅ Argo CD installed successfully!"
echo "👉 Run: kubectl get svc -n argocd"