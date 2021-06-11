# Bravo Example on AWS
This project is partitioned into two parts.
The first provisions infrastructure on AWS on which to run the applications.
The second is an ansible script to deploy and start the application.

## Provision Infrastrucutre on AWS
Terraform config derived from 
[this Hashicorp tutorial](https://learn.hashicorp.com/tutorials/terraform/blue-green-canary-tests-deployments)

See [Provisioning readme](provision/readme.md).

## Deploy Applications
Ansible playbook to install, configure, load data, and run BRAVO's components.

See [Deployment readme](deploy/readme.md).
