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

dependency "cicd" {
  config_path = "../../cicd/pipeline"

  mock_outputs = {
    codecommit_clone_url_http = "https://git-codecommit.us-east-1.amazonaws.com/v1/repos/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  cluster_name                       = dependency.eks.outputs.cluster_name
  cluster_arn                        = dependency.eks.outputs.cluster_arn
  cluster_endpoint                   = dependency.eks.outputs.cluster_endpoint
  cluster_certificate_authority_data = dependency.eks.outputs.cluster_certificate_authority_data

  deploy_repo_url = dependency.cicd.outputs.codecommit_clone_url_http
}
