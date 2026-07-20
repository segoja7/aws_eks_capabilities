resource "aws_codepipeline" "this" {
  count = local.create ? 1 : 0

  name     = var.name
  role_arn = local.role_arn
  tags     = var.tags

  artifact_store {
    location = aws_s3_bucket.this[0].bucket
    type     = "S3"

    dynamic "encryption_key" {
      for_each = local.kms_key_arn != null ? [1] : []
      content {
        id   = local.kms_key_arn
        type = "KMS"
      }
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        RepositoryName = local.repo_name
        BranchName     = var.source_branch
        # EventBridge (default) is the recommended trigger; poll is the fallback.
        PollForSourceChanges = var.source_change_detection == "poll" ? "true" : "false"
      }
    }
  }

  dynamic "stage" {
    for_each = var.stages
    content {
      name = stage.value.name

      action {
        name            = stage.value.name
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        version         = "1"
        input_artifacts = ["source"]
        run_order       = coalesce(stage.value.run_order, stage.key + 2)

        configuration = {
          ProjectName = "${var.name}-${stage.value.build_project}"
        }
      }
    }
  }
}
