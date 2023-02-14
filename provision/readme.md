# Provisioning BRAVO Demo on AWS
Creates an application load balancer for SSL termination 

## Dependencies
- AWS Account
- Terraform configured for use with your AWS account
- Existing Domain registered with Route53 e.g. example.com
- A cert for that domain that with a SAN that covers bravo subdomain in SANs.
    - Expected cert name is the top level name e.g. `example.com`
    - e.g Cert with name `example.com` having `*.example.com` or `bravo.example.com` in SAN list.
- Backing vignette data in an S3 bucket.
    - Available from: ftp://share.sph.umich.edu/bravo/bravo_vignette_data.tar.bz2
    - Backing data needs to be present in bucket.

## Required Terraform Variables
- Name of key pair to use to access EC2 instances.
- Name of hosted zone under which `bravo` subdomain record will be created.
- Name of bucket that will contain vignette backing data.

Env vars as convenience method for development
```sh
export TF_VAR_key_pair_name=my-example-aws-key
export TF_VAR_app_domain=example.com
export TF_VAR_bucket_name=my-example-data
# Specify which AWS credentials profile to use.
export AWS_PROFILE=statgen
```

## Development debugging simple httpd server
The `init-script.sh` includes a simple httpd systemd service to indicate test port 8080. 
Enable running this init script as the instance user data with

```sh
terraform apply -var='install_httpd=true'
```

Don't use this when you will be deploying an application (i.e. bravo-api).
You'll get an error because the port to bind to is already in use.

