resource "aws_instance" "blue" {
  count = var.enable_blue_env ? var.blue_instance_count : 0

  ami                    = var.app_ami ? var.app_ami : data.aws_ami.ubuntu.id
  instance_type          = var.app_inst_type
  #subnet_id              = module.vpc.public_subnets[count.index % length(module.vpc.public_subnets)]
  subnet_id              = module.vpc.private_subnets[count.index % length(module.vpc.public_subnets)]
  vpc_security_group_ids = [module.app_security_group.security_group_id,
                            module.bastion_access_security_group.security_group_id]

  key_name               = var.key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.s3_read_bucket.name
  associate_public_ip_address = false

  user_data = var.install_httpd ? file("${path.module}/init-script.sh") : null

  tags = {
    Name = "version-1.0-${count.index}"
  }
}

resource "aws_lb_target_group" "blue" {
  name     = "blue-two-tg-${random_pet.app.id}-lb"
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

resource "aws_lb_target_group_attachment" "blue" {
  count            = length(aws_instance.blue)
  target_group_arn = aws_lb_target_group.blue.arn
  target_id        = aws_instance.blue[count.index].id
  port             = 8080
}
