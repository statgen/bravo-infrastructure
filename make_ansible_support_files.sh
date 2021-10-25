#!/usr/bin/env bash

# Create ansible inventory and ssh config from terraform state.



# Get json output from terraform statefile
TERRAFORM_JSON=$(terraform output -json -state=provision/terraform.tfstate)

# Parse json into env variables
BUCKET_NAME=$(echo "${TERRAFORM_JSON}" | jq -r '.bucket_name.value')
PET_NAME=$(echo "${TERRAFORM_JSON}" | jq -r '.pet_name.value')
BASTION_PUBLIC_IP=$(echo "${TERRAFORM_JSON}" | jq -r '.bastion_public_ip.value')
APP_SERVER_PRIVATE_IP=$(echo "${TERRAFORM_JSON}" | jq -r '.app_server_private_ip.value[0]')

# Write ssh config
cat << SSHDOC > deploy-ssh-config
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
cat << INVENTORYDOC > deploy-inventory
[bastion]
${PET_NAME}-bastion

[app]
${PET_NAME}-app data_bucket=${BUCKET_NAME}

[mongo]
${PET_NAME}-app
INVENTORYDOC

echo -e "To use from deploy directory:\n\
ansible-playbook --ssh-common-args='-F ../deploy-ssh-config' -i '../deploy-inventory' playbook.yml\n"
