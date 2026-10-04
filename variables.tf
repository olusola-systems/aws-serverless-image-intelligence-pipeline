variable "aws_region" {
  description = "AWS region for the Week 31 deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "week31-serverless-image-intelligence-pipeline"
}
