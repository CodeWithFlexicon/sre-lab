#!/usr/bin/env bash
set -euo pipefail

LAB_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DEMO_DIR="$LAB_ROOT/../microservices-demo"

echo "==> Start Colima VM (arm64)"
colima start --profile boutique --arch arm64 --cpu 4 --memory 4 --disk 40
docker context use colima-boutique

echo "==> Recreate kind cluster"
kind delete cluster --name boutique || true
kind create cluster --name boutique --image kindest/node:v1.30.0

echo "==> Apply arm64 patch to Cart Service"
"$LAB_ROOT/patches/patch-cartservice.sh" "$DEMO_DIR"

echo "==> Build & deploy Online Boutique (arm64)"
(cd "$DEMO_DIR" && skaffold run --platform=linux/arm64 --kube-context kind-boutique)

echo "==> Cluster is up.  Browse: http://localhost:8080"
kubectl port-forward svc/frontend 8080:80
