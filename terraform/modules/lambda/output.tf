output "lambda_routes" {
  value = {
    for func in var.lambda_functions :
      "${func.method} ${func.route}" => {
        name       = func.name
        path     = func.route
        method     = func.method
        lambda_arn = aws_lambda_function.this[func.name].arn
    }
  }
}