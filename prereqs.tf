module "cert" {
  source        = "git@github.com:hashicorp-services/terraform-acme-tls-aws?ref=main"
  tls_cert_fqdn = local.vault_fqdn
  tls_cert_sans = [
    local.vault_primary_fqdn, local.vault_dr, local.vault_pr,
    local.vault_whatever, local.vault_foo
  ]
  tls_cert_email_address   = "nick.philbrook@hashicorp.com"
  route53_public_zone_name = local.r53_zone
}
