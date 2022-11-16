resource "aws_codestarconnections_connection" "example" {
  name          = "backend-example-connection"
  provider_type = "GitHub"
}