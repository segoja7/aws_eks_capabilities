output "source_repository_name" {
  description = "Name of the CodeCommit source repository"
  value       = local.repo_name
}

output "source_repository_arn" {
  description = "ARN of the CodeCommit source repository"
  value       = local.repo_arn
}

output "source_repository_clone_url_http" {
  description = "HTTPS clone URL of the source repository (only when created)"
  value       = try(aws_codecommit_repository.this[0].clone_url_http, null)
}

output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = try(aws_codepipeline.this[0].name, null)
}

output "pipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = try(aws_codepipeline.this[0].arn, null)
}

output "iam_role_arn" {
  description = "ARN of the shared CodePipeline/CodeBuild role"
  value       = local.role_arn
}

output "iam_role_name" {
  description = "Name of the shared role (attach extra policies to it if needed)"
  value       = local.role_name
}

output "kms_key_arn" {
  description = "ARN of the artifact-encryption KMS key"
  value       = local.kms_key_arn
}

output "artifact_bucket" {
  description = "Name of the artifact bucket"
  value       = try(aws_s3_bucket.this[0].bucket, null)
}

output "codebuild_projects" {
  description = "CodeBuild project names keyed by build_projects key"
  value       = { for k, p in aws_codebuild_project.this : k => p.name }
}
