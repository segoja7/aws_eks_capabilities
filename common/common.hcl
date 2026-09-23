# Load variables in locals
locals {
  # Default values for variables
  profile           = "segoja7"
  project           = "base-eks"
  deployment_region = "us-east-1"
  provider          = "aws"
  client = "dev-to"

  environment = get_env("TF_VAR_ENVIRONMENT", "dev")
  # Set tags according to company policies
  tags = {
    ProjectCode = "base-eks"
    Framework   = "DevSecOps-IaC"
  }

  # Backend Configuration
  backend_region        = "us-east-1"
  backend_bucket_name   = "test-wrapper-tfstate-071620260752"
  backend_profile       = "segoja7"
  backend_dynamodb_lock = "db-terraform-lock-071620260752"
  backend_key           = "terraform.tfstate"
  backend_encrypt = true
  # format cloud provider/client/projectname
  project_folder        = "${local.provider}/${local.client}/${local.project}"

}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "required_tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
variable "project" {
  type        = string
  description = "Project tool"
}
variable "profile" {
  description = "Variable for credentials management."
  default = {
    default = {
      profile = "segoja7"
      region = "us-east-1"
}
    dev  = {
      profile = "segoja7"
      region = "us-east-1"
}
    prod = {
      profile = "segoja7"
      region = "us-east-1"
    
}
  }

}


provider "aws" {
  region  = var.profile[terraform.workspace]["region"]
  profile = var.profile[terraform.workspace]["profile"]

  default_tags {
    tags = var.required_tags

}
}

EOF
}
