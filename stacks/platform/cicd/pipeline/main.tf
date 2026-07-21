module "cicd" {
  source = "../../../../modules/cicd"

  name                   = "${var.project}-${var.environment}-cicd"
  source_repository_name = var.platform_repo_name
  source_branch          = var.platform_repo_branch

  build_projects = {
    render = {
      buildspec = "templates/buildspec_render.yml"
      environment_variables = {
        REPO_NAME     = var.platform_repo_name
        DEPLOY_BRANCH = var.deploy_branch
        ECR_REPO_URL = var.ecr_repository_url
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
      resources = [var.ecr_repository_arn]
    },
  ]

  tags = var.tags
}
