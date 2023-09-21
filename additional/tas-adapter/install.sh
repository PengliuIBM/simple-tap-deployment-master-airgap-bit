#!/bin/bash

set -e
set -u
set -o pipefail

TAS_ADAPTER_VERSION=$(yq -r .tas_adapter.version tas-adapter-config.yml)

echo -e "\nInstalling TAS Adapter version ${TAS_ADAPTER_VERSION}"
# Install TAS repo
echo -e "\nInstalling TAS repo...\n"
ytt --data-values-file tas-adapter-config.yml --data-values-file ../../tap-install-config.yml --data-values-file ../../tap-install-secrets.yml -f tas-adapter-repo.yml | kubectl apply -f-

ytt --data-values-file tas-adapter-config.yml --data-values-file ../../tap-install-config.yml --data-values-file ../../tap-install-secrets.yml -f tas-adapter-values-templated.yml > tas-adapter-values.yml

# Install TAS Adapter and/or update it if changed
echo -e "\nInstalling TAS Adapter...\n"
tanzu package install tas-adapter \
  -p application-service-adapter.tanzu.vmware.com \
  --version "${TAS_ADAPTER_VERSION}" \
  --values-file tas-adapter-values.yml \
  --namespace tap-install 