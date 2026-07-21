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

variable "ecr_registry" {
  description = "ECR registry host (account.dkr.ecr.region.amazonaws.com) libraries push/pull from"
  type        = string
}

variable "ecr_namespace" {
  description = "Repo prefix for the per-library repos (e.g. kcl-modules)"
  type        = string
}

variable "ecr_repository_arns" {
  description = "ARNs of every library repo — scopes the CodeBuild role's push/pull IAM"
  type        = list(string)
}

variable "kcl_version" {
  description = "KCL CLI version the pipeline installs (read by the install script's KCL_VERSION env var). Pinned to avoid the flaky latest lookup."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
