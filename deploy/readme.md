# BRAVO Deployment with Ansible

Three roles:
- Install components & configure.
- Download, unpack, and load backing data.
- Run applications as systemd services.

## Data Loading 
The data loading step is expensive.
The role creates a lock file to indicate that it's already been run.
This facilitates a hack to avoid trying to figure out if data needs to be reloaded.
