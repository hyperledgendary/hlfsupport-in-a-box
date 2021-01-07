#!/usr/bin/env bash
set -euo pipefail
DOCKER_REGISTRY=us.icr.io
DOCKER_REPOSITORY=ibp-temp
DOCKER_USERNAME=token
DOCKER_PASSWORD=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiIyMmVkZGJhMC0xNDVmLTU3NDAtOWVkYi1lMTZmMTY4MjgzNDYiLCJpc3MiOiJyZWdpc3RyeS5uZy5ibHVlbWl4Lm5ldCJ9.ZQV5Zem-xIjBXp9LQkEEVnaXz52VpavUi3Pl2kpCfCg
DOCKER_EMAIL=nobody@ibm.com
PRODUCT_VERSION=2.5.1
ARCHITECTURE=amd64
FABRIC_V1_VERSION=1.4.9
FABRIC_V2_VERSION=2.2.1
COUCHDB_V2_VERSION=2.3.1
COUCHDB_V3_VERSION=3.1.0
CONSOLE_DOMAIN=apps.nx01.cp.fyre.ibm.com


function get_latest_tag {
    docker-ls \
    tags \
    -j \
    -u ${DOCKER_USERNAME} \
    -p ${DOCKER_PASSWORD} \
    -r https://${DOCKER_REGISTRY} \
    "$1" \
    | jq -r ".tags | map(select(test(\"^${2:-${PRODUCT_VERSION}}-\\\\d{8}-${ARCHITECTURE}\$\"))) | .[-1]"
}
CRDWEBHOOK_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-crdwebhook)
INIT_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-init)
ENROLLER_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-enroller)
OPERATOR_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-operator)
UTILITIES_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-utilities ${FABRIC_V2_VERSION})
CONSOLE_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-console)
COUCHDB_TAG_V2=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-couchdb ${COUCHDB_V2_VERSION})
COUCHDB_TAG_V3=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-couchdb ${COUCHDB_V3_VERSION})
DEPLOYER_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-deployer)
GRPCWEB_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-grpcweb)
FLUENTD_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-fluentd)
DIND_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-dind ${FABRIC_V1_VERSION})
PEER_TAG_V1=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-peer ${FABRIC_V1_VERSION})
PEER_TAG_V2=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-peer ${FABRIC_V2_VERSION})
ORDERER_TAG_V1=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-orderer ${FABRIC_V1_VERSION})
ORDERER_TAG_V2=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-orderer ${FABRIC_V2_VERSION})
CA_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-ca ${FABRIC_V1_VERSION})
CCENV_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-ccenv ${FABRIC_V2_VERSION})
GOENV_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-goenv ${FABRIC_V2_VERSION})
JAVAENV_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-javaenv ${FABRIC_V2_VERSION})
NODEENV_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-nodeenv ${FABRIC_V2_VERSION})
CHAINCODE_LAUNCHER_TAG=$(get_latest_tag ${DOCKER_REPOSITORY}/ibp-chaincode-launcher ${FABRIC_V2_VERSION})
cat > latest-crds.yml <<EOF
---
- name: Deploy IBM Blockchain Platform custom resource definitions
  hosts: localhost
  vars:
    state: present
    target: openshift
    arch: amd64
    project: ibpinfra
    image_registry: ${DOCKER_REGISTRY}
    image_repository: ${DOCKER_REPOSITORY}
    image_registry_url: ""
    image_registry_username: ${DOCKER_USERNAME}
    image_registry_password: ${DOCKER_PASSWORD}
    image_registry_email: ${DOCKER_EMAIL}
    product_version: ${PRODUCT_VERSION}
    webhook_image: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-crdwebhook
    webhook_tag: ${CRDWEBHOOK_TAG}
    wait_timeout: 3600
  roles:
    - ibm.blockchain_platform.crds
