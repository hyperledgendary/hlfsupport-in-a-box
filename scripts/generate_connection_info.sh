#!/usr/bin/env bash
set -ex -u -o pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd ${ROOT_DIR}/playbooks/fabric-test-network
export IBP_ANSIBLE_LOG_FILENAME=ansible_debug.log

set -x
ansible-playbook 22-register-application.yml --extra-vars @auth-vars.yml 
ansible-playbook 23-register-application.yml --extra-vars @auth-vars.yml 
set +x