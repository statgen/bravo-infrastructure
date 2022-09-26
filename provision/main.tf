# default instance of provider
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = "test"
      Terraform = "true"
      Project = "bravo"
    }
  }
}

# us-east-1 provider instance when it is required to use this region
provider "aws" {
  region = "us-east-1"
  alias = "useast1"
  default_tags {
    tags = {
      Environment = "test"
      Terraform = "true"
      Project = "bravo"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "domain" {
  name = var.app_domain
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_acm_certificate" "subdomain" {
  domain = var.app_domain
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"

  name = "main-vpc"
  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.available.names
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, var.private_subnet_count)
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, var.public_subnet_count)

  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true

  private_subnet_ipv6_prefixes = slice(range(10,17), 0, var.public_subnet_count)
  public_subnet_ipv6_prefixes  = slice(range(0,7), 0, var.public_subnet_count)

  public_subnet_assign_ipv6_address_on_creation  = true
  private_subnet_assign_ipv6_address_on_creation = false

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_vpn_gateway = var.enable_vpn_gateway
}

module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.2.0"

  name        = "web-sg"
  description = "Security group for web-servers to communicate with load balancer."
  vpc_id      = module.vpc.vpc_id

  computed_egress_with_source_security_group_id = [
    { 
      rule                     = "http-8080-tcp",
      source_security_group_id = module.lb_security_group.security_group_id 
    },
  ]
  number_of_computed_egress_with_source_security_group_id = 1

  computed_ingress_with_source_security_group_id = [
    { 
      rule                     = "http-8080-tcp",
      source_security_group_id = module.lb_security_group.security_group_id 
    },
  ]
  number_of_computed_ingress_with_source_security_group_id = 1
}

module "updates_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.2.0"

  name        = "updates-sg"
  description = "Security group to allow https egress."
  vpc_id      = module.vpc.vpc_id

  # Permit http & https so apt and git can fetch dependencies.
  egress_rules = ["http-80-tcp", "https-443-tcp"]
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_ipv6_cidr_blocks = ["::/0"]
}

module "lb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.2.0"

  name        = "lb-sg"
  description = "Security group for load balancer with HTTP ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules = ["http-80-tcp", "http-8080-tcp", "https-443-tcp", "https-8443-tcp"]
  egress_rules = ["http-80-tcp", "http-8080-tcp", "https-443-tcp", "https-8443-tcp"]
}

module "github_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.2.0"

  name        = "git-sg"
  description = "Security group for development with Github repo"
  vpc_id      = module.vpc.vpc_id

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_ipv6_cidr_blocks = ["::/0"]

  egress_with_cidr_blocks = [
    {
      from_port = 9418
      to_port = 9418
      protocol = "tcp"
      description = "github ssh port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule = "ssh-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_with_ipv6_cidr_blocks = [
    {
      from_port = 9418
      to_port = 9418
      protocol = "tcp"
      description = "github ssh port"
      cidr_blocks = "::/0"
    },
    {
      rule = "ssh-tcp"
      cidr_blocks = "::/0"
    }
  ]
}

resource "random_pet" "app" {
  length    = 2
  separator = "-"
}

resource "aws_lb" "app" {
  name               = "main-app-${random_pet.app.id}-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [module.lb_security_group.security_group_id]
}

resource "aws_lb_listener" "front_insecure" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_server.arn
  }
}

resource "aws_lb_listener" "front_secure" {
  load_balancer_arn = aws_lb.app.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.subdomain.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_server.arn
  }
}

resource "aws_route53_record" "bravo" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = "bravo.${data.aws_route53_zone.domain.name}"
  type    = "A"
  alias {
    name    = aws_lb.app.dns_name
    zone_id = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}
