resource "aws_codebuild_project" "tf-plan" {
  name         = "tf-cicd-plan2"
  description  = "Plan stage for terraform"
  service_role = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "REACT_APP_API_URL"
      value = "prod-url:REACT_APP_API_URL"
      type  = "SECRETS_MANAGER"
    }
  }
  source {
    type      = "CODEPIPELINE"
    # buildspec = file("buildspec/plan-buildspec.yml")
    # type            = "GITHUB"
    location        = "https://github.com/thomasni91/quickfront.git"
    git_clone_depth = 1
  }
}

