#!/bin/bash
set -euo pipefail

# Ensure k3d
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Setup bootstrap manifests
if [ ! -d bootstrap ]; then mkdir bootstrap; fi

# Create cluster
k3d cluster create mgmt --volume $(pwd)/bootstrap:/var/lib/rancher/k3s/server/manifests/bootstrap 

# Wait until podCIDR is returned
until [[ $(kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}') =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]]; do 
  sleep 1
done 

# Install tink-stack helm chart
trusted_proxies=$(kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}' | tr ' ' ',')
STACK_CHART_VERSION=0.4.3
helm install tink-stack oci://ghcr.io/tinkerbell/charts/stack \
  --version "$STACK_CHART_VERSION" \
  --create-namespace \
  --namespace tink-system \
  --wait --set "smee.trustedProxies={${trusted_proxies}}" \
  --set "hegel.trustedProxies={${trusted_proxies}}"

