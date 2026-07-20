module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.2.0"

  repository_name                 = var.ecr_repository_name
  repository_image_tag_mutability = "MUTABLE"
  repository_force_delete         = true
  create_lifecycle_policy         = false

  tags = var.tags
}
