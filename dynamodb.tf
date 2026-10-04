resource "aws_dynamodb_table" "image_analysis" {
  name         = "${var.project_name}-results"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "imageId"

  attribute {
    name = "imageId"
    type = "S"
  }

  tags = {
    Name    = "${var.project_name}-results"
    Project = var.project_name
  }
}
