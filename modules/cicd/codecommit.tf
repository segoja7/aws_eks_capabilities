resource "aws_codecommit_repository" "this" {
  count = local.create && var.create_source_repo ? 1 : 0

  repository_name = var.source_repository_name
  description     = var.repository_description
  tags            = var.tags

}

resource "aws_codecommit_approval_rule_template" "this" {
  count = local.create && var.create_source_repo && var.pull_request_approval != null ? 1 : 0

  name        = "${var.source_repository_name}-${var.source_branch}-approval"
  description = "PR approval rule for ${var.source_branch}"

  content = jsonencode({
    Version               = "2018-11-08"
    DestinationReferences = ["refs/heads/${var.source_branch}"]
    Statements = [{
      Type                    = "Approvers"
      NumberOfApprovalsNeeded = var.pull_request_approval.count
      ApprovalPoolMembers     = [var.pull_request_approval.approvers_arn]
    }]
  })
}

resource "aws_codecommit_approval_rule_template_association" "this" {
  count = local.create && var.create_source_repo && var.pull_request_approval != null ? 1 : 0

  approval_rule_template_name = aws_codecommit_approval_rule_template.this[0].name
  repository_name             = aws_codecommit_repository.this[0].repository_name
}
