output "lb_dns_name" {
  value = aws_lb.app.dns_name
}

output "bastion_public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

output "blue_private_ip" {
  value = "${aws_instance.blue.*.private_ip}"
}

output "pet_name" {
  value = "${random_pet.app.id}"
}
