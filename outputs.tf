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

output "ui_domains" {
  value = ["${var.ui_domain_aws}", "${var.ui_domain_ext}"]
}

output "env_tag" {
  value = var.env_tag
}

output "cloudfront_domain" {
  value = "${aws_cloudfront_distribution.website_cdn_root.domain_name}"
}

output "ui_acm_cert_id" {
  value = data.aws_acm_certificate.ui.id
}

output "api_acm_cert_id" {
  value = data.aws_acm_certificate.api.id
}

output "app_data_ebs_vol_id" {
  value = aws_ebs_volume.app_data.id
}

output "db_data_ebs_vol_id" {
  value = aws_ebs_volume.db_data.id
}
