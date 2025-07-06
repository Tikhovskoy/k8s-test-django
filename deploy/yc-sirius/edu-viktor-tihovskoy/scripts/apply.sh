#!/bin/bash

set -e

echo "Применяю все манифесты dev-окружения"

kubectl apply -f manifests/

echo "Готово"
