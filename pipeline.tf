resource "aws_codebuild_project" "tf-plan" {
  name         = "tf-cicd-plan2"
  description  = "Plan stage for terraform"
  service_role = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  #   environment {
  #     compute_type                = "BUILD_GENERAL1_SMALL"
  #     image                       = "hashicorp/terraform:0.14.3"
  #     type                        = "LINUX_CONTAINER"
  #     image_pull_credentials_type = "SERVICE_ROLE"
  #     registry_credential {         
  #       credential          = var.dockerhub_credentials
  #       credential_provider = "SECRETS_MANAGER"
  #     }
  #   }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    # environment_variable {
    #   name  = "SOME_KEY1"
    #   value = "SOME_VALUE1"
    # }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec/plan-buildspec.yml")
  }
}

resource "aws_codebuild_project" "tf-apply" {
  name         = "tf-cicd-apply"
  description  = "Apply stage for terraform"
  service_role = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  #   environment {
  #     compute_type                = "BUILD_GENERAL1_SMALL"
  #     image                       = "hashicorp/terraform:0.14.3"
  #     type                        = "LINUX_CONTAINER"
  #     image_pull_credentials_type = "SERVICE_ROLE"
  #     registry_credential {
  #       credential          = var.dockerhub_credentials
  #       credential_provider = "SECRETS_MANAGER"
  #     }
  #   }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    # environment_variable {
    #   name  = "SOME_KEY1"
    #   value = "SOME_VALUE1"
    # }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec/apply-buildspec.yml")
  }
}


resource "aws_codepipeline" "cicd_pipeline" {

  name     = "tf-cicd"
  role_arn = aws_iam_role.tf-codepipeline-role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_artifacts.id
  }

  stage {
    name = "Source"
    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      provider = "CodeStarSourceConnection"
      version  = "1"
        output_artifacts = ["tf-code"]
    #   output_artifacts = ["source_output"]
      configuration = {
        FullRepositoryId = "thomasni91/aws-cicd-pipeline"
        BranchName       = "master"
        # ConnectionArn        = var.codestar_connector_credentials
        ConnectionArn        = aws_codestarconnections_connection.example.arn

        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Plan"
    action {
      name     = "Build"
      category = "Build"
      provider = "CodeBuild"
      version  = "1"
      owner    = "AWS"
        input_artifacts = ["tf-code"]
    #   input_artifacts = ["source_output"]
      configuration = {
        ProjectName = "tf-cicd-plan2"
      }
    }
  }

  stage {
    name = "good"
    action {
      name            = "Deploy"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["tf-code"]
      configuration = {
        ProjectName = "tf-cicd-apply"
      }
    }
  }

}

resource "aws_codestarconnections_connection" "example" {
  name          = "example-connection"
  provider_type = "GitHub"
}