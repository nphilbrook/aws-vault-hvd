#------------------------------------------------------------------------------
# Lab env
#------------------------------------------------------------------------------
data "tfe_outputs" "azure_hcp_control_outputs" {
  workspace = "azure-hcp-control"
}
data "tfe_outputs" "tfe_hvd" {
  workspace = "tfe-hvd"
}

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
    values = [local.w2_vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [local.w2_vpc_id]
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

# Blessed HC base images
data "aws_ami" "hc_base_ubuntu_2404" {
  filter {
    name   = "name"
    values = ["hc-base-ubuntu-2404-amd64-*"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
  most_recent = true
  owners      = ["888995627335"] # ami-prod account
}

data "aws_ami" "hc_base_ubuntu_2404_e2" {
  provider = aws.secondary

  filter {
    name   = "name"
    values = ["hc-base-ubuntu-2404-amd64-*"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
  most_recent = true
  owners      = ["888995627335"] # ami-prod account
}

# My bastion based on ^ above
data "hcp_packer_artifact" "bastion" {
  bucket_name  = "bastion-ubuntu"
  channel_name = "dev"
  platform     = "aws"
  region       = "us-east-2"
}
