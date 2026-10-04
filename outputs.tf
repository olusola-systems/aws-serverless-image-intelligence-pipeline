output "image_bucket_name" {
  description = "S3 bucket used for uploaded images"
  value       = aws_s3_bucket.images.bucket
}

output "image_bucket_arn" {
  description = "ARN of the image S3 bucket"
  value       = aws_s3_bucket.images.arn
}

output "lambda_function_name" {
  description = "Lambda function that analyzes uploaded images"
  value       = aws_lambda_function.analyzer.function_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table storing image analysis results"
  value       = aws_dynamodb_table.image_analysis.name
}

output "dynamodb_table_arn" {
  description = "ARN of the image analysis DynamoDB table"
  value       = aws_dynamodb_table.image_analysis.arn
}
