
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
      # output_artifacts = ["tf-code"]
      output_artifacts = ["source_output"]
      configuration = {
        FullRepositoryId     = "thomasni91/quickfront"
        BranchName           = "master"
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
      # input_artifacts = ["tf-code"]
      input_artifacts  = ["source_output"]
      output_artifacts = ["BuildArtifact"]
      configuration = {
        ProjectName = "tf-cicd-plan2"
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      name     = "Deploy"
      category = "Deploy"
      owner    = "AWS"
      provider = "S3"
      # input_artifacts = ["build_output"]
      input_artifacts = ["BuildArtifact"]
      # input_artifacts = ["SourceArtifact"]
      # input_artifacts = ["source_output"]

      version = "1"
      configuration = {
        # ActionMode     = "REPLACE_ON_FAILURE"
        # Capabilities   = "CAPABILITY_AUTO_EXPAND,CAPABILITY_IAM"
        # OutputFileName = "CreateStackOutput.json"
        # StackName      = "35MiddleFE"
        # TemplatePath   = "build_output::sam-templated.yaml"
        BucketName = aws_s3_bucket.codepipeline_artifacts.bucket
        # BucketName      = "pipeline-artifacts-sheng"

        Extract = "true"
      }
    }
  }
}

