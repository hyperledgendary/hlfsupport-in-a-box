#!/usr/bin/env bash
set -ex -u -o pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

IMPORT_EXPORT_REQUIRED=0
function usage {
    echo "Usage: build_network.sh [-i] [build|destroy]" 1>&2
    exit 1
}
while getopts ":i" OPT; do
    case ${OPT} in
        i)
            IMPORT_EXPORT_REQUIRED=1
            ;;
        \?)
            usage
            ;;
    esac
done
shift $((OPTIND -1))
COMMAND=$1

cd ${ROOT_DIR}/playbooks/fabric-test-network
export IBP_ANSIBLE_LOG_FILENAME=ansible_debug.log
if [ "${COMMAND}" = "build" ]; then
    set -x
    ansible-playbook 01-create-ordering-organization-components.yml --extra-vars @auth-vars.yml
    ansible-playbook 02-create-endorsing-organization-components.yml  --extra-vars @auth-vars.yml
    if [ "${IMPORT_EXPORT_REQUIRED}" = "1" ]; then
        ansible-playbook 03-export-organization.yml  --extra-vars @auth-vars.yml
        ansible-playbook 04-import-organization.yml  --extra-vars @auth-vars.yml
    fi
    ansible-playbook 05-enable-capabilities.yml  --extra-vars @auth-vars.yml
    ansible-playbook 06-add-organization-to-consortium.yml  --extra-vars @auth-vars.yml
    if [ "${IMPORT_EXPORT_REQUIRED}" = "1" ]; then
        ansible-playbook 07-export-ordering-service.yml  --extra-vars @auth-vars.yml
        ansible-playbook 08-import-ordering-service.yml  --extra-vars @auth-vars.yml
    fi
    ansible-playbook 09-create-channel.yml  --extra-vars @auth-vars.yml
    ansible-playbook 10-join-peer-to-channel.yml  --extra-vars @auth-vars.yml
    ansible-playbook 11-add-anchor-peer-to-channel.yml  --extra-vars @auth-vars.yml
    set +x
elif [ "${COMMAND}" = "destroy" ]; then
    set -x
    if [ "${IMPORT_EXPORT_REQUIRED}" = "1" ]; then
        ansible-playbook 97-delete-endorsing-organization-components.yml  --extra-vars '{"import_export_used":true}'  --extra-vars @auth-vars.yml
        ansible-playbook 99-delete-ordering-organization-components.yml  --extra-vars '{"import_export_used":true}'  --extra-vars @auth-vars.yml
    else
        ansible-playbook 97-delete-endorsing-organization-components.yml  --extra-vars @auth-vars.yml
        ansible-playbook 99-delete-ordering-organization-components.yml  --extra-vars @auth-vars.yml
    fi
    set +x
else
    usage
fi