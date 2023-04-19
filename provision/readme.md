# Provisioning BRAVO on AWS
This terraform project is designed to provision infrastructure that will run the BRAVO API and UI.
Major components created:

- EC2 instance running the API
- EC2 instance for running mongodb
- EBS mounts for API and mongo instances.
- Bucket for storing the Vue UI  
- Cloudfront distribution for serving out the UI.

Running this provisioner will incur charges to the associated AWS account.

## Dependencies

- AWS access key and access secret for deployment
- Terraform cloud project
- Existing Domain registered with Route53 e.g. example.com
- A cert for that domain that with a SAN that covers bravo subdomain in SANs.
    - Expected cert name is the top level name e.g. `example.com`
    - e.g Cert with name `example.com` having `*.example.com` in SAN list.
- Backing vignette data in an S3 bucket.
    - Available from: ftp://share.sph.umich.edu/bravo/bravo_vignette_data.tar.bz2
    - Backing data needs to be present in bucket.

## Required Terraform Variables
Terraform variables are stored in the terraform cloud project.
Full list of names and descriptions available there or in `variables.tf`.
Some of the important ones are:

- Name of key pair to use to access EC2 instances.
- Names of hosted zone domain, ui domain, api domain.
- Name of bucket that contains backing data.

## Development debugging simple httpd server
The `init-script.sh` includes a simple httpd systemd service to indicate test port 8080. 
Enable running this init script as the instance user data with

```sh
terraform apply -var='install_httpd=true'
```

Do NOT use this when you will be deploying the BRAVO API.
Deploy will fail because the port for the API to bind to is already in use.

## Provisioning: Stating or Production
This code base provisions for both the staging and production infrastructure.
See [managing workspaces](https://developer.hashicorp.com/terraform/cli/workspaces) for docs.
In short the relevant cli commands are:

- `terraform workspace list`
- `terraform workspace select`

**Make sure you are on the correct workspace**

With the correct tf cloud workspace selected, provision using as usual with:
```sh
terraform apply
```
