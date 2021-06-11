#!/bin/sh

terraform output -json |\
  jq --raw-output '.bastion_public_ip.value' |\
  awk '{print "ssh -A ec2-user@"$1}'

echo ""

terraform output -json |\
  jq --join-output '.bastion_public_ip.value, " ", .app_server_private_ip.value[0]' |\
  awk '{print "ssh -A -J ec2-user@"$1 " ubuntu@"$2}'

echo ""

terraform output -json |\
  jq --join-output '.bastion_public_ip.value, " ", .app_server_private_ip.value[0]' |\
  awk '{print "scp -o \"ProxyJump ec2-user@"$1 "\" SRCFILE ubuntu@"$2":/home/ubuntu/DEST"}'
