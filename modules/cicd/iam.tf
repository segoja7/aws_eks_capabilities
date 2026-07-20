data "aws_iam_policy_document" "assume" {
  count = local.create && var.create_iam_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com", "codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  count = local.create && var.create_iam_role ? 1 : 0

  name               = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume[0].json
  tags               = var.tags
}

data "aws_iam_policy_document" "role" {
  count = local.create && var.create_iam_role ? 1 : 0

  statement {
    sid     = "Artifacts"
    actions = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject", "s3:GetBucketVersioning", "s3:GetBucketLocation", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.this[0].arn,
      "${aws_s3_bucket.this[0].arn}/*",
    ]
  }

  dynamic "statement" {
    for_each = local.kms_key_arn != null ? [1] : []
    content {
      sid       = "Kms"
      actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
      resources = [local.kms_key_arn]
    }
  }

  statement {
    sid = "CodeCommit"
    actions = [
      "codecommit:GitPull", "codecommit:GitPush", "codecommit:GetBranch", "codecommit:GetCommit",
      "codecommit:GetRepository", "codecommit:UploadArchive", "codecommit:GetUploadArchiveStatus",
      "codecommit:CancelUploadArchive",
    ]
    resources = [local.repo_arn]
  }

  statement {
    sid       = "CodeBuild"
    actions   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild", "codebuild:BatchGetProjects"]
    resources = ["arn:${data.aws_partition.current.partition}:codebuild:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:project/${var.name}-*"]
  }

  # Scoped to this module's own CodeBuild log groups.
  statement {
    sid     = "Logs"
    actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.name}-*",
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.name}-*:*",
    ]
  }

  # Read secret env-var sources (SSM / Secrets Manager), least-privilege scoped.
  dynamic "statement" {
    for_each = length(var.secrets_read_arns) > 0 ? [1] : []
    content {
      sid       = "ReadSecrets"
      actions   = ["ssm:GetParameter", "ssm:GetParameters", "secretsmanager:GetSecretValue"]
      resources = var.secrets_read_arns
    }
  }

  # Network interfaces for VPC-isolated builds.
  dynamic "statement" {
    for_each = local.any_vpc ? [1] : []
    content {
      sid = "VpcEni"
      actions = [
        "ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets", "ec2:DescribeSecurityGroups", "ec2:DescribeDhcpOptions", "ec2:DescribeVpcs",
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = local.any_vpc ? [1] : []
    content {
      sid       = "VpcEniPermission"
      actions   = ["ec2:CreateNetworkInterfacePermission"]
      resources = ["arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:network-interface/*"]

      condition {
        test     = "StringEquals"
        variable = "ec2:AuthorizedService"
        values   = ["codebuild.amazonaws.com"]
      }
    }
  }

  # Scenario-specific extras (ECR push, deploy targets, ...) injected by the caller.
  dynamic "statement" {
    for_each = var.additional_policy_statements
    content {
      sid       = try(statement.value.sid, null)
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_role_policy" "this" {
  count = local.create && var.create_iam_role ? 1 : 0

  name   = "${var.name}-policy"
  role   = aws_iam_role.this[0].id
  policy = data.aws_iam_policy_document.role[0].json
}
