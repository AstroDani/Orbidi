resource "aws_ecr_repository" "main" {
  name                 = "orbidi-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ssm_parameter" "repository" {
  type = "String"
  name = "orbidi-api-ecr-repository-url"
  value = aws_ecr_repository.main.repository_url
}