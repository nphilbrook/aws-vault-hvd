locals {
  primary_region   = "us-west-2"
  secondary_region = "us-east-2"
  common_tags = {
    App                = "vault"
    Env                = "sbx"
    Owner              = "nick.philbrook@hashicorp.com"
    "created-by"       = "terraform"
    "source_workspace" = var.TFC_WORKSPACE_SLUG
  }

  vault_fqdn         = "vault.nick-philbrook.sbx.hashidemos.io"
  vault_primary_fqdn = "vault-primary.nick-philbrook.sbx.hashidemos.io"
  vault_dr           = "vault-dr.nick-philbrook.sbx.hashidemos.io"
  vault_pr           = "vault-pr.nick-philbrook.sbx.hashidemos.io"
  vault_whatever     = "vault-legacy.nick-philbrook.sbx.hashidemos.io"
  vault_foo          = "vault-foo.nick-philbrook.sbx.hashidemos.io"

  it_me    = data.aws_iam_session_context.human.issuer_arn
  r53_zone = "nick-philbrook.sbx.hashidemos.io"
  # bad naming - w2 exists in e2 as well
  key_pair_name = "acme-w2"
  # Ideally pull these in from tfe-hvd outputs but :shrug:
  w2_vpc_id                 = "vpc-0a81d8ce35b989c3d"
  w2_bastion_security_group = data.tfe_outputs.tfe_hvd.nonsensitive_values.new_bastion_sg_id
  w2_bastion_private_ip     = data.tfe_outputs.tfe_hvd.nonsensitive_values.new_bastion_private_ip
}
