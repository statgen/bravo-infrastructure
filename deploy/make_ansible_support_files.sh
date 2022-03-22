#!/usr/bin/env bash
# Get plan outputs from Terraform Cloud and build files to facilitate running ansible.
# Builds
#  - ssh config
#  - ansible inventory

# Get workspace name from env or use default
WORKSPACE_NAME="${WORKSPACE_NAME:=bravo-ci-staging}"

# Get terraform cloud token from credentials file 
JQ_EXP='."credentials"."app.terraform.io"."token"'
TOKEN=$(jq -r ${JQ_EXP} < ~/.terraform.d/credentials.tfrc.json)

# Get Workspace Id from Name
URL_ID="https://app.terraform.io/api/v2/organizations/statgen/workspaces?search%5Bname%5D=${WORKSPACE_NAME}"
WORKSPACE_ID=$(curl -s \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  "${URL_ID}" |\
  jq -r '.data[0].id')

# Get json output from terraform workspace outputs
#   Munge to similar format as terraform output -json  
URL_OUTS="https://app.terraform.io/api/v2/workspaces/$WORKSPACE_ID/current-state-version?include=outputs"
TERRAFORM_JSON=$(curl -s \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  "${URL_OUTS}" |\
  jq '.included | map( {(.attributes.name) : .attributes.value}) | add')

# Parse json into env variables
BUCKET_NAME=$(echo "${TERRAFORM_JSON}" | jq -r '.bucket_name')
SITE_BUCKET=$(echo "${TERRAFORM_JSON}" | jq -r '.static_site_bucket')
PET_NAME=$(echo "${TERRAFORM_JSON}" | jq -r '.pet_name')
BASTION_PUBLIC_IP=$(echo "${TERRAFORM_JSON}" | jq -r '.bastion_public_ip')
APP_SERVER_PRIVATE_IP=$(echo "${TERRAFORM_JSON}" | jq -r '.app_server_private_ip[0]')

echo "${TERRAFORM_JSON}"

# Make inv dir for inventory and ssh config
mkdir -p inv

# Write ssh config
cat << SSHDOC > inv/deploy-ssh-config
Host ${PET_NAME}-bastion
  User ec2-user
  Hostname ${BASTION_PUBLIC_IP}
  Port 22

Host ${PET_NAME}-app
  User ubuntu
  Hostname ${APP_SERVER_PRIVATE_IP}
  ProxyJump ${PET_NAME}-bastion
  Port 22
SSHDOC

# write inventory
cat << INVENTORYDOC > inv/deploy-inventory
[bastion]
${PET_NAME}-bastion
site_bucket=${SITE_BUCKET}

[app]
${PET_NAME}-app data_bucket=${BUCKET_NAME}

[mongo]
${PET_NAME}-app
INVENTORYDOC

echo -e "# Run ansible playbook\n\
ansible-playbook --ssh-common-args='-F inv/deploy-ssh-config' -i 'inv/deploy-inventory' playbook.yml\n"
