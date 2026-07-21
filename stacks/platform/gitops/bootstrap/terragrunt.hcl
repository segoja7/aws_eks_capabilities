include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "kubectl" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/common/additional_providers/provider_kubectl.hcl"
}

dependency "eks" {
  config_path = "../../containers/eks"

  mock_outputs = {
    cluster_name                       = "mock"
    cluster_arn                        = "arn:aws:eks:us-east-1:000000000000:cluster/mock"
    cluster_endpoint                   = "https://mock.eks.amazonaws.com"
    cluster_certificate_authority_data = "bW9jaw=="
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

# The seed's source is the manifests OCI artifact in ECR (repoURL oci://...).
dependency "ecr" {
  config_path = "../../containers/ecr"

  mock_outputs = {
    manifests_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/kcl-modules/manifests"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("common/common.hcl"))
  env              = local.environment_vars.locals.environment
}

inputs = {
  cluster_name                       = dependency.eks.outputs.cluster_name
  cluster_arn                        = dependency.eks.outputs.cluster_arn
  cluster_endpoint                   = dependency.eks.outputs.cluster_endpoint
  cluster_certificate_authority_data = dependency.eks.outputs.cluster_certificate_authority_data

  # ArgoCD tracks the environment channel tag; must match MANIFESTS_TAG in the pipeline.
  manifests_repo = dependency.ecr.outputs.manifests_url
  manifests_tag  = local.env
}
