# Registry host shared by every repo (strip the /namespace/lib path off any URL).
output "registry_url" {
  value = split("/", values(module.ecr)[0].repository_url)[0]
}

output "namespace" {
  value = var.ecr_namespace
}

# Real ARNs of every library repo — the cicd role scopes its ECR IAM to exactly
# these (grows automatically as libraries are added; no wildcard, no construction).
output "repository_arns" {
  value = [for m in module.ecr : m.repository_arn]
}

# name -> full repo URL (host/namespace/lib), handy for reference.
output "repository_urls" {
  value = { for k, m in module.ecr : k => m.repository_url }
}
