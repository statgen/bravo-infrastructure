# Look up bucket
data "aws_s3_bucket" "backing" {
  bucket=var.bucket_name
}

# Create policy & role to permit reading from the bucket.
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
            "s3:GetObject"
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
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.s3_read_only.name
  policy_arn = aws_iam_policy.s3_read_only.arn
}

resource "aws_iam_instance_profile" "s3_read_bucket" {
  name = "s3_reading_${random_pet.app.id}"
  role = aws_iam_role.s3_read_only.name
}
