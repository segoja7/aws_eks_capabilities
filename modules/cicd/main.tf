data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  create = var.create


  kms_key_arn = var.create_kms_key ? try(aws_kms_key.this[0].arn, null) : var.kms_key_arn
  role_arn    = var.create_iam_role ? try(aws_iam_role.this[0].arn, null) : var.iam_role_arn
  role_name   = try(aws_iam_role.this[0].name, null)

  repo_name = var.source_repository_name
  repo_arn = var.create_source_repo ? (
    try(aws_codecommit_repository.this[0].arn, null)
    ) : (
    try(data.aws_codecommit_repository.this[0].arn, null)
  )

  # True when any build project requests VPC isolation (drives the ENI IAM perms).
  any_vpc = length([for k, v in var.build_projects : k if v.vpc_config != null]) > 0
}

########################################
# Artifact bucket (SSE-KMS, versioned, private, TLS-only, lifecycle-managed)
########################################
resource "aws_s3_bucket" "this" {
  count = local.create ? 1 : 0

  bucket_prefix = "${var.name}-artifacts-"
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = local.create ? 1 : 0

  bucket                  = aws_s3_bucket.this[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  count  = local.create ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = local.create && (var.create_kms_key || var.kms_key_arn != null) ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}


data "aws_iam_policy_document" "bucket" {
  count = local.create ? 1 : 0

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.this[0].arn, "${aws_s3_bucket.this[0].arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count  = local.create ? 1 : 0
  bucket = aws_s3_bucket.this[0].id
  policy = data.aws_iam_policy_document.bucket[0].json
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = local.create && var.artifact_expiration_days > 0 ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    id     = "expire-noncurrent-artifacts"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.artifact_expiration_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

# Look up an existing repo when create_source_repo = false.
data "aws_codecommit_repository" "this" {
  count           = local.create && !var.create_source_repo ? 1 : 0
  repository_name = var.source_repository_name
}
