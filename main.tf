module "vault_hvd_primary" {
  source = "git@github.com:nphilbrook/terraform-aws-vault-enterprise-hvd?ref=main"
  #------------------------------------------------------------------------------
  # Common
  #------------------------------------------------------------------------------
  friendly_name_prefix = "vault"
  vault_fqdn           = local.vault_fqdn
  # later
  # vault_version        = "1.21.3+ent"

  #------------------------------------------------------------------------------
  # Networking
  #------------------------------------------------------------------------------
  net_vpc_id            = local.vpc_id
  load_balancing_scheme = "NONE"
  net_vault_subnet_ids  = data.aws_subnets.private_subnets.ids
  net_lb_subnet_ids     = data.aws_subnets.private_subnets.ids

  net_ingress_vault_security_group_ids = [local.bastion_security_group]
  net_ingress_ssh_security_group_ids   = [local.bastion_security_group]
  net_ingress_lb_security_group_ids    = [local.bastion_security_group]

  create_route53_vault_dns_record      = true
  route53_vault_hosted_zone_name       = local.r53_zone
  route53_vault_hosted_zone_is_private = true

  #------------------------------------------------------------------------------
  # AWS Secrets Manager installation secrets and AWS KMS unseal key
  #------------------------------------------------------------------------------
  sm_vault_license_arn      = aws_secretsmanager_secret.vault_license.arn
  sm_vault_tls_cert_arn     = aws_secretsmanager_secret.vault_tls_cert.arn
  sm_vault_tls_cert_key_arn = aws_secretsmanager_secret.vault_tls_privkey.arn
  sm_vault_tls_ca_bundle    = null # publicly trusted cert from Let's Encrypt, so no CA bundle
  vault_seal_awskms_key_arn = aws_kms_key.unseal.arn

  #------------------------------------------------------------------------------
  # Compute
  #------------------------------------------------------------------------------
  vm_key_pair_name = local.key_pair_name
  vm_instance_type = "t3a.medium"
  asg_node_count   = 6

  depends_on = [
    aws_secretsmanager_secret_version.vault_license,
    aws_secretsmanager_secret_version.vault_tls_cert,
    aws_secretsmanager_secret_version.vault_tls_privkey,
    aws_kms_key.unseal
  ]
}

module "vault_hvd_public_private" {
  source = "git@github.com:nphilbrook/terraform-aws-vault-enterprise-hvd?ref=main"
  #------------------------------------------------------------------------------
  # Common
  #------------------------------------------------------------------------------
  friendly_name_prefix = "vault-pub-priv"
  vault_fqdn           = local.vault_whatever
  # later
  # vault_version        = "1.21.3+ent"

  #------------------------------------------------------------------------------
  # Networking
  #------------------------------------------------------------------------------
  net_vpc_id            = local.vpc_id
  load_balancing_scheme = "EXTERNAL"
  net_vault_subnet_ids  = data.aws_subnets.private_subnets.ids
  net_lb_subnet_ids     = data.aws_subnets.public_subnets.ids

  net_ingress_vault_security_group_ids = [local.bastion_security_group]
  net_ingress_ssh_security_group_ids   = [local.bastion_security_group]
  net_ingress_lb_cidr_blocks           = ["71.168.85.118/32"]

  create_route53_vault_dns_record      = true
  route53_vault_hosted_zone_name       = local.r53_zone
  route53_vault_hosted_zone_is_private = false

  #------------------------------------------------------------------------------
  # AWS Secrets Manager installation secrets and AWS KMS unseal key
  #------------------------------------------------------------------------------
  sm_vault_license_arn      = aws_secretsmanager_secret.vault_license.arn
  sm_vault_tls_cert_arn     = aws_secretsmanager_secret.vault_tls_cert.arn
  sm_vault_tls_cert_key_arn = aws_secretsmanager_secret.vault_tls_privkey.arn
  sm_vault_tls_ca_bundle    = null # publicly trusted cert from Let's Encrypt, so no CA bundle
  vault_seal_awskms_key_arn = aws_kms_key.unseal.arn

  #------------------------------------------------------------------------------
  # Compute
  #------------------------------------------------------------------------------
  vm_key_pair_name = local.key_pair_name
  vm_instance_type = "t3a.medium"
  asg_node_count   = 3

  depends_on = [
    aws_secretsmanager_secret_version.vault_license,
    aws_secretsmanager_secret_version.vault_tls_cert,
    aws_secretsmanager_secret_version.vault_tls_privkey,
    aws_kms_key.unseal
  ]
}

module "vault_hvd_public_public" {
  source = "git@github.com:nphilbrook/terraform-aws-vault-enterprise-hvd?ref=main"
  #------------------------------------------------------------------------------
  # Common
  #------------------------------------------------------------------------------
  friendly_name_prefix = "vault-pub-pub"
  vault_fqdn           = local.vault_foo
  # later
  # vault_version        = "1.21.3+ent"

  #------------------------------------------------------------------------------
  # Networking
  #------------------------------------------------------------------------------
  net_vpc_id            = local.vpc_id
  load_balancing_scheme = "EXTERNAL"
  net_vault_subnet_ids  = data.aws_subnets.public_subnets.ids
  net_lb_subnet_ids     = data.aws_subnets.public_subnets.ids

  net_ingress_vault_cidr_blocks = ["71.168.85.118/32"]
  net_ingress_ssh_cidr_blocks   = ["71.168.85.118/32"]
  net_ingress_lb_cidr_blocks    = ["71.168.85.118/32"]

  create_route53_vault_dns_record      = true
  route53_vault_hosted_zone_name       = local.r53_zone
  route53_vault_hosted_zone_is_private = false

  #------------------------------------------------------------------------------
  # AWS Secrets Manager installation secrets and AWS KMS unseal key
  #------------------------------------------------------------------------------
  sm_vault_license_arn      = aws_secretsmanager_secret.vault_license.arn
  sm_vault_tls_cert_arn     = aws_secretsmanager_secret.vault_tls_cert.arn
  sm_vault_tls_cert_key_arn = aws_secretsmanager_secret.vault_tls_privkey.arn
  sm_vault_tls_ca_bundle    = null # publicly trusted cert from Let's Encrypt, so no CA bundle
  vault_seal_awskms_key_arn = aws_kms_key.unseal.arn

  #------------------------------------------------------------------------------
  # Compute
  #------------------------------------------------------------------------------
  vm_key_pair_name = local.key_pair_name
  vm_instance_type = "t3a.medium"
  asg_node_count   = 6

  depends_on = [
    aws_secretsmanager_secret_version.vault_license,
    aws_secretsmanager_secret_version.vault_tls_cert,
    aws_secretsmanager_secret_version.vault_tls_privkey,
    aws_kms_key.unseal
  ]
}
