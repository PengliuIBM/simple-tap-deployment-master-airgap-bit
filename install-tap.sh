#!/bin/bash

set -e
set -u
set -o pipefail

function print_help {
  echo ""
  echo "Installs TAP, plus optional features."
  echo "Usage: ./install-tap.sh [certs|external-dns|sql|full-deps|help]"
  echo ""
  echo "Optional features (requires updating TAP config files):"
  echo "certs         Configure cert-manager to TLS-secure TAP"
  echo "external-dns  Configure external-dns"
  echo "sql           Install latest verions of Tanzu PostgreSQL and MySQL"
  echo "full-deps     Configure Full TBS dependencies"
  echo "help          Print this help message"
  echo ""
}

# Did the user ask for help?
for arg in "$@"
do
  case $arg in
    help)
     print_help 
     exit 0
      ;;
  esac
done

#
# We'll render each manifest file, dump it to disk, and feed the file to kubectl.
# Why do that instead of piping? Because having the rendered files on-hand is useful
# for troubleshooting.
#
RENDERED_FILES_DIR=rendered-files
echo -e "\nStoring all rendered files in the directory ${RENDERED_FILES_DIR}"
mkdir -p ${RENDERED_FILES_DIR}

TAP_VERSION=$(yq -r .tap.version          tap-install-config.yml)
TDS_MYSQL_OPERATOR_VERSION=$(yq -r .tap.tds_mysql_operator_version tap-install-config.yml)
TDS_POSTGRES_OPERATOR_VERSION=$(yq -r .tap.tds_postgres_operator_version tap-install-config.yml)

#
# Functions for additional features
#

function print_tap_install_failure {
  echo -e "\nFailure detected while deploying TAP. Sometimes this is a false-negative."
  echo    "We recommend you examine the app itself (kubectl get app -n tap-install) for further examination."
  echo    "It may simply still be 'Reconciling'"
  exit 1
}

function airgap_grype {
  # Deploy the Secret used by the Grype airgap overlay
  echo -e "\nConfiguring for offline Grype...\n"
  kubectl apply -f additional/grype/grype-airgap-overlay.yml
}

function external_dns {
  echo -e "\nConfiguring External DNS...\n"
  ytt --data-values-file tap-install-config.yml \
      --data-values-file tap-install-secrets.yml \
      -f additional/external-dns \
      > ${RENDERED_FILES_DIR}/tap-external-dns.yml 
  kubectl apply -f ${RENDERED_FILES_DIR}/tap-external-dns.yml
}

function certs {
  echo -e "\nConfiguring Certificates...\n"
  ytt --data-values-file tap-install-config.yml \
      --data-values-file tap-install-secrets.yml \
      -f additional/certificates/certificate.yml \
      -f additional/certificates/tls-cert-delegation.yml \
      -f additional/certificates/lets-encrypt-cluster-issuer.yml \
      > ${RENDERED_FILES_DIR}/tap-external-dns.yml 
  kubectl apply -f ${RENDERED_FILES_DIR}/tap-external-dns.yml
}

function full_tbs {
  echo -e "\nInstalling full TBS dependencies...\n"
  ytt --data-values-file tap-install-config.yml \
    --data-values-file tap-install-secrets.yml \
    -f prereqs/full-tbs-deps.yml > ${RENDERED_FILES_DIR}/full-tbs-deps.yml
  kubectl apply -f ${RENDERED_FILES_DIR}/full-tbs-deps.yml
  for x in {1..30}; do
    [ $(kubectl get packagerepository tbs-full-deps-repository -n tap-install -o jsonpath='{.status.conditions[0].type}') == 'ReconcileSucceeded' ] && break
    echo "TBS Package repo not reconciled yet, trying a max of 30 times"
    sleep 1
    if [ ${x} -eq 30 ]
    then
      echo 'TBS Package repo has not reconciled before timeout. Quitting.'
      exit 1
    fi
  done
  tanzu package install full-deps -p full-deps.buildservice.tanzu.vmware.com -v "> 0.0.0" -n tap-install --values-file ./rendered-files/tap-values-full.yml
}

