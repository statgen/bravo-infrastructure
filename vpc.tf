module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name = "main-vpc"
  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.available.names
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, var.private_subnet_count)
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, var.public_subnet_count)

  enable_ipv6                     = true

  private_subnet_ipv6_prefixes = slice(range(10,17), 0, var.public_subnet_count)
  public_subnet_ipv6_prefixes  = slice(range(0,7), 0, var.public_subnet_count)

  map_public_ip_on_launch = true
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
    { 
      rule                     = "mongodb-27017-tcp",
      source_security_group_id = module.db_security_group.security_group_id 
    },
  ]
  number_of_computed_egress_with_source_security_group_id = 2

  computed_ingress_with_source_security_group_id = [
    { 
      rule                     = "http-8080-tcp",
      source_security_group_id = module.lb_security_group.security_group_id 
    },
    { 
      rule                     = "mongodb-27017-tcp",
      source_security_group_id = module.db_security_group.security_group_id 
    },
  ]
  number_of_computed_ingress_with_source_security_group_id = 2
}

module "db_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.2.0"

  name        = "db-sg"
  description = "Security group for db-servers to communicate with app servers."
  vpc_id      = module.vpc.vpc_id

  computed_egress_with_source_security_group_id = [
    { 
      rule                     = "mongodb-27017-tcp",
      source_security_group_id = module.app_security_group.security_group_id 
    },
  ]
  number_of_computed_egress_with_source_security_group_id = 1

  computed_ingress_with_source_security_group_id = [
    { 
      rule                     = "mongodb-27017-tcp",
      source_security_group_id = module.app_security_group.security_group_id 
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
  certificate_arn   = data.aws_acm_certificate.api.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_server.arn
  }
}

data "aws_vpc_endpoint_service" "s3" {
  service      = "s3"
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = data.aws_vpc_endpoint_service.s3.service_name
}

resource "aws_vpc_endpoint_route_table_association" "s3_route" {
  route_table_id  = module.vpc.private_route_table_ids[0]
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}
