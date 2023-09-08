#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cluster_name=$1
region=us-east-2
credential=cdd-gloudgate

function on_exit() {
  dir=$1
  rm -rf $dir
}


# move to new group to get rid of kustomization
tmp_d=$(mktemp -d)
trap "on_exit $tmp_d" EXIT
tmp_f="$tmp_d/cluster-update.yaml"
tanzu tmc ekscluster get $cluster_name -r $region -c $credential | yq -e '.spec.clusterGroupName="cdelashmutt-todelete"' > $tmp_f
tanzu tmc ekscluster update $cluster_name -f $tmp_f

# delete and wait for app to go away
kubectl delete apps.kappctrl.k14s.io/tmc-cd-bootstrap -n tanzu-continuousdelivery-resources
kubectl wait apps.kappctrl.k14s.io/tmc-cd-bootstrap -n tanzu-continuousdelivery-resources --for=delete  --timeout=900s
deleted=$?
if [ "$deleted" -ne 0 ]; then
  "echo Timed out waiting for tmc-cd-bootstrap app to be deleted."
  exit -1
fi

# remove IAM Roles for cluster
$SCRIPT_DIR/eks-irsa.sh delete $1 external-dns external-dns
$SCRIPT_DIR/eks-irsa.sh delete $1 cert-manager cert-manager
$SCRIPT_DIR/eks-irsa.sh delete $1 tanzu-continuousdelivery-resources eso-aws
$SCRIPT_DIR/eks-irsa.sh delete $1 tap-gui tap-gui

# delete cluster
tanzu tmc ekscluster delete $cluster_name -r $region -c $credential