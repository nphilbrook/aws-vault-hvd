locals {
  primary_region       = "us-west-2"
  friendly_name_prefix = "primary"
  common_tags = {
    App                = "vault"
    Env                = "sbx"
    Owner              = "nick.philbrook@hashicorp.com"
    "created-by"       = "terraform"
    "source_workspace" = var.TFC_WORKSPACE_SLUG
  }

  # DEPRECATED
  vault_fqdn         = "vault.nick-philbrook.sbx.hashidemos.io"
  vault_primary_fqdn = "vault-primary.nick-philbrook.sbx.hashidemos.io"
  vault_dr           = "vault-dr.nick-philbrook.sbx.hashidemos.io"
  vault_pr           = "vault-pr.nick-philbrook.sbx.hashidemos.io"
  vault_whatever     = "vault-legacy.nick-philbrook.sbx.hashidemos.io"
  vault_foo          = "vault-foo.nick-philbrook.sbx.hashidemos.io"

  it_me    = data.aws_iam_session_context.human.issuer_arn
  r53_zone = "nick-philbrook.sbx.hashidemos.io"
  # ngw_cidrs = [for ip in module.prereqs.ngw_public_ips : "${ip}/32"]

  vpc_id = "vpc-0a81d8ce35b989c3d"
}
