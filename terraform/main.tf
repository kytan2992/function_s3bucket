locals {
  resource_prefix = "ky-tf"
}

resource "aws_s3_bucket" "s3" {
  bucket        = "${local.resource_prefix}-misc-storage"
  force_destroy = true
}

resource "aws_cloudwatch_log_group" "lambda" {
  name = "/aws/lambda/${local.resource_prefix}-process-s3events"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "${local.resource_prefix}-lambda-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "${local.resource_prefix}-lambda-s3-policy"
  description = "Allow Lambda to access S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      },
      {
        Action = "s3:GetObject"  
        Effect = "Allow"
        Resource = "${aws_s3_bucket.s3.arn}/*" 
      }
    ]
  }
  )
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

resource "aws_lambda_function" "lambda_s3" {
  function_name = "${local.resource_prefix}-process-s3events"
  filename      = "lambda_function.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  role          = aws_iam_role.lambda_exec_role.arn

  depends_on = [ aws_iam_role.lambda_exec_role, aws_cloudwatch_log_group.lambda ]
}

resource "aws_s3_bucket_notification" "upload_notification" {
  bucket = aws_s3_bucket.s3.id

  lambda_function {
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
    lambda_function_arn = aws_lambda_function.lambda_s3.arn
  }

  depends_on = [aws_lambda_function.lambda_s3]
}

resource "aws_lambda_permission" "allow_s3_to_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  principal     = "s3.amazonaws.com"
  function_name = aws_lambda_function.lambda_s3.function_name
  source_arn    = aws_s3_bucket.s3.arn
}
