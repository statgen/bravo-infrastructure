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
  description = "AMI to use for the application"
  type        = string
  default     = "false"
}

variable "app_volume_size" {
  description = "Size in Gb of attached volume for application"
  type        = number
  default     = 100
}

variable "db_volume_size" {
  description = "Size in Gb of attached volume for database"
  type        = number
  default     = 30
}

variable "app_domain" {
  description = "Hosted Zone name covering the api and ui domains."
  type        = string
  default     = "false"
}

variable "api_domain" {
  description = "Domain to direct to load balancer."
  type        = string
  default     = "false"
}

variable "ui_domain" {
  description = "Domain to direct to static site (UI)."
  type        = string
  default     = "false"
}

variable "app_inst_type" {
  description = "Instance type for application"
  type        = string
  default     = "t3a.large"
}

variable "db_inst_type" {
  description = "Instance type for database"
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
