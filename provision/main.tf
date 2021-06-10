provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "domain" {
  name = "contrapaganza.com"
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

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.0.0"

  name = "main-vpc"
  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.available.names
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, var.private_subnet_count)
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, var.public_subnet_count)

  enable_nat_gateway = false
  enable_vpn_gateway = var.enable_vpn_gateway
}

module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.2.0"

  name        = "web-sg"
  description = "Security group for web-servers with HTTP ports open within VPC"
  vpc_id      = module.vpc.vpc_id

  #ingress_cidr_blocks = module.vpc.public_subnets_cidr_blocks
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules = ["http-80-tcp", "http-8080-tcp", "https-443-tcp", "https-8443-tcp"]
  egress_rules = ["http-80-tcp", "http-8080-tcp", "https-443-tcp", "https-8443-tcp"]
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
    target_group_arn = aws_lb_target_group.blue_two.arn
  }
}

resource "aws_lb_listener" "front_secure" {
  load_balancer_arn = aws_lb.app.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-2:931601792379:certificate/6702d1f7-c27b-4bef-b786-2d23beca60fc"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue_two.arn
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
