# encrypt logs + set retention, and lets the role scope to a known group).
resource "aws_cloudwatch_log_group" "this" {
  for_each = local.create ? var.build_projects : {}

  name              = "/aws/codebuild/${var.name}-${each.key}"
  retention_in_days = var.log_retention_days
  kms_key_id        = local.kms_key_arn
  tags              = var.tags
}

resource "aws_codebuild_project" "this" {
  for_each = local.create ? var.build_projects : {}

  name           = "${var.name}-${each.key}"
  description    = each.value.description
  service_role   = local.role_arn
  encryption_key = local.kms_key_arn
  build_timeout  = each.value.timeout
  tags           = var.tags

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = each.value.compute_type
    image           = each.value.image
    type            = each.value.type
    privileged_mode = each.value.privileged_mode

    dynamic "environment_variable" {
      for_each = each.value.environment_variables
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PLAINTEXT"
      }
    }

    dynamic "environment_variable" {
      for_each = each.value.parameter_store_variables
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PARAMETER_STORE"
      }
    }

    dynamic "environment_variable" {
      for_each = each.value.secrets_manager_variables
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "SECRETS_MANAGER"
      }
    }
  }

  dynamic "vpc_config" {
    for_each = each.value.vpc_config != null ? [each.value.vpc_config] : []
    content {
      vpc_id             = vpc_config.value.vpc_id
      subnets            = vpc_config.value.subnets
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = each.value.buildspec
  }

  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = aws_cloudwatch_log_group.this[each.key].name
    }
  }
}
