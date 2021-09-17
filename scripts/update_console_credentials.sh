#!/usr/bin/env bash
set -ex -u -o pipefail
ROOTDIR=$(cd "$(dirname "$0")/.." && pwd)

: ${CONSOLE_PASSWORD:="new42day"}
: ${PROJECT_NAME_VALUE:="hlf-network"}

# Build authentication variables required for the new Console (must change default password)
echo "Generating authentication vars for new console"
IBP_CONSOLE=$(kubectl get routes/ibm-hlfsupport-console-console --namespace ${PROJECT_NAME_VALUE} -o=json | jq .spec.host | tr -d '"')


# Basic auth passed here must match that in the generated ansible playbooks. You have been warned.
AUTH=$(curl -X POST \
 https://$IBP_CONSOLE:443/ak/api/v2/permissions/keys \
 -u nobody@ibm.com:${CONSOLE_PASSWORD} \
 -k \
 -H 'Content-Type: application/json' \
 -d '{
     "roles": ["writer", "manager"],
     "description": "newkey"
     }')

KEY=$(echo $AUTH | jq .api_key | tr -d '"')
SECRET=$(echo $AUTH | jq .api_secret | tr -d '"')

echo "Writing authentication file for Ansible based network building"
cat << EOF > $ROOTDIR/playbooks/fabric-test-network/auth-vars.yml
api_key: $KEY
api_endpoint: https://$IBP_CONSOLE
api_authtype: basic
api_secret: $SECRET
EOF

