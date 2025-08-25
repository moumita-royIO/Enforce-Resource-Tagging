resource "aws_iam_role" "lambda_exec" {
  name = "lambda-enforce-tag-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Logging permissions
resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom least-privilege policy for EC2, RDS, S3
resource "aws_iam_policy" "lambda_enforce_tags" {
  name        = "lambda-enforce-tags-policy"
  description = "Allow Lambda to terminate EC2, delete RDS and S3 resources if tags missing"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:TerminateInstances",
          "rds:DescribeDBInstances",
          "rds:DeleteDBInstance",
          "s3:GetBucketTagging",
          "s3:DeleteBucket"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach custom policy
resource "aws_iam_role_policy_attachment" "lambda_custom" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_enforce_tags.arn
}

resource "aws_iam_role" "cloudtrail_to_s3_role" {
  name = "cloudtrail-to-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
