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

resource "aws_kms_key" "unseal" {
  description             = "KMS Key for Vault auto-unseal"
  enable_key_rotation     = true
  deletion_window_in_days = 20
}

# Because Secrets Manager secrets stick around in pending deletion state.action "
# On a full destroy/recreate these will change
resource "random_id" "secret_suffix" {
  byte_length = 4
}

# LICENSE
resource "aws_secretsmanager_secret" "vault_license" {
  name        = "vault-license-${random_id.secret_suffix.hex}"
  description = "Raw contents of the VAULT license file stored as a string."

  tags = merge(
    { Name = "vault-license-${random_id.secret_suffix.hex}" },
    local.common_tags
  )
}

resource "aws_secretsmanager_secret_version" "vault_license" {
  secret_id     = aws_secretsmanager_secret.vault_license.id
  secret_string = var.vault_license_secret_value
}

#------------------------------------------------------------------------------
# TLS Certificate (PEM format)
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "vault_tls_cert" {
  name        = "vault-cert-${random_id.secret_suffix.hex}"
  description = "string value of VAULT TLS certificate in PEM format."

  tags = merge(
    { Name = "vault-cert-${random_id.secret_suffix.hex}" },
    local.common_tags
  )
}

resource "aws_secretsmanager_secret_version" "vault_tls_cert" {
  secret_id     = aws_secretsmanager_secret.vault_tls_cert.id
  secret_string = base64decode(module.cert.tls_fullchain_base64)
}

#------------------------------------------------------------------------------
# TLS Private Key (PEM format)
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "vault_tls_privkey" {
  name        = "vault-privkey-${random_id.secret_suffix.hex}"
  description = "string value of VAULT TLS private key in PEM format."

  tags = merge(
    { Name = "vault-privkey-${random_id.secret_suffix.hex}" },
    local.common_tags
  )
}

resource "aws_secretsmanager_secret_version" "vault_tls_privkey" {
  secret_id     = aws_secretsmanager_secret.vault_tls_privkey.id
  secret_string = base64decode(module.cert.tls_privkey_base64)
}
