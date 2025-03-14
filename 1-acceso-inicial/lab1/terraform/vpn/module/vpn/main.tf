# lab1-account-id-discovery/main.tf

terraform {
    required_version = "~> 1.11.2"
        required_providers {
            aws = {
                source  = "hashicorp/aws"
                version = "~> 5.91.0"
            }
        }
}

module "s3_bucket_lambda" {
  source = "terraform-aws-modules/s3-bucket/aws"
  #version = "value"
  bucket = "vpn-${random_string.s3bucketname.result}"
  acl    = "private"
  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
}

resource "random_string" "s3bucketname" {
  length  = 10
  special = false
  upper   = false
  numeric  = true
}

resource "aws_s3_object" "vpn_add" {
  bucket = module.s3_bucket_lambda.s3_bucket_id
  key    = "vpn_add.zip"
  source = data.archive_file.vpn_add.output_path
  etag = filemd5(data.archive_file.vpn_add.output_path)
}

resource "aws_s3_object" "vpn_remove" {
  bucket = module.s3_bucket_lambda.s3_bucket_id
  key    = "vpn_remove.zip"
  source = data.archive_file.vpn_remove.output_path
  etag = filemd5(data.archive_file.vpn_remove.output_path)
}

data "archive_file" "vpn_add" {
  type = "zip"
  source_dir  = "${path.module}/add"
  output_path = "${path.module}/vpn_add.zip"
}

data "archive_file" "vpn_remove" {
  type = "zip"
  source_dir  = "${path.module}/remove"
  output_path = "${path.module}/vpn_remove.zip"
}

resource "aws_lambda_function" "vpn_add" {
  function_name = "vpn-add-${random_string.s3bucketname.result}"
  s3_bucket = module.s3_bucket_lambda.s3_bucket_id
  s3_key    = aws_s3_object.vpn_add.key
  runtime = "python3.12" # Make sure its the latest version of nodejs run npm npm@latest -g to update in terminal
  handler = "lambda_handler.lambda_handler"
  source_code_hash = data.archive_file.vpn_add.output_base64sha256
  role = aws_iam_role.lambda_vpn_add_role.arn

    environment {
    variables = {
      BUCKET_NAME = module.s3_bucket_lambda.s3_bucket_id
      KEY_PREFIX = "ips/"
      SECURITY_GROUP_ID = var.security_groups
      PORT = var.port
    }
  }
}

resource "aws_lambda_function" "vpn_remove" {
  function_name = "vpn-remove-${random_string.s3bucketname.result}"
  s3_bucket = module.s3_bucket_lambda.s3_bucket_id
  s3_key    = aws_s3_object.vpn_remove.key
  runtime = "python3.12" # Make sure its the latest version of nodejs run npm npm@latest -g to update in terminal
  handler = "lambda_handler.lambda_handler"
  source_code_hash = data.archive_file.vpn_remove.output_base64sha256
  role = aws_iam_role.lambda_vpn_remove_role.arn

    environment {
    variables = {
      EXPIRATION_TIMEOUT =  var.EXPIRATION_TIMEOUT
      SECURITY_GROUP_ID = var.security_groups
    }
  }
}


resource "aws_iam_role" "lambda_vpn_add_role" {
  name = "vpn-role-add-${random_string.s3bucketname.result}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role" "lambda_vpn_remove_role" {
  name = "vpn-role-remove-${random_string.s3bucketname.result}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = [
            "lambda.amazonaws.com",
            "events.amazonaws.com"
          ]
      }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "vpn_logs_add" {
  name = "/aws/lambda/${aws_lambda_function.vpn_add.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "vpn_logs_remove" {
  name = "/aws/lambda/${aws_lambda_function.vpn_remove.function_name}"
  retention_in_days = 14
}

# resource "aws_iam_role_policy_attachment" "lambda_vpn_policy" {
#   role       = aws_iam_role.lambda_vpn_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

