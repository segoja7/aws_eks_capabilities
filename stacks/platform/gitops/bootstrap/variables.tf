variable "cluster_arn" {
  description = "EKS cluster ARN — the server value ArgoCD uses to register the local cluster"
  type        = string
}

variable "deploy_repo_url" {
  description = "CodeCommit HTTPS URL the root Application watches; wired from the cicd/pipeline stack output"
  type        = string
}

variable "deploy_branch" {
  description = "Branch the root Application tracks (targetRevision); same branch CodeBuild pushes rendered YAML to"
  type        = string
}
