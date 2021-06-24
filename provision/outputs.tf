output "lb_dns_name" {
  value = aws_lb.app.dns_name
}

output "bastion_public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

output "app_server_private_ip" {
  value = "${aws_instance.app_server.*.private_ip}"
}

output "pet_name" {
  value = "${random_pet.app.id}"
}

output "bucket_name" {
  value = var.bucket_name
}
