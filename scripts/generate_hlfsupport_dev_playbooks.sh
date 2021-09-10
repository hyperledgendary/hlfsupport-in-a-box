#!/usr/bin/env bash
set -ex -u -o pipefail
ROOTDIR=$(cd "$(dirname "$0")/.." && pwd)

# This is a general version playbook generation script
# for targetting both IKS, and OCP

DOCKER_REGISTRY=us.icr.io
: ${DOCKER_REPOSITORY:=ibp-temp}
: ${DOCKER_USERNAME:=iamapikey}     # iks had this as token??
DOCKER_EMAIL=bmxbcv1@us.ibm.com
: ${DOCKER_IMAGE_PREFIX:=ibm-hlfsupport}
: ${CONSOLE_DOMAIN}

FABRIC_V2_VERSION=${FABRIC_V2:-2.2}
COUCHDB_V2_VERSION=${COUCHDB_V2:-2.3}
COUCHDB_V3_VERSION=${COUCHDB_V3:-3.1}

: ${FABRIC_CA_VERSION:=1.5.1}

ARCHITECTURE=amd64

# Enforce these variables to be set
: ${DOCKER_PW}
: ${CLUSTER_TYPE:=ocp}
: ${PRODUCT_VERSION:=1.0.0}

if [ $CLUSTER_TYPE == "iks" ]; then
  TARGET_VALUE=k8s
  PROJECT_OR_NAMEPSACE_KEY=namespace
  CONSOLE_STORAGE_CLASS="# not required"
elif [ $CLUSTER_TYPE == "ocp" ]; then
  TARGET_VALUE=openshift
  PROJECT_OR_NAMEPSACE_KEY=project
  CONSOLE_STORAGE_CLASS="# not required"
elif [ $CLUSTER_TYPE == "ocp-fyre" ]; then
  TARGET_VALUE=openshift
  PROJECT_OR_NAMEPSACE_KEY=project
  CONSOLE_STORAGE_CLASS="console_storage_class: rook-cephfs"
else
  echo "CLUSTER_TYPE Unkown, can't create playbooks"
  exit -1
fi

# ensure the version tool has been updated
#npm install --prefix ../../utility/ibp_hlf_versions/

# Note that it might have been a lot easier to do this as JS script?
function get_latest_tag {
VER=${2:-${PRODUCT_VERSION}}
docker-ls tags -j  -u ${DOCKER_USERNAME} -p ${DOCKER_PW} -r https://${DOCKER_REGISTRY} "$1" | ${ROOTDIR}/utility/ibp_hlf_versions/docker-tags-parse.js -a amd64 -m "~${VER}"
}

