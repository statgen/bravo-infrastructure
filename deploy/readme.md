# BRAVO Deployment with Ansible

Three roles:
- Install components & configure.
- Download, unpack, and load backing data.
- Run applications as systemd services.

## Dependencies
- Requires community.mongodb collection
    ```
    ansible-galaxy collection install -r requirements.yml
    ```
- Requires `bravo_vignette_data.tar.bz2` in an accessible S3 bucket.

## Run Deployment
The `../make_ansible_support_files.sh` script emits a command that will run ansible.
It assumes the terraform statefile exists in `provision/` after terrform has run.
The command emitted is meant to be run from the `deploy/` directory:
```
ansible-playbook --ssh-common-args='-F ../deploy-ssh-config' -i '../deploy-inventory' playbook.yml
```

The group var that might need to be changed is the `data_bucket`.  Use `-e 'data_bucket=your_bucket'`

## Data Loading 
The data loading step is expensive.
The role creates lock files to indicate that it's already been run.
This facilitates a hack to avoid trying to figure out if data needs to be reloaded.

## Auth Configuration
Configuration is expected to be in `group_vars/app/auth.yml`
```yml
---
gauth_client_id: "yourcliendid"
gauth_client_secret: "yourclientsecret"
```
When absent, the application config will leave values empty and set `DISABLE_LOGIN` to `true`.
