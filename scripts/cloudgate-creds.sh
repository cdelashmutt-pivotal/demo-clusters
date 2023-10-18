#!/bin/bash

CG_ID=$(jq -r '.id' ~/.cloudgate/api_client.json)
CG_SECRET=$(jq -r '.secret' ~/.cloudgate/api_client.json)
CG_ACCOUNT_NAME="US1920102 WORLDWIDE SALES cdelashmutt"

CG_ACCESS_TOKEN=$(curl -s --location --request POST 'https://api.console.cloudgate.vmware.com/authn/token' \
    --user "$CG_ID:$CG_SECRET" \
    --header 'Content-Type: application/json' \
    --data-raw '{ "grant_type": "client_credentials" }' | jq -r '.access_token')

CG_ACCOUNTS_JSON=$(curl -s --location --request GET 'https://api.console.cloudgate.vmware.com/v2/accounts/resources' \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $CG_ACCESS_TOKEN")

CG_RESOURCE_PATH=$(jq -r '.data[]| select(.name == "US1920102 WORLDWIDE SALES cdelashmutt") | .resourcePath' <<< "$CG_ACCOUNTS_JSON")

echo $CG_MASTER_ACCOUNT_ID
echo $CG_ORG_ACCOUNT_ID

CG_SESSION_JSON=$(curl -s --location --request POST 'https://api.console.cloudgate.vmware.com/v2/access/sessions' \
--header 'Content-Type: application/json' \
--header "Authorization: Bearer $CG_ACCESS_TOKEN" \
-d '{"resourcePath": "'"$CG_RESOURCE_PATH"'","role": "PowerUser","ttl": 43200}')

export AWS_ACCESS_KEY_ID=$(jq -r '.credential.accessKeyId' <<< "$CG_SESSION_JSON") \
  AWS_SECRET_ACCESS_KEY=$(jq -r '.credential.secretAccessKey' <<< "$CG_SESSION_JSON") \
  AWS_SESSION_TOKEN=$(jq -r '.credential.sessionToken' <<< "$CG_SESSION_JSON")

echo Session variables set, navigate to the following URL if you need Web Console access:
echo $(jq -r '.consoleAccessUrl' <<< "$CG_SESSION_JSON")