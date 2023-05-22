resource "aws_default_vpc" "default" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.key_pair_name

  vpc_security_group_ids = [module.bastion_security_group.security_group_id]

  tags = {
    Name = "bastion"
  }
}

module "bastion_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.2.0"

  name        = "bast-sg"
  description = "Security group for Bastion Host"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["ssh-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["ssh-tcp"]
}

module "bastion_access_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.2.0"

  name        = "bast-access-sg"
  description = "Allows ssh access from Bastion Host"
  vpc_id      = module.vpc.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "ssh-tcp"
      source_security_group_id = module.bastion_security_group.security_group_id
    },
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  depends_on = [module.bastion_security_group]
}
