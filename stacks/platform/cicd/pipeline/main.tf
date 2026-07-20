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
      }
    }
  }

  stages = [
    { name = "render", build_project = "render" },
  ]

  tags = var.tags
}
