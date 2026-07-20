# `project` and `profile` come from the generated provider.tf (common.hcl).

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ecr_repository_name" {
  description = "ECR repository for KCL modules published as OCI artifacts"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
