data "archive_file" "lambda_analyzer" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "analyzer" {
  function_name = "${var.project_name}-analyzer"
  role          = aws_iam_role.lambda_analyzer.arn

  runtime = "python3.12"
  handler = "lambda_function.lambda_handler"

  filename         = data.archive_file.lambda_analyzer.output_path
  source_code_hash = data.archive_file.lambda_analyzer.output_base64sha256

  timeout = 30

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.image_analysis.name
    }
  }

  tags = {
    Name    = "${var.project_name}-analyzer"
    Project = var.project_name
  }
}
