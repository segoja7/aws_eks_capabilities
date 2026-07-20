variable "create" {
  description = "Whether to create any resources"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name prefix for all CI/CD resources"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "Allow the artifact bucket to be destroyed while it still holds objects"
  type        = bool
  default     = false
}

variable "artifact_expiration_days" {
  description = "Expire noncurrent artifact object versions after N days (0 disables the lifecycle rule)"
  type        = number
  default     = 90
}

########################################
# Source (CodeCommit)
########################################
variable "create_source_repo" {
  description = "Create the CodeCommit repo. If false, an existing repo named source_repository_name is used."
  type        = bool
  default     = true
}

variable "source_repository_name" {
  description = "Name of the CodeCommit source repository"
  type        = string
}

variable "repository_description" {
  description = "Description for a created source repository"
  type        = string
  default     = "Managed by the cicd module"
}

variable "source_branch" {
  description = "Branch CodePipeline watches"
  type        = string
  default     = "main"
}

variable "source_change_detection" {
  description = "How the pipeline detects source changes: 'events' (EventBridge, AWS-recommended) or 'poll'."
  type        = string
  default     = "events"

  validation {
    condition     = contains(["events", "poll"], var.source_change_detection)
    error_message = "source_change_detection must be 'events' or 'poll'."
  }
}

variable "pull_request_approval" {
  description = "Optional PR approval rule on the source branch. Null disables it."
  type = object({
    approvers_arn = string
    count         = optional(number, 1)
  })
  default = null
}

########################################
# KMS (artifact + log encryption)
########################################
variable "create_kms_key" {
  description = "Create a KMS key for artifact/log encryption. If false, kms_key_arn is used (or no encryption)."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Existing KMS key ARN, used when create_kms_key = false"
  type        = string
  default     = null
}

variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7
}

########################################
# IAM
########################################
variable "create_iam_role" {
  description = "Create the shared CodePipeline/CodeBuild role. If false, iam_role_arn is used."
  type        = bool
  default     = true
}

variable "iam_role_arn" {
  description = "Existing IAM role ARN, used when create_iam_role = false"
  type        = string
  default     = null
}

variable "secrets_read_arns" {
  description = "SSM Parameter / Secrets Manager ARNs the build role may read (for secret env vars). Least-privilege scoped."
  type        = list(string)
  default     = []
}

variable "additional_policy_statements" {
  description = "Extra IAM statements attached to the created role (e.g. ECR push, deploy targets). Keeps scenario-specific perms out of the module."
  type = list(object({
    sid       = optional(string)
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

########################################
# CodeBuild
########################################
variable "log_retention_days" {
  description = "CloudWatch Logs retention (days) for the CodeBuild projects"
  type        = number
  default     = 30
}

variable "build_projects" {
  description = "CodeBuild projects keyed by name. Stages reference these keys."
  type = map(object({
    buildspec       = string
    description     = optional(string)
    compute_type    = optional(string, "BUILD_GENERAL1_SMALL")
    image           = optional(string, "aws/codebuild/amazonlinux2-x86_64-standard:5.0")
    type            = optional(string, "LINUX_CONTAINER")
    privileged_mode = optional(bool, false)
    timeout         = optional(number, 60)

    # Plaintext env vars only.
    environment_variables = optional(map(string), {})
    # Secret env vars by reference (best practice): name -> SSM parameter name.
    parameter_store_variables = optional(map(string), {})
    # name -> Secrets Manager secret id/arn (optionally ":json-key").
    secrets_manager_variables = optional(map(string), {})

    # Optional network isolation.
    vpc_config = optional(object({
      vpc_id             = string
      subnets            = list(string)
      security_group_ids = list(string)
    }))
  }))
  default = {}
}

########################################
# CodePipeline
########################################
variable "stages" {
  description = "Ordered build stages after Source. Each runs a build_projects entry via CodeBuild."
  type = list(object({
    name          = string
    build_project = string
    run_order     = optional(number)
  }))
  default = []
}
