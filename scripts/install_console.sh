#!/usr/bin/env bash
set -ex -u -o pipefail
ROOTDIR=$(cd "$(dirname "$0")/.." && pwd)

# Input Environment Variables:

# ocp-fyre - this is a fyre hosted OCP cluster - assuming that the login has already been completed and cluster targetted
# ocp      - OCP cluster on IBM Cloud
# iks      - IKS cluster on IBM Cloud

# These are required to be able to login in and target the the cluster  (ocp or iks only)
#   CLUSTER_API_KEY
#   CLUSTER_REGION
#   RESOURCE_GROUP

#   CLUSTER_INGRESS_HOSTNAME is also required for creating the playbooks

# If you are targetting the IBM Cloud staging
#  STAGING=1


# defensively define some defaults
: ${DEBUG:=0}
: ${PRODUCTION_DOCKER_IMAGES:=0}
: ${PRODUCT_VERSION:=1.0.0}
###
# Ansible playbook installation of CRD and Operator/Console
###

# Fyre is a pure OCP environment outside IBM Cloud, therefore no requirement
# To login 
if [ -z $OCP_TOKEN ]; then
  # pasword and user id login
  # OCP_PASSWORD=$(jq -r '.clusters[0].kubeadmin_password' "$ROOT_DIR/fyre/ocpdetails.json")
  oc login ${OCP_URL} --password ${OCP_PASSWORD} --username ${OCP_USERNAME} --insecure-skip-tls-verify=true
  export CLUSTER_INGRESS_HOSTNAME=apps.${FYRE_OCP_NAME:=nx02}.cp.fyre.ibm.com
else
  oc login --token=${OCP_TOKEN} --server=${OCP_TOKEN_SERVER}
fi

# Gererate playbooks (latest-crds.yml, latest-console.yml)
echo "Generating Ansible playbooks"
if [ $PRODUCTION_DOCKER_IMAGES == "1" ]; then
echo "not yet ready"
exit 1
 #./generate_prod_playbooks.sh	
else
	$ROOTDIR/scripts/generate_hlfsupport_dev_playbooks.sh
fi

# exit 0 
# Install CRD and IBP Console, use config in sourced export $KUBECONFIG
echo "Installing IBP Custom Resource Definition and Console"

# Provide logs on any problems regardless of whether debug is 0 or 1.
export IBP_ANSIBLE_LOG_FILENAME=ansible_debug.log

if [ $DEBUG == "0" ]; then
  ansible-playbook $ROOTDIR/playbooks/latest-crds.yml
  ansible-playbook $ROOTDIR/playbooks/latest-console.yml
else
  ansible-playbook $ROOTDIR/playbooks/latest-crds.yml -vvv
  ansible-playbook $ROOTDIR/playbooks/latest-console.yml -vvv
fi

echo "Sleeping to let cluster catch up with Console existence"
sleep 2m

# Build authentication variables required for the new Console (must change default password)
echo "Generating authentication vars for new console"
# if [ $CLUSTER_TYPE == "iks" ]; then
#   # IBP_CONSOLE=$(kubectl get ing/ibp-console --namespace openmarvin -o=json | jq .spec.rules[0].host | tr -d '"')
#   echo "not yet supported"
#   exit 1
# else
IBP_CONSOLE=$(kubectl get routes/ibm-hlfsupport-console-console --namespace marvin -o=json | jq .spec.host | tr -d '"')
# fi

# Basic auth passed here must match that in the generated ansible playbooks. You have been warned.
AUTH=$(curl -X POST \
 https://$IBP_CONSOLE:443/ak/api/v2/permissions/keys \
 -u nobody@ibm.com:passw0rd \
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

