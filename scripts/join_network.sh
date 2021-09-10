#!/usr/bin/env bash
set -e
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

IMPORT_EXPORT_REQUIRED=0
function usage {
    echo "Usage: join_network.sh [-i] [join|destroy]" 1>&2
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

if [ "${COMMAND}" = "join" ]; then
    set -x
    ansible-playbook 12-create-endorsing-organization-components.yml --extra-vars @auth-vars.yml
    if [ "${IMPORT_EXPORT_REQUIRED}" = "1" ]; then
        ansible-playbook 13-export-organization.yml --extra-vars @auth-vars.yml
        ansible-playbook 14-import-organization.yml --extra-vars @auth-vars.yml
    fi
    ansible-playbook 15-add-organization-to-channel.yml --extra-vars @auth-vars.yml
    if [ "${IMPORT_EXPORT_REQUIRED}" = "1" ]; then
        ansible-playbook 16-import-ordering-service.yml --extra-vars @auth-vars.yml
    fi
    ansible-playbook 17-join-peer-to-channel.yml --extra-vars @auth-vars.yml
    ansible-playbook 18-add-anchor-peer-to-channel.yml --extra-vars @auth-vars.yml
    set +x
elif [ "${COMMAND}" = "destroy" ]; then
    set -x
    if [ "${IMPORT_EXPORT_REQUIRED}" = "1" ]; then
        ansible-playbook 97-delete-endorsing-organization-components.yml --extra-vars '{"import_export_used":true}' --extra-vars @auth-vars.yml
        ansible-playbook 98-delete-endorsing-organization-components.yml --extra-vars '{"import_export_used":true}'   --extra-vars @auth-vars.yml
        ansible-playbook 99-delete-ordering-organization-components.yml --extra-vars '{"import_export_used":true}' --extra-vars @auth-vars.yml
    else
        ansible-playbook 97-delete-endorsing-organization-components.yml --extra-vars @auth-vars.yml
        ansible-playbook 98-delete-endorsing-organization-components.yml --extra-vars @auth-vars.yml
        ansible-playbook 99-delete-ordering-organization-components.yml --extra-vars @auth-vars.yml
    fi
    set +x
else
    usage
fi