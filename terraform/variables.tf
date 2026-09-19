variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

variable "function_name" {
  type        = string
  default     = "image-resizer"
  description = "The name of the AWS Lambda function"
}

