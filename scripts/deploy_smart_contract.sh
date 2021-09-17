#!/usr/bin/env bash
set -ex -u -o pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

function usage {
    echo "Usage: deploy_smart_contract.sh" 1>&2
    exit 1
}
while getopts ":" OPT; do
    case ${OPT} in
        \?)
            usage
            ;;
    esac
done

# clone and build the contract to install
cd ${ROOT_DIR}
# git clone https://github.com/hyperledgendary/ibp-fabric-toolchain-demo-scenario.git
# cd ibp-fabric-toolchain-demo-scenario/contracts/asset-transfer-ts
# npm install && npm run package


# will be packaged to 
# /workspace/ibp-fabric-toolchain-demo-scenario/contracts/asset-transfer-ts/asset-transfer-basic.tgz
cd ${ROOT_DIR}/playbooks/fabric-test-network
export IBP_ANSIBLE_LOG_FILENAME=ansible_debug.log

cat > cc-vars.yml <<EOF
---
smart_contract_name: "asset-transfer"
smart_contract_version: "1.0.0"
smart_contract_sequence: 1
smart_contract_package: $ROOT_DIR/ibp-fabric-toolchain-demo-scenario/contracts/asset-transfer-ts/asset-transfer-basic.tgz
EOF

set -x
ansible-playbook 19-install-and-approve-chaincode.yml --extra-vars @auth-vars.yml --extra-vars @cc-vars.yml
ansible-playbook 20-install-and-approve-chaincode.yml --extra-vars @auth-vars.yml --extra-vars @cc-vars.yml
ansible-playbook 21-commit-chaincode.yml --extra-vars @auth-vars.yml --extra-vars @cc-vars.yml
ansible-playbook 22-register-application.yml --extra-vars @auth-vars.yml --extra-vars @cc-vars.yml
ansible-playbook 23-register-application.yml --extra-vars @auth-vars.yml --extra-vars @cc-vars.yml
set +x