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
: ${PRODUCTION_DOCKER_IMAGES:=1}
: ${PRODUCT_VERSION:=1.0.0}
: ${OCP_TOKEN:=""}
: ${CONSOLE_PASSWORD:="new42day"}
: ${PROJECT_NAME_VALUE:="hlf-network"}
: ${CLUSTER_TYPE:="ocp"}

###
# Ansible playbook installation of CRD and Operator/Console
###
if [ $CLUSTER_TYPE == "ocp" ]; then
  # To login 
  if [ -z $OCP_TOKEN ]; then
    # pasword and user id login
    oc login ${OCP_URL} --password ${OCP_PASSWORD} --username ${OCP_USERNAME} --insecure-skip-tls-verify=true
  else
    oc login --token=${OCP_TOKEN} --server=${OCP_TOKEN_SERVER}
  fi
else 
  echo "Using IBM IKS Cluster"
  kubectl config current-context
  CLUSTER_ID=$(kubectl config current-context | cut -f2 -d'/')

fi

# Gererate playbooks (latest-crds.yml, latest-console.yml)
echo "Generating Ansible playbooks"
if [ $PRODUCTION_DOCKER_IMAGES == "1" ]; then
	$ROOTDIR/scripts/generate_hlfsupport_playbooks.sh
else
	$ROOTDIR/scripts/generate_hlfsupport_dev_playbooks.sh
fi

# IKS requires the Ingress Controller to be setup to support SSL Passthrough
# See https://cloud.ibm.com/docs/blockchain-sw-252?topic=blockchain-sw-252-deploy-k8#console-deploy-k8-iks-considerations
if [ $CLUSTER_TYPE == "iks" ]; then
  echo "Attempting to set the Ingress Controller to support SSL Passthrough"
  JSON='{"enableSslPassthrough":"true", "ingressClass":"nginx","replicas":1}'
  DATA=$(ibmcloud ks alb ls -c ${CLUSTER_ID} --output json | jq --raw-output '"\(.alb[].albID): JSONHERE"' ) 
  DATA=$(echo $DATA | sed "s/JSONHERE/'${JSON}'\n/g" )
  cat > ibm-ingress-deploy-config.yml <<EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
 name: ibm-ingress-deploy-config
 namespace: kube-system
data:
 ${DATA}
EOF
    cat ibm-ingress-deploy-config.yml
    kubectl apply -f ibm-ingress-deploy-config.yml
    ibmcloud ks ingress alb update -c ${CLUSTER_ID}
fi

# Install CRD and IBP Console
echo "Installing IBP Custom Resource Definition and Console"

# Provide logs on any problems regardless of whether debug is 0 or 1.
export IBP_ANSIBLE_LOG_FILENAME=ansible_console_debug.log

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
if [ $CLUSTER_TYPE == "iks" ]; then
  IBP_CONSOLE=$(kubectl -n ${PROJECT_NAME_VALUE} get ingress -o json | jq ".items[0].spec.rules[0].host" -r)
else
  IBP_CONSOLE=$(kubectl get routes/hlf-console --namespace ${PROJECT_NAME_VALUE} -o=json | jq .spec.host | tr -d '"')
fi

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

cat $ROOTDIR/playbooks/fabric-test-network/auth-vars.yml