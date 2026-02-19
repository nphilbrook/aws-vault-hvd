#------------------------------------------------------------------------------
# Environment variable dump (temporary)
#------------------------------------------------------------------------------
# data "environment_variables" "tfe_token" {
#   filter = "^TFE_TOKEN$"
# }

#------------------------------------------------------------------------------
# Lab env
#------------------------------------------------------------------------------
data "tfe_outputs" "azure_hcp_control_outputs" {
  workspace = "azure-hcp-control"
}

# data "tfe_organization" "foo" {
# #   name = "organization-name"
# }

# output "tfe_org_id" {
#   value = data.tfe_organization.foo.external_id
# }

#------------------------------------------------------------------------------
# AWS environment
#------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_partition" "current" {}

data "aws_iam_session_context" "human" {
  arn = "arn:aws:sts::590184029125:assumed-role/aws_nick.philbrook_test-developer/nick.philbrook@hashicorp.com"
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

data "aws_route53_zone" "zone" {
  name         = local.r53_zone
  private_zone = true
}
