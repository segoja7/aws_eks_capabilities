data "aws_iam_policy_document" "kms" {
  count = local.create && var.create_kms_key ? 1 : 0

  statement {
    sid       = "RootAccountAdmin"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "AllowRoleUseOfKey"
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [local.role_arn]
    }
  }

  # Let CloudWatch Logs use the key to encrypt the CodeBuild log groups.
  statement {
    sid       = "AllowCloudWatchLogs"
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.name}-*"]
    }
  }
}

resource "aws_kms_key" "this" {
  count = local.create && var.create_kms_key ? 1 : 0

  description             = "${var.name} CI/CD artifact and log encryption"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms[0].json
  tags                    = var.tags
}

resource "aws_kms_alias" "this" {
  count = local.create && var.create_kms_key ? 1 : 0

  name          = "alias/${var.name}-cicd"
  target_key_id = aws_kms_key.this[0].key_id
}
