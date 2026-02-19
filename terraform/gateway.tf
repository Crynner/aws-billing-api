resource "aws_apigatewayv2_api" "billing-gateway" {
  description   = "Public facing API for billing info access"
  name          = "billing-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "get-status" {
  api_id                 = aws_apigatewayv2_api.billing-gateway.id
  integration_method     = "POST"
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.billing-api-get.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "route-get-status" {
  api_id    = aws_apigatewayv2_api.billing-gateway.id
  route_key = "GET /user/{id}/balance"
  target    = "integrations/${aws_apigatewayv2_integration.get-status.id}"
}

resource "aws_apigatewayv2_integration" "get-ledger" {
  api_id                 = aws_apigatewayv2_api.billing-gateway.id
  integration_method     = "POST"
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.billing-api-get.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "route-get-ledger" {
  api_id    = aws_apigatewayv2_api.billing-gateway.id
  route_key = "GET /user/{id}/ledger"
  target    = "integrations/${aws_apigatewayv2_integration.get-ledger.id}"
}

resource "aws_apigatewayv2_integration" "post-user" {
  api_id                 = aws_apigatewayv2_api.billing-gateway.id
  integration_method     = "POST"
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.billing-api-post.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "route-post-user" {
  api_id    = aws_apigatewayv2_api.billing-gateway.id
  route_key = "POST /adduser"
  target    = "integrations/${aws_apigatewayv2_integration.post-user.id}"
}