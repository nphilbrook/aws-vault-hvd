locals {
  primary_region = "us-west-2"
  common_tags = {
    App                = "vault"
    Env                = "sbx"
    Owner              = "nick.philbrook@hashicorp.com"
    "created-by"       = "terraform"
    "source_workspace" = var.TFC_WORKSPACE_SLUG
  }

  vault_fqdn         = "vaultabc.nick-philbrook.sbx.hashidemos.io"
  vault_primary_fqdn = "vault-primary.nick-philbrook.sbx.hashidemos.io"
  vault_dr           = "vault-dr.nick-philbrook.sbx.hashidemos.io"
  vault_pr           = "vault-pr.nick-philbrook.sbx.hashidemos.io"
  vault_whatever     = "vaultabc-legacy.nick-philbrook.sbx.hashidemos.io"
  vault_foo          = "vaultabc-foo.nick-philbrook.sbx.hashidemos.io"

  it_me         = data.aws_iam_session_context.human.issuer_arn
  r53_zone      = "nick-philbrook.sbx.hashidemos.io"
  key_pair_name = "acme-w2"

  # Ideally pull these in from tfe-hvd outputs but :shrug:
  vpc_id                 = "vpc-0a81d8ce35b989c3d"
  vpc_cidr               = "10.9.0.0/16"
  bastion_security_group = "sg-097db6b701058a37b"
}
