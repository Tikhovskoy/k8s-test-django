#!/bin/bash

set -euo pipefail

NAMESPACE="edu-viktor-tihovskoy"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="$SCRIPT_DIR/../manifests"
SECRETS_DIR="$SCRIPT_DIR/../secrets"

echo "Применяю secrets"
kubectl apply -n "$NAMESPACE" -f "$SECRETS_DIR"

echo "Применяю manifests"
kubectl apply -n "$NAMESPACE" -f "$MANIFESTS_DIR"

echo "Готово: все ресурсы применены в namespace '$NAMESPACE'"
