data "aws_region" "current" {}

module "cicd" {
  source = "../../../../modules/cicd"

  name                   = "${var.project}-${var.environment}-cicd"
  source_repository_name = var.platform_repo_name
  source_branch          = var.platform_repo_branch
  force_destroy = true #Demo purposes

  build_projects = {
    render = {
      buildspec = "templates/buildspec_render.yml"
      environment_variables = {
        # Read by the KCL install script (kcl-lang.io/script/install-cli.sh) to pin the CLI version
        KCL_VERSION   = var.kcl_version
        ECR_REGISTRY  = var.ecr_registry
        ECR_NAMESPACE = var.ecr_namespace
        # OCI manifest delivery (Rendered Manifests Pattern). The buildspec pushes
       
        MANIFESTS_REPO = var.ecr_manifests_url
        MANIFESTS_TAG  = var.environment
        ORAS_VERSION   = var.oras_version
        # git-direct consumer claims
        CLAIMS_REPO_URL = "https://git-codecommit.${data.aws_region.current.region}.amazonaws.com/v1/repos/${var.platform_repo_name}"
      }
    }
  }

  stages = [
    { name = "render", build_project = "render" },
  ]

  additional_policy_statements = [
    {
      sid       = "ECRAuth"
      actions   = ["ecr:GetAuthorizationToken"]
      resources = ["*"]
    },
    {
      sid = "ECRModulesReadWrite"
      actions = [
        "ecr:DescribeRepositories",
        "ecr:DescribeImages",
        "ecr:ListImages",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage",
      ]
      resources = var.ecr_repository_arns
    },
  ]

  tags = var.tags
}
