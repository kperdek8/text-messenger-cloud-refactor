resource "aws_lambda_function" "this" {
  for_each = {
    for func in var.lambda_functions : func.name => func
  }

  function_name = each.value.name
  role          = var.execution_role_arn
  handler       = each.value.handler
  runtime       = each.value.runtime

  filename         = each.value.zip_path
  source_code_hash = filebase64sha256(each.value.zip_path)

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = var.vpc_security_group_ids
  }

  environment {
    variables = each.value.env_vars
  }
}