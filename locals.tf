locals {
  primary_region = "us-west-2"
  common_tags = {
    App                = "vault5"
    Env                = "sbx"
    Owner              = "nick.philbrook@hashicorp.com"
    "created-by"       = "terraform"
    "source_workspace" = var.TFC_WORKSPACE_SLUG
  }

  vault_fqdn         = "vault5.nick-philbrook.sbx.hashidemos.io"
  vault_primary_fqdn = "vault5-primary.nick-philbrook.sbx.hashidemos.io"
  vault_dr           = "vault5-dr.nick-philbrook.sbx.hashidemos.io"
  vault_pr           = "vault5-pr.nick-philbrook.sbx.hashidemos.io"
  vault_whatever     = "vault5-legacy.nick-philbrook.sbx.hashidemos.io"
  vault_foo          = "vault5-foo.nick-philbrook.sbx.hashidemos.io"

  it_me         = data.aws_iam_session_context.human.issuer_arn
  r53_zone      = "nick-philbrook.sbx.hashidemos.io"
  key_pair_name = "acme-w2"
  # Ideally pull these in from tfe-hvd outputs but :shrug:
  vpc_id                 = "vpc-0a81d8ce35b989c3d"
  bastion_security_group = "sg-097db6b701058a37b"
}
