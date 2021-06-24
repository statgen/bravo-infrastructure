# Bravo Example on AWS
Provision infrastructure and deploy BRAVO applications. 

To that end, this project is partitioned into two parts.
The first provisions infrastructure on AWS on which to run the applications.
The second is an ansible script to deploy and start the application.

## Provision Infrastrucutre on AWS
Terraform config derived from 
[this Hashicorp tutorial](https://learn.hashicorp.com/tutorials/terraform/blue-green-canary-tests-deployments)

See [Provisioning readme](provision/readme.md).

## Deploy Applications
Ansible playbook to install, configure, load data, and run BRAVO's components.

See [Deployment readme](deploy/readme.md).

## Use

```sh 
# Script to export my TF_VARs
source my-terraform-env-vars.sh

# Do provisioning
cd provision
terraform apply

# (Optional) print convenient ssh commands for bastion or app server. 
./print_ssh_cmd.sh

# Create Ansible config from terraform state
cd ..
./make_ansible_support_files.sh

# Do deployment
cd deploy
ansible-playbook --ssh-common-args='-F ../deploy-ssh-config' -i '../deploy-inventory' playbook.yml
```


