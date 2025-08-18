################################################################################
# Resources to allow reading backing data from data prep into mongo database 
################################################################################

# Look up bucket
data "aws_s3_bucket" "backing" {
  bucket=var.bucket_name
}

# Opt-in for additional metrics
resource "aws_s3_bucket_metric" "coverage_filtered" {
  bucket = data.aws_s3_bucket.backing.id
  name   = "BravoCoverage"

  filter {
    prefix = "runtime/coverage/"
  }
}

# Add metrics for vcf objects
resource "aws_s3_bucket_metric" "vcfs_filtered" {
  bucket = data.aws_s3_bucket.backing.id
  name   = "BravoVcfs"

  filter {
    prefix = "runtime/public-vcfs/"
  }
}

resource "aws_iam_policy" "s3_read_only_lookup" {
  name        = "s3_read_lookup_${random_pet.app.id}"
  path        = "/"
  description = "Allow clients to read the instance profile to use facilitate using STS credentials."

  policy = jsonencode(
    {
      "Version":"2012-10-17",
      "Statement":[
        {
          "Effect":"Allow",
          "Action":[
            "iam:GetInstanceProfile",
          ],
          "Resource": "${aws_iam_instance_profile.s3_read_bucket.arn}"
        }
      ]
    }
  )
}

# Create policy and role to permit reading from the backing data bucket.
resource "aws_iam_policy" "s3_read_only" {
  name        = "s3_read_${random_pet.app.id}"
  path        = "/"
  description = "Allow EC2 instance to read a specified bucket"

  policy = jsonencode( 
    {
      "Version":"2012-10-17",
      "Statement":[
        {
          "Effect":"Allow",
          "Action":[
            "s3:ListBucket",
            "s3:ListAllMyBuckets"
          ],
          "Resource":"arn:aws:s3:::*"
        },
        {
          "Effect":"Deny",
          "Action":[
            "s3:ListBucket"
          ],
          "NotResource":[
            "${data.aws_s3_bucket.backing.arn}",
            "${data.aws_s3_bucket.backing.arn}/*"
          ]
        },
        {
          "Effect":"Allow",
          "Action":[
            "s3:ListBucket",
            "s3:GetObject",
            "s3:GetBucketLocation"
          ],
          "Resource":[
            "${data.aws_s3_bucket.backing.arn}",
            "${data.aws_s3_bucket.backing.arn}/*"
          ]
        }
      ]
    }
  )
}

############################################
# Role for EC2 instance allowing S3 access #
############################################

# Workaround for self referencing role:
# https://aws.amazon.com/blogs/security/announcing-an-update-to-iam-role-trust-policy-behavior
data "aws_caller_identity" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

resource "aws_iam_role" "s3_read_only" {
  name = "s3_read_${random_pet.app.id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
          AWS = "arn:aws:iam::${local.aws_account_id}:role/s3_read_${random_pet.app.id}"
        }
      },
    ]
  })
}

# Attach managed policies to role
resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.s3_read_only.name
  policy_arn = aws_iam_policy.s3_read_only.arn
}

resource "aws_iam_role_policy_attachment" "lookup_s3_read_only" {
  role       = aws_iam_role.s3_read_only.name
  policy_arn = aws_iam_policy.s3_read_only_lookup.arn
}

resource "aws_iam_instance_profile" "s3_read_bucket" {
  name = "s3_reading_${random_pet.app.id}"
  role = aws_iam_role.s3_read_only.name
}
