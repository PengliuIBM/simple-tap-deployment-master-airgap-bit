#!/bin/bash

set -e
set -u
set -o pipefail

TAP_VERSION=1.5.0
TBS_DEPS_VERSION=1.10.8

# Tanzu Data Services
# See this link for a mapping of SQL version -> TDS version.
# https://docs.vmware.com/en/VMware-SQL-with-Postgres-for-Kubernetes/2.0/vmware-postgres-k8s/GUID-release-notes.html#1_9_0_tds_packages
TDS_VERSION=1.5.0

# Tanzu Cluster Essentials.
# Find the latest here:
# https://docs.vmware.com/en/Cluster-Essentials-for-VMware-Tanzu/index.html
CLUSTER_ESSENTIALS_VERSION=1.5.0

# Associative array of package names and URLS. Add to this list to have the script
# download more packages.
declare -A packages=(
  ["ytt"]="https://github.com/carvel-dev/ytt/releases/download/v0.45.0/ytt-linux-amd64"
  ["imgpkg"]="https://github.com/carvel-dev/imgpkg/releases/download/v0.36.1/imgpkg-linux-amd64"
  ["k9s"]="https://github.com/derailed/k9s/releases/download/v0.27.3/k9s_Linux_amd64.tar.gz"
  ["yq"]="https://github.com/mikefarah/yq/releases/download/v4.33.3/yq_linux_amd64.tar.gz"
  ["tap-docs"]="https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap.pdf"
  ["kubectl-tree"]="https://github.com/ahmetb/kubectl-tree/releases/download/v0.4.3/kubectl-tree_v0.4.3_linux_amd64.tar.gz"
  ["kctrl"]="https://github.com/carvel-dev/kapp-controller/releases/download/v0.45.0/kctrl-linux-amd64"
  ["kubectl-view-allocations"]="https://github.com/davidB/kubectl-view-allocations/releases/download/0.16.3/kubectl-view-allocations_0.16.3-x86_64-unknown-linux-gnu.tar.gz"
  ["kubectl-view-utilizations"]="https://github.com/etopeter/kubectl-view-utilization/releases/download/v0.3.3/kubectl-view-utilization-v0.3.3.tar.gz"
)

DOWNLOAD_DIR=bits-for-transfer
mkdir -p ${DOWNLOAD_DIR}

function print_help {
  echo ""
  echo "Downloads software necessary for an airgapped install of TAP, including CLI utilities."
  echo "Usage: ./download-bits.sh [cli|grype|tap|tbs-deps|help]"
  echo ""
  echo "Optional features (requires updating TAP config files):"
  echo "cli                   Downloads CLI utilities. See list in the script."
  echo "grype                 Downloads the latest five Grype DBs and stubs a custom listing.json"
  echo "tap                   Uses imgpkg to download TAP. Version specified in the script."
  echo "tbs-deps              Uses imgpkg to download TBS Full Deps. Version specified in the script."
  echo "tds                   Uses imgpkg to download Tanzu Data Services. Version specified in the script."
  echo "cluster-essentials    Uses imgpkg to download Cluster Essentials. Version specified in the script."
  echo "all                   Downloads everything."
  echo "help                  Print this help message"
  echo ""
  exit 0
}

function download_cli_utils {
  CLI_DIR=${DOWNLOAD_DIR}/cli-and-docs
  mkdir -p ${CLI_DIR}
  for package_name in "${!packages[@]}"; do
    package_url="${packages[$package_name]}"
    echo "Downloading $package_name from $package_url..."
  
    # use -nc for "no clobber" so we don't re-download a file or clobber what's already there.
    wget -nc -P ${CLI_DIR} "$package_url"
  done

}

