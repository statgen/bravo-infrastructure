################################################################################
# Resources for backup/restore of mongo database from S3
################################################################################

# Look up bucket for mongo backups
data "aws_s3_bucket" "backup" {
  bucket=var.bucket_name
}

# Create policy to permit IO with backup bucket.
resource "aws_iam_policy" "s3_backup" {
  name        = "s3_backup_${random_pet.app.id}"
  path        = "/"
  description = "Allow EC2 instance to read/write backup bucket"

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
            "${data.aws_s3_bucket.backup.arn}",
            "${data.aws_s3_bucket.backup.arn}/*"
          ]
        },
        {
          "Effect":"Allow",
          "Action":[
            "s3:ListBucket",
            "s3:GetObject",
            "s3:DeleteObject",
            "s3:PutObject"
          ],
          "Resource":[
            "${data.aws_s3_bucket.backup.arn}",
            "${data.aws_s3_bucket.backup.arn}/*"
          ]
        }
      ]
    }
  )
}

# Role for EC2 instance to assume
resource "aws_iam_role" "s3_backup" {
  name = "s3_backup_${random_pet.app.id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Attach managed policy to role
resource "aws_iam_role_policy_attachment" "s3_backup" {
  role       = aws_iam_role.s3_backup.name
  policy_arn = aws_iam_policy.s3_backup.arn
}

resource "aws_iam_instance_profile" "s3_backup" {
  name = "s3_mongo_backup_${random_pet.app.id}"
  role = aws_iam_role.s3_backup.name
}
