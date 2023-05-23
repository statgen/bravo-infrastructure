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

  # Canonical
  owners = ["099720109477"] 
}

resource "aws_instance" "app_server" {
  count = var.enable_app_server_env ? var.app_server_instance_count : 0

  ami                    = var.app_ami == "" ? data.aws_ami.ubuntu.id : var.app_ami
  instance_type          = var.app_inst_type
  subnet_id              = module.vpc.private_subnets[count.index % length(module.vpc.public_subnets)]
  vpc_security_group_ids = [module.app_security_group.security_group_id,
                            module.bastion_access_security_group.security_group_id,
                            module.updates_security_group.security_group_id,
                            module.github_security_group.security_group_id]

  key_name               = var.key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.s3_read_bucket.name
  associate_public_ip_address = false

  user_data = var.install_httpd ? file("${path.module}/init-script.sh") : null

  tags = {
    Name = "version-1.0-${count.index}"
  }
}

resource "aws_ebs_volume" "app_data" {
  availability_zone = data.aws_availability_zones.available.names[0]
  type = "io2"
  iops = 5000
  size = var.app_volume_size
}

resource "aws_volume_attachment" "app_data_attach" {
  count       = length(aws_instance.app_server)
  # Will be auto-renamed nvme1n1
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.app_data.id
  instance_id = aws_instance.app_server[count.index].id
}

resource "aws_lb_target_group" "app_server" {
  name     = "apps-two-tg-${random_pet.app.id}-lb"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    port     = 8080
    protocol = "HTTP"
    timeout  = 5
    interval = 10
  }
}

resource "aws_lb_target_group_attachment" "app_server" {
  count            = length(aws_instance.app_server)
  target_group_arn = aws_lb_target_group.app_server.arn
  target_id        = aws_instance.app_server[count.index].id
  port             = 8080
}
