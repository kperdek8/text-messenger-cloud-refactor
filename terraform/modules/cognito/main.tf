resource "aws_cognito_user_pool" "pool" {
  name = "app-user-pool"

  lambda_config {
    pre_sign_up = var.lambda_script_arn
  }

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
  }
}

resource "aws_lambda_permission" "allow_cognito" {
  statement_id  = "AllowCognitoToInvokeFunction"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_script_arn
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.pool.arn
}

resource "aws_cognito_user_pool_client" "client" {
  name = "user-pool-client"

  user_pool_id = aws_cognito_user_pool.pool.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}
