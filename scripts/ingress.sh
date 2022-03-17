#!/bin/bash

CLUSTER_ID=c56subjl04sjs13traf0
    
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
    kubectl create -f ibm-ingress-deploy-config.yml
    ibmcloud ks ingress alb update -c ${CLUSTER_ID}