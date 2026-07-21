# `project` and `profile` come from the generated provider.tf (common.hcl).

variable "environment" {
  description = "Environment name"
  type        = string
}


variable "platform_repo_name" {
  description = "CodeCommit repository name (mirror of the public GitHub platform repo). Shared with the eks stack, which grants codecommit:GitPull on it."
  type        = string
}

variable "platform_repo_branch" {
  description = "Branch CodePipeline watches (where KCL is authored)"
  type        = string
}

variable "deploy_branch" {
  description = "Branch CodeBuild pushes rendered YAML to; ArgoCD watches this one (used by the buildspec)"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repo — scopes the CodeBuild role's push/pull IAM"
  type        = string
}

variable "ecr_repository_url" {
  description = "URL of the ECR repo (host/repo) — the kcl mod push/pull target"
  type        = string
}

variable "kcl_version" {
  description = "KCL CLI version the pipeline installs (read by the install script's KCL_VERSION env var). Pinned to avoid the flaky latest lookup."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
