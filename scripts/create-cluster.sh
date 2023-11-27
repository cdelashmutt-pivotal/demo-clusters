#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cluster_name=$1
region=us-east-2
credential=cdd-gloudgate

tanzu tmc ekscluster create -v <( cat << EOF
CredentialName: ${credential}
Region: ${region}
Name: ${cluster_name}
ClusterGroup: cdelashmutt
LoggingApiServer: false
LoggingAudit: false
LoggingAuthenticator: false
LoggingControllerManager: false
LoggingScheduler: false
ControlplaneRoleArn: arn:aws:iam::537807987484:role/control-plane.4811654495416222692.eks.tmc.cloud.vmware.com
Version: 1.27
EnablePrivateAccess: true
EnablePublicAccess: true
PublicAccessCidrs: 0.0.0.0/0
SubnetIds: subnet-0cb140d8fc3fba9a1,subnet-008d9a057277c2972,subnet-09b9dd52b0ff1de87,subnet-0227daac459dcf721
EOF
)

tanzu tmc ekscluster nodepool create -v <(cat << EOF
CredentialName: ${credential}
EksClusterName: ${cluster_name}
Name: pool1
Region: ${region}
AmiType: BOTTLEROCKET_x86_64
InstanceTypes: t3a.xlarge
RootDiskSize: 100
RoleArn: arn:aws:iam::537807987484:role/worker.4811654495416222692.eks.tmc.cloud.vmware.com
DesiredSize: 4
MaxSize: 8
MinSize: 1
SubnetIds: subnet-0cb140d8fc3fba9a1,subnet-008d9a057277c2972,subnet-09b9dd52b0ff1de87,subnet-0227daac459dcf721
MaxUnavailableNodes: 1
EOF
)

current_status_json=$(tanzu tmc ekscluster get ${cluster_name} -r us-east-2 -c cdd-gloudgate -o json)
current_status=$(jq -r ".status.phase" <<< $current_status_json)
while [[ $current_status != "READY" ]]; do
  echo "------"
  echo "Status: $current_status"
  jq -r '.status.conditions[] | .type + if .message then ": "+.message else ""  end' <<< $current_status_json
  echo "------"

  sleep 5
  current_status_json=$(tanzu tmc ekscluster get ${cluster_name} -r us-east-2 -c cdd-gloudgate -o json)
  current_status=$(jq -r ".status.phase" <<< $current_status_json)
done

echo "------"
echo "Status: $current_status"
jq -r '.status.conditions[] | .type + if .message then ": "+.message else ""  end' <<< $current_status_json
echo "------"

export AWS_REGION=$region
$SCRIPT_DIR/eks-irsa.sh create $1 external-dns external-dns
$SCRIPT_DIR/eks-irsa.sh create $1 cert-manager cert-manager
$SCRIPT_DIR/eks-irsa.sh create $1 tanzu-continuousdelivery-resources eso-aws
$SCRIPT_DIR/eks-irsa.sh create $1 tap-gui tap-gui