#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "===================================================="
echo "🚀 Initializing CoreBank Local Kubernetes Cluster"
echo "===================================================="

# 1. Switch context to Docker Desktop to ensure we don't accidentally deploy to cloud
echo "🌐 Setting kubectl context to docker-desktop..."
kubectl config use-context docker-desktop

# 2. Create Core Enterprise Namespaces
echo "📦 Creating isolated namespaces..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: prod-fintech
  labels:
    istio-injection: enabled # Auto-inject Istio sidecar proxies
EOF

kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# 3. Create Network Isolation (Default Deny All)
echo "🛡️  Applying Zero-Trust default-deny network policy..."
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: prod-fintech
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# 4. Mock Local Infrastructure Secrets
echo "🔑 Injecting local staging bootstrap secrets..."
kubectl create secret generic mysql-db-credentials \
  --from-literal=username=corebank_admin \
  --from-literal=password=SuperSecureBankPass2026 \
  -n prod-fintech --dry-run=client -o yaml | kubectl apply -f -

echo "===================================================="
echo "✅ Local bootstrap complete! System ready for apps."
echo "===================================================="
