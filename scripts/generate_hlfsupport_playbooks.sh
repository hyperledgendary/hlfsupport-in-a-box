#!/usr/bin/env bash
set -ex -u -o pipefail
ROOTDIR=$(cd "$(dirname "$0")/.." && pwd)

# This is a general version playbook generation script
# for targetting both IKS, and OCP

DOCKER_REGISTRY=us.icr.io
: ${DOCKER_REPOSITORY:=ibp-temp}
: ${DOCKER_USERNAME:=iamapikey}    
: ${DOCKER_EMAIL}
: ${DOCKER_IMAGE_PREFIX:=ibm-hlfsupport}
: ${CONSOLE_DOMAIN}
: ${PROJECT_NAME_VALUE:="hlf-network"}

ARCHITECTURE=amd64

# Enforce these variables to be set
: ${DOCKER_PW}
: ${CLUSTER_TYPE:=ocp}
: ${PRODUCT_VERSION:=1.0.0}
: ${OPERATOR_VERSION:=20220308}
: ${WEBHOOK_VERSION:=20220308}
: ${CONSOLE_STORAGE_CLASS:="default"}

if [ $CLUSTER_TYPE == "iks" ]; then
  TARGET_VALUE=k8s
  PROJECT_OR_NAMEPSACE_KEY=namespace
elif [ $CLUSTER_TYPE == "ocp" ]; then
  TARGET_VALUE=openshift
  PROJECT_OR_NAMEPSACE_KEY=project
else
  echo "CLUSTER_TYPE Unkown, can't create playbooks"
  exit -1
fi

# ensure the version tool has been updated
#npm install --prefix ../../utility/ibp_hlf_versions/

echo "Writing latest-crds.yml file"
cat > $ROOTDIR/playbooks/latest-crds.yml <<EOF
---
- name: Deploy IBM HLF Support custom resource definitions
  hosts: localhost
  vars:
    state: present
    target: ${TARGET_VALUE}
    arch: ${ARCHITECTURE}
    ${PROJECT_OR_NAMEPSACE_KEY}: ibm-hlfsupport-infra
    image_registry_password: ${DOCKER_PW}
    image_registry_email: ${DOCKER_USERNAME}
    product_version: ${PRODUCT_VERSION}
    webhook_version: ${WEBHOOK_VERSION}
    wait_timeout: 3600
  roles:
    - ibm.blockchain_platform.hlfsupport_crds
EOF

echo "Writing latest-console.yml file"
cat > $ROOTDIR/playbooks/latest-console.yml <<EOF
- name: Deploy IBM HLF Support console
  hosts: localhost
  vars:
    state: present
    target: ${TARGET_VALUE}
    arch:  ${ARCHITECTURE}
    ${PROJECT_OR_NAMEPSACE_KEY}: ${PROJECT_NAME_VALUE}
    image_registry_password: ${DOCKER_PW}
    image_registry_email: ${DOCKER_USERNAME}
    console_storage_class: ${CONSOLE_STORAGE_CLASS}
    console_domain: ${CONSOLE_DOMAIN}
    console_email: nobody@ibm.com
    console_default_password: new42day
    wait_timeout: 3600
    product_version: ${PRODUCT_VERSION}
    operator_version: ${OPERATOR_VERSION}
  roles:
    - ibm.blockchain_platform.hlfsupport_console
EOF
