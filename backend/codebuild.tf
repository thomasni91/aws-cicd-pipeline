resource "aws_codebuild_project" "tf-plan" {
  name         = "backend-tf-cicd-plan"
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
    privileged_mode             = true

    environment_variable {
      name  = "AWS_REGION"
      value = "ap-southeast-2"
    }
    # environment_variable {
    #   name  = "AWS_ACCOUNT_ID"
    #   value = "AWS_ACCOUNT_ID:AWS_ACCOUNT_ID"
    #   type  = "SECRETS_MANAGER"
    # }
    environment_variable {
      name  = "DB_USERNAME"
      value = "braincells"
    }
    environment_variable {
      name  = "DB_PASSWORD"
      value = "braincells2022"
    }
    environment_variable {
      name  = "SECRET"
      value = "password2022"
    }
    environment_variable {
      name  = "NODE_ENV"
      value = "development"
    }
    environment_variable {
      name  = "PORT"
      value = "3001"
    }

    environment_variable {
      name  = "AWS_ECR_IMAGE"
      value = "473488110151.dkr.ecr.ap-southeast-2.amazonaws.com/codepipeline:latest"
    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = "codebuild"
    }
  }
  source {
    type     = "CODEPIPELINE"
    location = "https://github.com/thomasni91/be-quick-learner-.git"
    # buildspec = file("buildspec/buildspec.yml")

    # git_clone_depth = 1
  }
}

