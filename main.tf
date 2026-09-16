provider "aws" {
  region = "ap-south-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_s3_bucket" "original-images" {
  bucket = "my-image-resizer-bucket-original"
}

resource "aws_s3_bucket" "resized-images" {
  bucket = "my-image-resizer-bucket-resized"
}

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