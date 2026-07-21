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
    registry_url    = "123456789012.dkr.ecr.us-east-1.amazonaws.com"
    namespace       = "kcl-modules"
    repository_arns = ["arn:aws:ecr:us-east-1:123456789012:repository/kcl-modules/mock"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  project     = local.environment_vars.locals.project
  environment = local.env

  ecr_registry        = dependency.ecr.outputs.registry_url
  ecr_namespace       = dependency.ecr.outputs.namespace
  ecr_repository_arns = dependency.ecr.outputs.repository_arns

  tags = {
    ProjectCode = local.environment_vars.locals.project
    Framework   = "DevSecOps-IaC"
    Environment = local.env
    ManagedBy   = "terragrunt"
    Layer       = "platform"
    Domain      = "cicd"
  }
}
