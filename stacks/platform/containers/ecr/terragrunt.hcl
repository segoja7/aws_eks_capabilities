include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("common/common.hcl"))
  env              = local.environment_vars.locals.environment
}

inputs = {
  project     = local.environment_vars.locals.project
  environment = local.env

  tags = {
    ProjectCode = local.environment_vars.locals.project
    Framework   = "DevSecOps-IaC"
    Environment = local.env
    ManagedBy   = "terragrunt"
    Layer       = "platform"
    Domain      = "containers"
  }
}
