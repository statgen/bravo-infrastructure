data "aws_acm_certificate" "ui" {
  # Domain cert for CDN needs to be looked up in us-east-1 
  provider = aws.useast1
  domain = var.ui_cert_domain
  key_types = ["RSA_2048", "EC_prime256v1"]
  most_recent = true
}

# Policy doc to permit cloudfront to access anything in the bucket
data "aws_iam_policy_document" "cf_access" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.vue_site.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.vue_site.iam_arn]
    }
  }
}

## S3 Bucket to store the static website
resource "aws_s3_bucket" "vue_site" {
  bucket = "${random_pet.app.id}-vue-site"
  force_destroy = true

  tags = {
    # Cannot use computed tag in addtion to default tags.
    # https://github.com/hashicorp/terraform-provider-aws/issues/19583
    # Changed   = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.vue_site.id

  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "vue_site" {
  bucket = aws_s3_bucket.vue_site.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


resource "aws_s3_bucket_policy" "vue_policy" {
  bucket = aws_s3_bucket.vue_site.id
  policy = data.aws_iam_policy_document.cf_access.json
}

## CloudFront
resource "aws_cloudfront_origin_access_identity" "vue_site" {
  comment = "Access identity for CF to get S3 backed site assets"
}

# Creates the CloudFront distribution to serve the static website
resource "aws_cloudfront_distribution" "website_cdn_root" {
  enabled     = true
  
  # See: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html
  price_class = "PriceClass_100"
  aliases = concat(["${var.ui_domain_aws}"], "${var.ui_domain_ext}")

  origin {
    origin_id   = "origin-bucket-${aws_s3_bucket.vue_site.id}"
    domain_name = aws_s3_bucket.vue_site.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.vue_site.cloudfront_access_identity_path
    }
  }

  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "origin-bucket-${aws_s3_bucket.vue_site.id}"
    min_ttl          = "0"
    default_ttl      = "300"
    max_ttl          = "1200"

    viewer_protocol_policy = "redirect-to-https" # Redirects any HTTP request to HTTPS
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.request_redirect.arn
    }
  }

  restrictions {
    geo_restriction {
      locations = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    # Use ARN override if defined, otherwise default to looked up cert.
    acm_certificate_arn = coalesce(var.ui_cert_arn, data.aws_acm_certificate.ui.arn)
    ssl_support_method  = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 404
    response_page_path    = "/404.html"
    response_code         = 404
  }

  tags = {
    # Cannot use computed tag in addtion to default tags.
    # https://github.com/hashicorp/terraform-provider-aws/issues/19583
  }
}

# Creates the DNS record to point on the main CloudFront distribution ID
resource "aws_route53_record" "ui" {
  zone_id = data.aws_route53_zone.app.zone_id
  name    = var.ui_domain_aws
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.website_cdn_root.domain_name
    zone_id                = aws_cloudfront_distribution.website_cdn_root.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_function" "request_redirect" {
  name    = "request_redirect_${var.env_tag}"
  runtime = "cloudfront-js-2.0"
  comment = "Redirect requests to legacy apps to correct subdomain."
  publish = true
  code    = file("${path.module}/scripts/redirect_legacy.js")
}
