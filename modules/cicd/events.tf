locals {
  use_events = local.create && var.source_change_detection == "events"
}

data "aws_iam_policy_document" "events_assume" {
  count = local.use_events ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "events" {
  count = local.use_events ? 1 : 0

  name               = "${var.name}-events"
  assume_role_policy = data.aws_iam_policy_document.events_assume[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy" "events" {
  count = local.use_events ? 1 : 0

  name = "${var.name}-events"
  role = aws_iam_role.events[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "codepipeline:StartPipelineExecution"
      Resource = aws_codepipeline.this[0].arn
    }]
  })
}

resource "aws_cloudwatch_event_rule" "source" {
  count = local.use_events ? 1 : 0

  name        = "${var.name}-source"
  description = "Start ${var.name} on commits to ${var.source_branch}"
  tags        = var.tags

  event_pattern = jsonencode({
    source        = ["aws.codecommit"]
    "detail-type" = ["CodeCommit Repository State Change"]
    resources     = [local.repo_arn]
    detail = {
      event         = ["referenceCreated", "referenceUpdated"]
      referenceType = ["branch"]
      referenceName = [var.source_branch]
    }
  })
}

resource "aws_cloudwatch_event_target" "pipeline" {
  count = local.use_events ? 1 : 0

  rule     = aws_cloudwatch_event_rule.source[0].name
  arn      = aws_codepipeline.this[0].arn
  role_arn = aws_iam_role.events[0].arn
}
