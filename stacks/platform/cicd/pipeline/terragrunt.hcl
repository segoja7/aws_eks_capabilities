include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("common/common.hcl"))
  env              = local.environment_vars.locals.environment
}


dependency "ecr" {
  config_path = "../../containers/ecr"

  mock_outputs = {
    repository_arn = "arn:aws:ecr:us-east-1:123456789012:repository/mock"
    repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  project     = local.environment_vars.locals.project
  environment = local.env

  ecr_repository_arn = dependency.ecr.outputs.repository_arn
  ecr_repository_url = dependency.ecr.outputs.repository_url

  tags = {
    ProjectCode = local.environment_vars.locals.project
    Framework   = "DevSecOps-IaC"
    Environment = local.env
    ManagedBy   = "terragrunt"
    Layer       = "platform"
    Domain      = "cicd"
  }
}
