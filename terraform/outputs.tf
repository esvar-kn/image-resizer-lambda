output "s3_bucket_name" {
  description = "Name of the S3 bucket used for original and resized images"
  value       = aws_s3_bucket.original-images.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.original-images.arn
}

output "lambda_function_name" {
  description = "Name of the deployed AWS Lambda function"
  value       = aws_lambda_function.resizer.function_name
}

output "lambda_function_arn" {
  description = "ARN of the deployed AWS Lambda function"
  value       = aws_lambda_function.resizer.arn
}
