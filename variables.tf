variable "region" {
  description = "The region Terraform deploys your instances"
  type        = string
  default     = "us-east-2"
}

variable "env_tag" {
  description = "The environment tag to apply to aws resources."
  type        = string
  default     = "test"
}

variable "app_ami" {
  description = "AMI to use for the application vm. Leave blank to lookup most recent ami."
  type        = string
  default     = ""
}

variable "db_ami" {
  description = "AMI to use for the mongo vm. Should be ARM architecture. Leave blank to lookup most recent ami."
  type        = string
  default     = ""
}

variable "app_volume_size" {
  description = "Size in Gb of attached volume for application"
  type        = number
  default     = 100
}

variable "app_root_volume_size" {
  description = "Size in Gb of volume for app server os"
  type        = number
  default     = 8
}

variable "db_volume_size" {
  description = "Size in Gb of attached volume for database"
  type        = number
  default     = 30
}

variable "api_cert_domain" {
  description = "Name of domain of ACM cert covering the api_domain."
  type        = string
  default     = "false"
}

variable "ui_cert_domain" {
  description = "Name of domain of ACM cert covering the ui_domain."
  type        = string
  default     = "false"
}

variable "ui_cert_arn" {
  description = "Optional ARN of cert covering the ui_domain to override domain cert lookup."
  type        = string
  default     = null
}

variable "api_domain" {
  description = "Domain to direct to load balancer."
  type        = string
  default     = "false"
}

variable "ui_domain_aws" {
  description = "Domains to direct to static site (UI)."
  type        = string
  default     = "genome-bravo.org"
}

variable "ui_domain_ext" {
  description = "Domains to direct to static site (UI)."
  type        = list(string)
  default     = []
}

variable "app_inst_type" {
  description = "Instance type for application"
  type        = string
  default     = "t3a.large"
}

variable "db_inst_type" {
  description = "Instance type for database. Should be ARM architecture."
  type        = string
  default     = "r7g.medium"
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "key_pair_name" {
  description = "Name of existing keypair to use for bastion host"
  type        = string
}

variable "bucket_name" {
  description = "Name of bucket backing vignette data is stored in"
  type        = string
}

variable "enable_vpn_gateway" {
  description = "Enable a VPN gateway in your VPC."
  type        = bool
  default     = false
}

variable "public_subnet_count" {
  description = "Number of public subnets."
  type        = number
  default     = 2
}

variable "private_subnet_count" {
  description = "Number of private subnets."
  type        = number
  default     = 2
}

variable "public_subnet_cidr_blocks" {
  description = "Available cidr blocks for public subnets"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24",
    "10.0.7.0/24",
    "10.0.8.0/24",
  ]
}

variable "private_subnet_cidr_blocks" {
  description = "Available cidr blocks for private subnets"
  type        = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24",
    "10.0.104.0/24",
    "10.0.105.0/24",
    "10.0.106.0/24",
    "10.0.107.0/24",
    "10.0.108.0/24",
  ]
}

variable "enable_app_server_env" {
  description = "Enable app_server environment"
  type        = bool
  default     = true
}

variable "app_server_instance_count" {
  description = "Number of instances in app_server environment"
  type        = number
  default     = 1
}

variable "install_httpd" {
  description = "Install simple httpd to debug provisioning"
  type        = bool
  default     = false
}