resource "aws_apigatewayv2_api" "vpn" {
  name          = "vpn-apigw-${random_string.s3bucketname.result}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.vpn.id

  name        = "serverless_vpn_stage"
  auto_deploy = true
#This displays the logs in cloudwatch
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.vpn_logs_add.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "vpn" {
  api_id = aws_apigatewayv2_api.vpn.id
  integration_uri    = aws_lambda_function.vpn_add.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "vpn" {
  api_id = aws_apigatewayv2_api.vpn.id
  route_key = "GET /vpn"
  target    = "integrations/${aws_apigatewayv2_integration.vpn.id}"
}

resource "aws_cloudwatch_log_group" "vpn" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.vpn.name}"
  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vpn_add.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.vpn.execution_arn}/*/*"
}

locals {
  security_group_list = compact(split(",", var.security_groups))
}

resource "aws_iam_policy" "security_group_access" {
  name        = "security-group-access-policy"
  description = "Allows access to specified security groups"

  policy = jsonencode({
    Version = "2012-10-17"  // Use the correct version string
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ec2:AuthorizeSecurityGroupIngress"
        ],
        Resource = [for sg_id in local.security_group_list : "arn:aws:ec2:*:*:security-group/${sg_id}"]
      },
    ]
  })
}


resource "aws_iam_policy" "policy-vpn-bucket-add" {
  name = "vpn-role-add-${random_string.s3bucketname.result}"
  description = "update vpn bucket"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "s3:Put*",
          "s3:List*"
          ],
            "Resource": ["${module.s3_bucket_lambda.s3_bucket_arn}"]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:*"
            ],
            "Resource": ["${aws_cloudwatch_log_group.vpn_logs_add.arn}"]
        }
  ]
}
EOF
}

resource "aws_iam_policy" "policy-vpn-bucket-remove" {
  name = "vpn-role-remove-${random_string.s3bucketname.result}"
  description = "remove sg ingress "
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
         "ec2:DescribeSecurityGroups",
          "ec2:DescribeSecurityGroupRules",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress"
          ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:*"
            ],
            "Resource": ["${aws_cloudwatch_log_group.vpn_logs_remove.arn}"]
        }
  ]
}
EOF
}

# Attached IAM Role and the new created Policy
resource "aws_iam_role_policy_attachment" "vpn-role-attachment" {
  role       = "${aws_iam_role.lambda_vpn_add_role.name}"
  policy_arn = "${aws_iam_policy.policy-vpn-bucket-add.arn}"
}

resource "aws_iam_role_policy_attachment" "vpn-role-sgsecuritygroup_add" {
  role       = "${aws_iam_role.lambda_vpn_add_role.name}"
  policy_arn = "${aws_iam_policy.security_group_access.arn}"
}
resource "aws_iam_role_policy_attachment" "vpn-role-sgsecuritygroup_remove" {
  role       = "${aws_iam_role.lambda_vpn_remove_role.name}"
  policy_arn = "${aws_iam_policy.policy-vpn-bucket-remove.arn}"
}

# cronjob

resource "aws_cloudwatch_event_rule" "cron_lambda_remove" {
  name                = "cron_lambda_remove"
  description         = "Triggers Lambda every 2 hours"
  schedule_expression = "cron(0 */${var.cron_lambda_remove_hour} * * ? *)" # Cron expresión para 2 horas
}

resource "aws_cloudwatch_event_target" "cron_lambda_remove" {
  rule      = aws_cloudwatch_event_rule.cron_lambda_remove.name
  target_id = "runLambdaFunction"
  arn       = aws_lambda_function.vpn_remove.arn
}

resource "aws_lambda_permission" "cron_lambda_remove" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vpn_remove.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_lambda_remove.arn
}

# resource "aws_iam_role_policy_attachment" "lambda_cron_remove" {
#   role       = "${aws_iam_role.lambda_vpn_remove_role.name}"
#   policy_arn = "${aws_lambda_permission.cron_lambda_remove.arn}"
# }

