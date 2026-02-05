module "vault_hvd_primary" {
  source = "git@github.com:nphilbrook/terraform-aws-vault-enterprise-hvd?ref=main"
  #------------------------------------------------------------------------------
  # Common
  #------------------------------------------------------------------------------
  friendly_name_prefix = "vault"
  vault_fqdn           = local.vault_fqdn

  #------------------------------------------------------------------------------
  # Networking
  #------------------------------------------------------------------------------

  # Ideally pull these in from tfe-hvd outputs but :shrug:
  net_vpc_id            = local.vpc_id
  load_balancing_scheme = "INTERNAL"
  net_vault_subnet_ids  = data.aws_subnets.vault_subnets.ids
  net_lb_subnet_ids     = data.aws_subnets.vault_subnets.ids

  net_ingress_vault_security_group_ids = ["sg-097db6b701058a37b"]
  net_ingress_ssh_security_group_ids   = ["sg-097db6b701058a37b"]

  net_ingress_vault_cidr_blocks = ["1.2.3.0/24"]
  net_ingress_ssh_cidr_blocks   = ["1.2.3.0/24"]

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
  vm_key_pair_name = "acme-w2"
  vm_instance_type = "t3a.medium"
  asg_node_count   = 6
}
