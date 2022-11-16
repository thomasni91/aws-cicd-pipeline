resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "backend-pipeline-artifacts-sheng"
  acl    = "private"
}
