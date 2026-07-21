variable "cluster_arn" {
  description = "EKS cluster ARN — the server value ArgoCD uses to register the local cluster"
  type        = string
}

variable "argocd_role_arn" {
  description = "ArgoCD capability role ARN — written to platform-config so the EKSCluster RGD reads it (externalRef) as the spoke AccessEntry principal"
  type        = string
}

variable "manifests_repo" {
  description = "ECR repo URL of the rendered-manifests OCI artifact the root Application watches (repoURL oci://...); from the ecr stack output"
  type        = string
}

variable "manifests_tag" {
  description = "OCI channel tag the root Application tracks (targetRevision) — the environment name; matches MANIFESTS_TAG in the pipeline"
  type        = string
}
