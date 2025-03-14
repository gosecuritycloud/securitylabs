
variable "aws_region" {
  description = "AWS region for all resources."
  type    = string
  default = "us-east-1"
}

variable "security_groups" {
  description = "AWS security groups"
}

variable "port" {
  description = "AWS security groups port"
}

variable "EXPIRATION_TIMEOUT" {
  description = "AWS security groups port"
  default = 8
}
variable "cron_lambda_remove_hour" {
  description = "cron schedule to remove ip for terraform"
  default = 2
}


# Output value definitions
# output "lambda_bucket_name" {
#   description = "Name of the S3 bucket used to store function code."

#   value = aws_s3_bucket.lambda_bucket.id
# }
# #Used to define your Lambda function and related resources.
# output "function_name" {
#   description = "Name of the Lambda function."

#   value = aws_lambda_function.hello_world.function_name
# }

# #The API Gateway stage will publish your API to a URL managed by AWS
# output "base_url" {
#   description = "Base URL for API Gateway stage."

#   value = aws_apigatewayv2_stage.lambda.invoke_url
# }