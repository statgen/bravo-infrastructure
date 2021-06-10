# Provisioning BRAVO Demo on AWS
Creates an application load balancer for SSL termination 

## Dependencies
- AWS Account
- Terraform configured for use with your AWS account
- Existing Domain registered with Route53 e.g. example.com
- A star cert (\*.example.com) for that domain, or cert for bravo.example.com
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

```sh
terraform apply
```

