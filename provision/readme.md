# Provisioning BRAVO Demo on AWS
Creates an application load balancer for SSL termination 

## Dependencies
- AWS Account
- Terraform configured for use with your AWS account
- Existing Domain registered with Route53 e.g. example.com
- A cert for that domain that covers bravo subdomain in SANs.
    e.g cert for example.com having *.example.com or bravo.example.com in SAN list.
- Backing vignette data in an S3 bucket.

## Required Terraform Variables
- Name of key pair to use to access EC2 instances.
- Name of hosted zone under which `bravo` subdomain record will be created.
- Name of bucket that contains vignette backing data.

Env vars as convenience method for development
```sh
export TF_VAR_key_pair_name=my-example-aws-key
export TF_VAR_app_domain=example.com
export TF_VAR_bucket_name=my-example-data
```

## Development debugging simple httpd server
The `init-script.sh` includes a simple httpd systemd service to indicate test port 8080. 
Enable running this init script as the instance user data with

```sh
terraform apply -var='install_httpd=true'
```

Don't use this when you will be deploying an application.
You'll get an error because the port to bind to is already in use.

