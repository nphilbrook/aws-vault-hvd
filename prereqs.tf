module "cert" {
  source        = "git@github.com:hashicorp-services/terraform-acme-tls-aws?ref=23a11ad3959ba50172770da92625f80497db1bc2"
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

# Because Secrets Manager secrets stick around in pending deletion state
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

# US-EAST-2 PREREQS
module "prereqs_use2" {
  # source = "git@github.com:hashicorp-services/terraform-aws-prereqs?ref=main"
  source = "git@github.com:nphilbrook/terraform-aws-prereqs?ref=nphilbrook_bastion_configurable"
  providers = {
    aws = aws.secondary
  }

  # --- Common --- #
  friendly_name_prefix = "e2sbx"
  common_tags          = local.common_tags

  # --- Networking --- #
  create_vpc          = true
  vpc_cidr            = "10.10.0.0/16"
  public_subnet_cidrs = ["10.10.0.0/24", "10.10.1.0/24", "10.10.2.0/24"]
  # public_subnet_cidrs            = []
  private_subnet_cidrs           = ["10.10.8.0/21", "10.10.16.0/21", "10.10.24.0/21"]
  create_bastion                 = true
  bastion_ec2_keypair_name       = local.key_pair_name
  bastion_cidr_allow_ingress_ssh = data.tfe_outputs.azure_hcp_control_outputs.nonsensitive_values.ingress_ips
  bastion_image_id               = data.hcp_packer_artifact.bastion.external_identifier
  # bastion_iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name
  save_money_on_nat_gateways = true

  # --- Secrets Manager Prereq Secrets --- #
  # No TFE in this region (yet)
  # tfe_license_secret_value             = var.tfe_license_secret_value
  # tfe_encryption_password_secret_value = var.tfe_encryption_password_secret_value
  # tfe_database_password_secret_value   = var.tfe_database_password_secret_value
  # tfe_redis_password_secret_value      = var.tfe_redis_password_secret_value

  vault_license_secret_value            = var.vault_license_secret_value
  vault_tls_cert_secret_value_base64    = module.cert.tls_fullchain_base64
  vault_tls_privkey_secret_value_base64 = module.cert.tls_privkey_base64

  # --- Cloudwatch Log Group --- #
  create_cloudwatch_log_group = true
}

resource "aws_kms_key" "unseal_use2" {
  provider = aws.secondary

  description             = "KMS Key for Vault auto-unseal (us-east-2)"
  enable_key_rotation     = true
  deletion_window_in_days = 20
}