function sql {
  echo -e "\nInstalling Tanzu SQL...\n"
  ytt --data-values-file tap-install-config.yml \
      --data-values-file tap-install-secrets.yml \
      -f additional/sql \
      > ${RENDERED_FILES_DIR}/tap-sql.yml 
  kubectl apply -f ${RENDERED_FILES_DIR}/tap-sql.yml
  for x in {1..30}; do
    [ $(kubectl get packagerepository tds-repo -n tap-install -o jsonpath='{.status.conditions[0].type}') == 'ReconcileSucceeded' ] && break
    echo "TDS Package repo not reconciled yet, trying a max of 30 times"
    sleep 1
    if [ ${x} -eq 30 ]
    then
      echo 'TDS Package repo has not reconciled before timeout. Quitting.'
      exit 1
    fi
  done
  tanzu package install mysql-operator -p mysql-operator.with.sql.tanzu.vmware.com -v $TDS_MYSQL_OPERATOR_VERSION -n tap-install
  tanzu package install postgres-operator -p postgres-operator.sql.tanzu.vmware.com -v $TDS_POSTGRES_OPERATOR_VERSION -n tap-install

  # ref: docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap/services-toolkit-how-to-guides-dynamic-provisioning-tanzu-postgresql.html
  # create Namespace first to avoid reconcile failures in the next step.
  ytt --data-values-file tap-install-config.yml \
      --data-values-file tap-install-secrets.yml \
      -f ./additional/sql/psql/psql-operator-namespace.yml | kubectl apply -f-

  ytt --data-values-file tap-install-config.yml \
      --data-values-file tap-install-secrets.yml \
      -f ./additional/sql/psql/. | kubectl apply -f-
}

# Install pre-reqs
echo -e "\nInstalling pre-reqs...\n"
ytt --data-values-file tap-install-config.yml \
    --data-values-file tap-install-secrets.yml \
    -f prereqs/tap-namespace.yml > ${RENDERED_FILES_DIR}/tap-namespace.yml 
kubectl apply -f ${RENDERED_FILES_DIR}/tap-namespace.yml

ytt --data-values-file tap-install-config.yml \
    --data-values-file tap-install-secrets.yml \
    -f prereqs/tap-registry.yml > ${RENDERED_FILES_DIR}/tap-registry.yml
kubectl apply -f ${RENDERED_FILES_DIR}/tap-registry.yml

ytt --data-values-file tap-install-config.yml \
    --data-values-file tap-install-secrets.yml \
    -f prereqs/tap-repo.yml > ${RENDERED_FILES_DIR}/tap-repo.yml
kubectl apply -f ${RENDERED_FILES_DIR}/tap-repo.yml

# Don't try to install TAP until the package repo reconciles. (hacky)
for x in {1..30}; do
  [ $(kubectl get packagerepository tanzu-tap-repository -n tap-install -o jsonpath='{.status.conditions[0].type}') == 'ReconcileSucceeded' ] && break
  echo "Package repo not reconciled yet, trying a max of 30 times"
  sleep 1
  if [ ${x} -eq 30 ]
  then
    echo 'Package repo has not reconciled before timeout. Quitting.'
    exit 1
  fi
done

# Package repo reconciled. Sleep for another 5 seconds. IDK why. We should fix this.
echo 'TAP package repo reconciled successfully'
sleep 5

# Create the values file from templated configs
echo -e "\nGenerating TAP Values file...\n"
ytt --data-values-file tap-install-config.yml --data-values-file tap-install-secrets.yml -f tap-values-templated.yml > ${RENDERED_FILES_DIR}/tap-values-full.yml

# Install TAP and/or update it if changed
echo -e "\nInstalling TAP from values file...\n"
tanzu package install tap -p tap.tanzu.vmware.com -v $TAP_VERSION --values-file ${RENDERED_FILES_DIR}/tap-values-full.yml -n tap-install  || print_tap_install_failure

# Did we specify any additional actions?
for arg in "$@"
do
  case $arg in
    certs)
      certs
      ;;
    external-dns)
      external_dns
      ;;
    full-deps)
      full_tbs
      ;;
    sql)
      sql
      ;;
    airgap-grype)
      airgap_grype
      ;;
    help)
      print_help
      ;;
    *)
      echo -e "\Invalid argument: ${arg}"
      exit 1
      ;;
  esac
done

echo -e "\nInstall Complete!\n"
