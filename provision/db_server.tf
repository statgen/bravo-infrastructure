resource "aws_instance" "db_server" {
  ami                    = data.aws_ami.arm_db.id
  instance_type          = var.db_inst_type
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [module.db_security_group.security_group_id,
                            module.bastion_access_security_group.security_group_id,
                            module.updates_security_group.security_group_id]

  key_name               = var.key_pair_name
  associate_public_ip_address = false

  user_data = var.install_httpd ? file("${path.module}/init-script.sh") : null

  tags = {
    Name = "bravo-db"
  }
}

resource "aws_ebs_volume" "db_data" {
  availability_zone = data.aws_availability_zones.available.names[0]
  type = "io2"
  iops = 3000
  size = var.db_volume_size
}

resource "aws_volume_attachment" "db_data_attach" {
  count       = length(aws_instance.app_server)
  # Will be auto-renamed nvme1n1
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.db_data.id
  instance_id = aws_instance.db_server.id
}