EOF
cat > latest.yml <<EOF
- name: Deploy IBM Blockchain Platform console
  hosts: localhost
  vars:
    state: present
    target: openshift
    arch: amd64
    project: ibp-zeta
    console_domain: ${CONSOLE_DOMAIN}
    console_email: nobody@ibm.com
    console_default_password: new42day
    console_storage_class: rook-cephfs
    image_registry: ${DOCKER_REGISTRY}
    image_repository: ${DOCKER_REPOSITORY}
    image_registry_url: ""
    image_registry_username: ${DOCKER_USERNAME}
    image_registry_password: ${DOCKER_PASSWORD}
    image_registry_email: ${DOCKER_EMAIL}
    product_version: ${PRODUCT_VERSION}
    operator_image: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-operator
    operator_tag: ${OPERATOR_TAG}
    console_images:
        configtxlatorImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-utilities
        configtxlatorTag: ${UTILITIES_TAG}
        consoleInitImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-init
        consoleInitTag: ${INIT_TAG}
        consoleImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-console
        consoleTag: ${CONSOLE_TAG}
        couchdbImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-couchdb
        couchdbTag: ${COUCHDB_TAG_V2}
        deployerImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-deployer
        deployerTag: ${DEPLOYER_TAG}
    console_versions:
      ca:
        ${FABRIC_V1_VERSION}-0:
          default: true
          image:
            caImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-ca
            caTag: ${CA_TAG}
            caInitImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-init
            caInitTag: ${INIT_TAG}
            enrollerImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-enroller
            enrollerTag: ${ENROLLER_TAG}
          version: ${FABRIC_V1_VERSION}-0
      orderer:
        ${FABRIC_V1_VERSION}-0:
          default: true
          image:
            grpcwebImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-grpcweb
            grpcwebTag: ${GRPCWEB_TAG}
            ordererImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-orderer
            ordererTag: ${ORDERER_TAG_V1}
            ordererInitImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-init
            ordererInitTag: ${INIT_TAG}
            enrollerImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-enroller
            enrollerTag: ${ENROLLER_TAG}
          version: ${FABRIC_V1_VERSION}-0
        ${FABRIC_V2_VERSION}-0:
          default: false
          image:
            grpcwebImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-grpcweb
            grpcwebTag: ${GRPCWEB_TAG}
            ordererImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-orderer
            ordererTag: ${ORDERER_TAG_V2}
            ordererInitImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-init
            ordererInitTag: ${INIT_TAG}
            enrollerImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-enroller
            enrollerTag: ${ENROLLER_TAG}
          version: ${FABRIC_V2_VERSION}-0
      peer:
        ${FABRIC_V1_VERSION}-0:
          default: true
          image:
            couchdbImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-couchdb
            couchdbTag: ${COUCHDB_TAG_V2}
            dindImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-dind
            dindTag: ${DIND_TAG}
            fluentdImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-fluentd
            fluentdTag: ${FLUENTD_TAG}
            grpcwebImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-grpcweb
            grpcwebTag: ${GRPCWEB_TAG}
            peerImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-peer
            peerTag: ${PEER_TAG_V1}
            peerInitImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-init
            peerInitTag: ${INIT_TAG}
            enrollerImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-enroller
            enrollerTag: ${ENROLLER_TAG}
          version: ${FABRIC_V1_VERSION}-0
        ${FABRIC_V2_VERSION}-0:
          default: false
          image:
            chaincodeLauncherImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-chaincode-launcher
            chaincodeLauncherTag: ${CHAINCODE_LAUNCHER_TAG}
            builderImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-ccenv
            builderTag: ${CCENV_TAG}
            goEnvImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-goenv
            goEnvTag: ${GOENV_TAG}
            javaEnvImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-javaenv
            javaEnvTag: ${JAVAENV_TAG}
            nodeEnvImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-nodeenv
            nodeEnvTag: ${NODEENV_TAG}
            couchdbImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-couchdb
            couchdbTag: ${COUCHDB_TAG_V3}
            grpcwebImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-grpcweb
            grpcwebTag: ${GRPCWEB_TAG}
            peerImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-peer
            peerTag: ${PEER_TAG_V2}
            peerInitImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-init
            peerInitTag: ${INIT_TAG}
            enrollerImage: ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/ibp-enroller
            enrollerTag: ${ENROLLER_TAG}
          version: ${FABRIC_V2_VERSION}-0
    wait_timeout: 3600
  roles:
    - ibm.blockchain_platform.console
EOF