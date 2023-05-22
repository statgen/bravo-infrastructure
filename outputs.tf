output "lb_dns_name" {
  value = aws_lb.app.dns_name
}

output "bastion_public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

output "app_server_private_ip" {
  value = "${aws_instance.app_server.*.private_ip}"
}

output "db_server_private_ip" {
  value = "${aws_instance.db_server.private_ip}"
}

output "pet_name" {
  value = "${random_pet.app.id}"
}

output "bucket_name" {
  value = var.bucket_name
}

output "static_site_bucket" {
  value = aws_s3_bucket.vue_site.id
}

output "api_domain" {
  value = var.api_domain
}

output "ui_domain" {
  value = var.ui_domain
}

output "env_tag" {
  value = var.env_tag
}
