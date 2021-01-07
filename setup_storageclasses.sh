#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

git clone https://github.com/rook/rook.git
cd rook/cluster/examples/kubernetes/ceph
oc create -f crds.yaml
oc create -f common.yaml
oc create -f operator-openshift.yaml
oc create -f cluster.yaml
oc create -f ./csi/rbd/storageclass.yaml
oc create -f ./csi/rbd/pvc.yaml
oc create -f filesystem.yaml
oc create -f ./csi/cephfs/storageclass.yaml
oc create -f ./csi/cephfs/pvc.yaml
oc create -f toolbox.yaml
