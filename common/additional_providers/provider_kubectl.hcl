generate "kubectl_provider" {
  path      = "kubectl_provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1"
    }
  }
}

variable "cluster_name" {
  description = "EKS cluster name the kubectl provider targets"
  type        = string
}
variable "cluster_endpoint" {
  description = "EKS API server endpoint"
  type        = string
}
variable "cluster_certificate_authority_data" {
  description = "Base64 CA cert for the cluster"
  type        = string
}

provider "kubectl" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", var.cluster_name,
      "--region", var.profile[terraform.workspace]["region"],
      "--profile", var.profile[terraform.workspace]["profile"],
    ]
  }
}
EOF
}
