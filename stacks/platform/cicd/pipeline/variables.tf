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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
