output "apigw_invoke_url" {
  value = aws_apigatewayv2_api.apigw.api_endpoint
}

output "apigw_domain_name" {
  value = replace(aws_apigatewayv2_api.apigw.api_endpoint, "https://", "")
}