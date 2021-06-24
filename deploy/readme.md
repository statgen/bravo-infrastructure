# BRAVO Deployment with Ansible

Three roles:
- Install components & configure.
- Download, unpack, and load backing data.
- Run applications as systemd services.

## Dependencies
Requires community.mongodb collection
```
ansible-galaxy collection install -r requirements.yml
```

## Run Deployment
The `../make_ansible_support_files.sh` script emits a command that will run ansible.
It assumes the terraform statefile exists in `provision/` after terrform has run.
The command emitted should be:
```
ansible-playbook --ssh-common-args='-F ../deploy-ssh-config' -i '../deploy-inventory' playbook.yml
```

The command is meant to be run from the `deploy/` directory.

## Data Loading 
The data loading step is expensive.
The role creates lock files to indicate that it's already been run.
This facilitates a hack to avoid trying to figure out if data needs to be reloaded.
