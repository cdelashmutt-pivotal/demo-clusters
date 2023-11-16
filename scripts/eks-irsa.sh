#!/bin/bash

operation=$1
cluster_name=$2
service_namespace=$3
service_name=$4


oidc_provider=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text)
oidc_provider=${oidc_provider/#https\:\/\/}

account_id=$(aws sts get-caller-identity --query "Account" --output text)

policy_arn=$(aws iam list-policies --query "Policies[?PolicyName=='$service_name'].Arn" --output text)

eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve

role_name=$cluster_name-$service_namespace-$service_name
if [ "create" == $operation ]; then
    aws iam create-role --role-name $role_name --no-cli-pager --assume-role-policy-document file://<(cat << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${account_id}:oidc-provider/${oidc_provider}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${oidc_provider}:aud": "sts.amazonaws.com",
                    "${oidc_provider}:sub": "system:serviceaccount:${service_namespace}:${service_name}"
                }
            }
        }
    ]
}
EOF
)

    aws iam attach-role-policy --role-name $role_name --policy-arn arn:aws:iam::${account_id}:policy/$service_name
elif [ "delete" == $operation ]; then
    aws iam detach-role-policy --role-name $role_name --policy-arn arn:aws:iam::${account_id}:policy/$service_name
    aws iam delete-role --role-name $role_name
fi