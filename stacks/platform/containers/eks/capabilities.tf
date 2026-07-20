module "ack" {
  source  = "terraform-aws-modules/eks/aws//modules/capability"
  version = "21.24.0"

  type         = "ACK"
  cluster_name = module.eks.cluster_name

  iam_role_policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  tags = var.tags
}

module "kro" {
  source  = "terraform-aws-modules/eks/aws//modules/capability"
  version = "21.24.0"

  type         = "KRO"
  cluster_name = module.eks.cluster_name

  tags = var.tags
}

module "argocd" {
  source  = "terraform-aws-modules/eks/aws//modules/capability"
  version = "21.24.0"

  type         = "ARGOCD"
  cluster_name = module.eks.cluster_name


  configuration = {
    argo_cd = {
      aws_idc = {
        idc_instance_arn = one(data.aws_ssoadmin_instances.this.arns)
      }
      namespace = "argocd"
      rbac_role_mapping = [{
        role = "ADMIN"
        identity = [{
          id   = aws_identitystore_group.argocd_admin.group_id
          type = "SSO_GROUP"
        }]
      }]
    }
  }

  iam_policy_statements = {
    ECRRead = {
      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
      ]
      resources = ["*"]
    }
    CodeCommitPull = {
      actions   = ["codecommit:GitPull"]
      resources = ["arn:${data.aws_partition.current.partition}:codecommit:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${var.platform_repo_name}"]
    }
  }

  tags = var.tags
}

# Grant the ArgoCD capability role RBAC on THIS cluster. 
resource "aws_eks_access_policy_association" "argocd" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.argocd.iam_role_arn
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [module.argocd]
}

# The account's IAM Identity Center instance (single-region, in us-east-1).
data "aws_ssoadmin_instances" "this" {}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# Add your SSO user to this group in the IdC console to log into ArgoCD.
resource "aws_identitystore_group" "argocd_admin" {
  identity_store_id = one(data.aws_ssoadmin_instances.this.identity_store_ids)
  display_name      = var.argocd_admin_idc_group
  description       = "ArgoCD ADMIN — mapped via the EKS ArgoCD capability"
}

# Optionally create the admin user and its group membership. 
resource "aws_identitystore_user" "argocd_admin" {
  count             = var.argocd_admin_user != null ? 1 : 0
  identity_store_id = one(data.aws_ssoadmin_instances.this.identity_store_ids)

  display_name = "${var.argocd_admin_user.given_name} ${var.argocd_admin_user.family_name}"
  user_name    = var.argocd_admin_user.username

  name {
    given_name  = var.argocd_admin_user.given_name
    family_name = var.argocd_admin_user.family_name
  }

  emails {
    value   = var.argocd_admin_user.email
    primary = true
  }
}

resource "aws_identitystore_group_membership" "argocd_admin" {
  count             = var.argocd_admin_user != null ? 1 : 0
  identity_store_id = one(data.aws_ssoadmin_instances.this.identity_store_ids)
  group_id          = aws_identitystore_group.argocd_admin.group_id
  member_id         = aws_identitystore_user.argocd_admin[0].user_id
}
