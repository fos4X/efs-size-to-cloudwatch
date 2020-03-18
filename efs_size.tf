locals {
  function_location = "efs_size.zip"
  function_name = "efs_size"
}

data "aws_caller_identity" "current" {}

# Create a role that will be assumed by the running Lambda
resource "aws_iam_role" "efs_size_role" {
  name = "efs_size_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Create a policy to allow writing metric data
resource "aws_iam_policy" "AccessCloudWatch" {
  name = "AccessCloudWatch"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AccessCloudWatch",
      "Effect": "Allow",
      "Action": "cloudwatch:PutMetricData",
      "Resource": "*"
    }
  ]
}
EOF
}

# Create a policy to allow getting information about EFS
resource "aws_iam_policy" "AccessEFS" {
  name = "AccessEFS"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": "elasticfilesystem:DescribeFileSystems",
      "Resource": "*"
    }
  ]
}
EOF
}

# Add a log group for the lambda
resource "aws_cloudwatch_log_group" "efs_size" {
  name = "/aws/lambda/${local.function_name}"
  retention_in_days = 14
}

# Create a policy that allows Access to the LogGroup
resource "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  name = "AWSLambdaBasicExecutionRole"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "logs:CreateLogGroup",
      "Resource": "arn:aws:logs:eu-central-1:${data.aws_caller_identity.current.account_id}:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.efs_size.arn}"
      ]
    }
  ]
}
EOF
}

# Attach the Policies to the Role
resource "aws_iam_role_policy_attachment" "AccessCloudWatch" {
  role = aws_iam_role.efs_size_role.name
  policy_arn = aws_iam_policy.AccessCloudWatch.arn
}

resource "aws_iam_role_policy_attachment" "AccessEFS" {
  role = aws_iam_role.efs_size_role.name
  policy_arn = aws_iam_policy.AccessEFS.arn
}

resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRole" {
  role = aws_iam_role.efs_size_role.name
  policy_arn = aws_iam_policy.AWSLambdaBasicExecutionRole.arn
}

# Create the lambda function
resource "aws_lambda_function" "efs_size" {
  filename      = local.function_location
  function_name = local.function_name
  role          = aws_iam_role.efs_size_role.arn
  handler       = "efs_size.cloudtrail_handler"

  source_code_hash = filebase64sha256(local.function_location)

  runtime = "python3.7"
}

# Create a CloudWatch event that will run the lambda
resource "aws_cloudwatch_event_rule" "scheduled_task" {
  name = "efs_size"
  schedule_expression = "rate(1 hour)"
}

# Configure the lambda as target for the cloudwatch event
resource "aws_cloudwatch_event_target" "scheduled_task" {
  rule      = aws_cloudwatch_event_rule.scheduled_task.name
  arn       = aws_lambda_function.efs_size.arn
}

# Allow Cloudwatch to actually run the lambda
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.efs_size.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduled_task.arn
}
