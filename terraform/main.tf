provider "aws" {
  region     = "ap-south-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# 1. S3 Buckets
resource "aws_s3_bucket" "original-images" {
  bucket = "my-image-resizer-bucket-original"
}

resource "aws_s3_bucket" "resized-images" {
  bucket = "my-image-resizer-bucket-resized"
}

# 2. IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "image-resizer-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 3. IAM Policy for Lambda (Least Privilege)
resource "aws_iam_role_policy" "lambda_policy" {
  name = "image-resizer-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = [
          "${aws_s3_bucket.original-images.arn}/*",
          "${aws_s3_bucket.original-images.arn}/originals/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = [
          "${aws_s3_bucket.resized-images.arn}/*",
          "${aws_s3_bucket.original-images.arn}/resized/*"
        ]
      }
    ]
  })
}

# 4. Lambda Function Definition
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../image-resizer"
  output_path = "${path.module}/function.zip"
}

resource "aws_lambda_function" "resizer" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 10
  memory_size      = 256
}

# 5. Lambda Permission for S3 Invocation
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resizer.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.original-images.arn
}

# 6. S3 Bucket Notification Trigger
resource "aws_s3_bucket_notification" "trigger" {
  bucket = aws_s3_bucket.original-images.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.resizer.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "originals/"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}