function download_grype_db {
  GRYPE_DIR=${DOWNLOAD_DIR}/grype
  mkdir -p ${GRYPE_DIR}

  ESCAPED_1=$(sed 's/[\*\/]/\\&/g' <<<"https://my-server.com")
  wget -nc -P ${GRYPE_DIR} https://toolbox-data.anchore.io/grype/databases/listing.json
  jq --arg v1 "https://my-server.com" '{ "available": { "1" : [.available."1"[0]] , "2" : [.available."2"[0]], "3" : [.available."3"[0]] , "4" : [.available."4"[0]] , "5" : [.available."5"[0]] } }' ${GRYPE_DIR}/listing.json > ${GRYPE_DIR}/listing.json.tmp
  mv ${GRYPE_DIR}/listing.json.tmp ${GRYPE_DIR}/listing.json
  wget -nc -P ${GRYPE_DIR} $(cat ${GRYPE_DIR}/listing.json |jq -r '.available."1"[0].url')
  wget -nc -P ${GRYPE_DIR} $(cat ${GRYPE_DIR}/listing.json |jq -r '.available."2"[0].url')
  wget -nc -P ${GRYPE_DIR} $(cat ${GRYPE_DIR}/listing.json |jq -r '.available."3"[0].url')
  wget -nc -P ${GRYPE_DIR} $(cat ${GRYPE_DIR}/listing.json |jq -r '.available."4"[0].url')
  wget -nc -P ${GRYPE_DIR} $(cat ${GRYPE_DIR}/listing.json |jq -r '.available."5"[0].url')
  sed -i -e "s/https:\/\/toolbox-data.anchore.io\/grype\/databases/$ESCAPED_1/g" ${GRYPE_DIR}/listing.json
}

#
# NOTE: You must be logged into Tanzunet. This script does not check for your auth status.
#

function download_tap {
  TAP_DIR=${DOWNLOAD_DIR}/tap
  mkdir -p ${TAP_DIR}
  echo "Downloading TAP version ${TAP_VERSION}..."
  echo "Note: this can take time as the images are roughly 10GB"
  imgpkg copy \
    -b registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:${TAP_VERSION} \
    --to-tar ${TAP_DIR}/tap-${TAP_VERSION}.tar \
    --include-non-distributable-layers
}

function download_tbs_deps {
  TBS_DIR=${DOWNLOAD_DIR}/tbs-deps
  mkdir -p ${TBS_DIR}
  echo "Downloading TBS Full Dependencies version ${TBS_DEPS_VERSION}..."
  echo "Note: This can take a while as the deps are roughly 11GB"
  imgpkg copy \
    -b registry.tanzu.vmware.com/tanzu-application-platform/full-tbs-deps-package-repo:${TBS_DEPS_VERSION} \
    --to-tar ${TBS_DIR}/tbs-deps-${TBS_DEPS_VERSION}.tar \
    --include-non-distributable-layers
}

function download_tds {
  TDS_DIR=${DOWNLOAD_DIR}/tanzu-data-services
  mkdir -p ${TDS_DIR}
  echo "Downloading Tanzu Data Services version ${TDS_VERSION}..."
  imgpkg copy \
    -b  registry.tanzu.vmware.com/packages-for-vmware-tanzu-data-services/tds-packages:${TDS_VERSION} \
    --to-tar ${TDS_DIR}/tanzu-data-services-${TDS_VERSION}.tar 
}

function download_cluster_essentials {
  CE_DIR=${DOWNLOAD_DIR}/cluster-essentials
  mkdir -p ${CE_DIR}
  echo "Downloading Tanzu Data Services version ${CLUSTER_ESSENTIALS_VERSION}..."
  imgpkg copy \
    -b registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle:${CLUSTER_ESSENTIALS_VERSION} \
    --to-tar ${CE_DIR}/cluster-essentials-bundle-${CLUSTER_ESSENTIALS_VERSION}.tar \
    --include-non-distributable-layers
}

if [ $# -eq 0 ]; then
  print_help
  exit 0
fi

for arg in "$@"
do
  case $arg in
    cli)
      download_cli_utils
      ;;
    grype)
      download_grype_db
      ;;
    tap)
      download_tap
      ;;
    tbs-deps)
      download_tbs_deps
      ;;
    tds)
      download_tds
      ;;
    cluster-essentials)
      download_cluster_essentials
      ;;
    all)
      download_cli_utils
      download_grype_db
      download_tap
      download_tbs_deps
      download_tds
      download_cluster_essentials
      ;;
    help)
      print_help
      ;;
    *)
      print_help
      exit 1
      ;;
  esac
done

echo -e  "\n\n##############################################################################################"
echo -e "\nFinished. All files are stored in ${DOWNLOAD_DIR}"
echo -e "\n\nYou will still need to manually download the Tanzu CLI."
echo -e "See https://network.tanzu.vmware.com/products/tanzu-application-platform to get started.\n"
echo -e "##############################################################################################\n\n"