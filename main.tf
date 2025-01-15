# default instance of provider
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = var.env_tag
      Terraform = "true"
      Project = "bravo"
    }
  }
}

# us-east-1 provider instance when it is required to use this region
provider "aws" {
  region = "us-east-1"
  alias = "useast1"
  default_tags {
    tags = {
      Environment = var.env_tag
      Terraform = "true"
      Project = "bravo"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "app" {
  name = var.api_cert_domain
}

data "aws_acm_certificate" "api" {
  domain = var.api_cert_domain
  key_types = ["RSA_2048", "EC_prime256v1"]
  most_recent = true
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.app.zone_id
  name    = var.api_domain
  type    = "A"
  alias {
    name    = aws_lb.app.dns_name
    zone_id = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}

resource "random_pet" "app" {
  length    = 2
  separator = "-"
}