: ${CRDWEBHOOK_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-crdwebhook)}
: ${INIT_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-init)}
: ${ENROLLER_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-enroller)}
: ${OPERATOR_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-operator)}
: ${UTILITIES_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-utilities ${FABRIC_V2_VERSION})}
: ${CONSOLE_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-console)}
: ${COUCHDB_TAG_V2:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-couchdb ${COUCHDB_V2_VERSION})}
: ${COUCHDB_TAG_V3:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-couchdb ${COUCHDB_V3_VERSION})}
: ${DEPLOYER_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-deployer)}
: ${GRPCWEB_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-grpcweb)}
: ${FLUENTD_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-fluentd)}
: ${DIND_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-dind ${FABRIC_V1_VERSION})}
: ${PEER_TAG_V1:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-peer ${FABRIC_V1_VERSION})}
: ${PEER_TAG_V2:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-peer ${FABRIC_V2_VERSION})}
: ${ORDERER_TAG_V1:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-orderer ${FABRIC_V1_VERSION})}
: ${ORDERER_TAG_V2:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-orderer ${FABRIC_V2_VERSION})}
: ${CA_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-ca 1.5.1)}
: ${CCENV_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-ccenv ${FABRIC_V2_VERSION})}
: ${GOENV_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-goenv ${FABRIC_V2_VERSION})}
: ${JAVAENV_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-javaenv ${FABRIC_V2_VERSION})}
: ${NODEENV_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-nodeenv ${FABRIC_V2_VERSION})}
: ${CHAINCODE_LAUNCHER_TAG:=$(get_latest_tag ${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-chaincode-launcher ${FABRIC_V2_VERSION})}


# determine the full version to use for the playbooks
FABRIC_V2_FULL_VERSION=$(echo ${JAVAENV_TAG} | cut -d '-' -f1)
FABRIC_V1_FULL_VERSION=$(echo ${ORDERER_TAG_V1} | cut -d '-' -f1)
PRODUCT_FULL_VERSION=$(echo ${INIT_TAG} | cut -d '-' -f1)

# note the 2.5.2 tag in the CRDs setting

echo "Writing latest-crds.yml file"
cat > $ROOTDIR/playbooks/latest-crds.yml <<EOF
---
- name: Deploy IBM Blockchain Platform custom resource definitions
  hosts: localhost
  vars:
    state: present
    target: ${TARGET_VALUE}
    arch: ${ARCHITECTURE}
    ${PROJECT_OR_NAMEPSACE_KEY}: hlfinfra
    image_registry: ${DOCKER_REGISTRY}
    image_repository: ${DOCKER_REPOSITORY}
    image_registry_url: ""
    image_registry_username: ${DOCKER_USERNAME}
    image_registry_password: ${DOCKER_PW}
    image_registry_email: ${DOCKER_EMAIL}
    product_version: 1.0.0
    webhook_image: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-crdwebhook
    webhook_tag: ${CRDWEBHOOK_TAG}
    wait_timeout: 3600
  roles:
    - ibm.blockchain_platform.hlfsupport_crds
EOF

echo "Writing latest-console.yml file"
cat > $ROOTDIR/playbooks/latest-console.yml <<EOF
- name: Deploy IBM Blockchain Platform console
  hosts: localhost
  vars:
    state: present
    target: ${TARGET_VALUE}
    arch: ${ARCHITECTURE}
    ${PROJECT_OR_NAMEPSACE_KEY}: marvin
    console_domain: ${CONSOLE_DOMAIN}
    console_email: nobody@ibm.com
    console_default_password: new42day
    ${CONSOLE_STORAGE_CLASS}
    image_registry: ${DOCKER_REGISTRY}
    image_repository: ${DOCKER_REPOSITORY}
    image_registry_url: ""
    image_registry_username: ${DOCKER_USERNAME}
    image_registry_password: ${DOCKER_PW}
    image_registry_email: ${DOCKER_EMAIL}
    product_version: 1.0.0
    operator_image: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-operator
    operator_tag: ${OPERATOR_TAG}
    console_images:
        configtxlatorImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-utilities
        configtxlatorTag: ${UTILITIES_TAG}
        consoleInitImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-init
        consoleInitTag: ${INIT_TAG}
        consoleImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-console
        consoleTag: ${CONSOLE_TAG}
        couchdbImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-couchdb
        couchdbTag: ${COUCHDB_TAG_V2}
        deployerImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-deployer
        deployerTag: ${DEPLOYER_TAG}
    console_versions:
      ca:
        1.5.1-0:
          default: true
          image:
            caImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-ca
            caTag: ${CA_TAG}
            caInitImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-init
            caInitTag: ${INIT_TAG}
            enrollerImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-enroller
            enrollerTag: ${ENROLLER_TAG}
          version: 1.5.1-0
      orderer:
        ${FABRIC_V2_FULL_VERSION}-0:
          default: true
          image:
            grpcwebImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-grpcweb
            grpcwebTag: ${GRPCWEB_TAG}
            ordererImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-orderer
            ordererTag: ${ORDERER_TAG_V2}
            ordererInitImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-init
            ordererInitTag: ${INIT_TAG}
            enrollerImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-enroller
            enrollerTag: ${ENROLLER_TAG}
          version: ${FABRIC_V2_FULL_VERSION}-0
      peer:
        ${FABRIC_V2_FULL_VERSION}-0:
          default: true
          image:
            chaincodeLauncherImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-chaincode-launcher
            chaincodeLauncherTag: ${CHAINCODE_LAUNCHER_TAG}
            builderImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-ccenv
            builderTag: ${CCENV_TAG}
            goEnvImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-goenv
            goEnvTag: ${GOENV_TAG}
            javaEnvImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-javaenv
            javaEnvTag: ${JAVAENV_TAG}
            nodeEnvImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-nodeenv
            nodeEnvTag: ${NODEENV_TAG}
            couchdbImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-couchdb
            couchdbTag: ${COUCHDB_TAG_V3}
            grpcwebImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-grpcweb
            grpcwebTag: ${GRPCWEB_TAG}
            peerImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-peer
            peerTag: ${PEER_TAG_V2}
            peerInitImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-init
            peerInitTag: ${INIT_TAG}
            enrollerImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_PREFIX}-enroller
            enrollerTag: ${ENROLLER_TAG}
          version: ${FABRIC_V2_FULL_VERSION}-0
    wait_timeout: 3600
  roles:
    - ibm.blockchain_platform.hlfsupport_console
EOF
