include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../../../foundation/network/vpc"

  mock_outputs = {
    vpc_id          = "vpc-123456"
    private_subnets = ["subnet-123456a", "subnet-123456b"]
    public_subnets  = ["subnet-123456c", "subnet-123456d"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("common/common.hcl"))
  env              = local.environment_vars.locals.environment
}

inputs = {
  project     = local.environment_vars.locals.project
  environment = local.env

  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnets

  tags = {
    ProjectCode = local.environment_vars.locals.project
    Framework   = "DevSecOps-IaC"
    Environment = local.env
    ManagedBy   = "terragrunt"
    Layer       = "platform"
    Domain      = "containers"
  }
}
