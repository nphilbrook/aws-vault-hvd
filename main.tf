module "vault_hvd_primary" {
  #  source = "git@github.com:hashicorp/terraform-aws-vault-enterprise-hvd?ref=main"
  source = "git@github.com:nphilbrook/terraform-aws-vault-enterprise-hvd?ref=nphilbrook_custom_target_groups"
  #------------------------------------------------------------------------------
  # Common
  #------------------------------------------------------------------------------
  friendly_name_prefix = "vault"
  vault_fqdn           = local.vault_primary_fqdn
  # later
  vault_version = "1.21.3+ent"

  #------------------------------------------------------------------------------
  # Networking
  #------------------------------------------------------------------------------
  net_vpc_id            = local.w2_vpc_id
  load_balancing_scheme = "INTERNAL"
  net_vault_subnet_ids  = data.aws_subnets.private_subnets.ids
  net_lb_subnet_ids     = data.aws_subnets.private_subnets.ids

  net_ingress_vault_security_group_ids = [local.w2_bastion_security_group]
  net_ingress_vault_cidr_blocks        = [data.aws_vpc.secondary.cidr_block]

  net_ingress_ssh_security_group_ids = [local.w2_bastion_security_group]
  net_ingress_lb_security_group_ids  = [local.w2_bastion_security_group]
  net_ingress_lb_cidr_blocks         = [data.aws_vpc.secondary.cidr_block] #, "${module.prereqs_use2.bastion_private_ip}/32"] Shouldn't be needed - subset of total VPC CIDR

  create_route53_vault_dns_record      = true
  route53_vault_hosted_zone_name       = local.r53_zone
  route53_vault_hosted_zone_is_private = true

  custom_target_group_arns = [aws_lb_target_group.vault_public_primary.arn]

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
  vm_image_id      = data.aws_ami.hc_base_rhel9.id
  ec2_os_distro    = "rhel"

  depends_on = [
    aws_secretsmanager_secret_version.vault_license,
    aws_secretsmanager_secret_version.vault_tls_cert,
    aws_secretsmanager_secret_version.vault_tls_privkey,
    aws_kms_key.unseal
  ]
}

module "vault_hvd_pr" {
  #source = "git@github.com:hashicorp/terraform-aws-vault-enterprise-hvd?ref=main"
  source = "git@github.com:nphilbrook/terraform-aws-vault-enterprise-hvd?ref=nphilbrook_custom_target_groups"

  providers = {
    aws = aws.secondary
  }
  #------------------------------------------------------------------------------
  # Common
  #------------------------------------------------------------------------------
  friendly_name_prefix = "e2prvault"
  vault_fqdn           = local.vault_pr
  # later
  vault_version = "1.21.3+ent"

  #------------------------------------------------------------------------------
  # Networking
  #------------------------------------------------------------------------------
  net_vpc_id            = module.prereqs_use2.vpc_id
  load_balancing_scheme = "INTERNAL"
  net_vault_subnet_ids  = module.prereqs_use2.private_subnet_ids
  net_lb_subnet_ids     = module.prereqs_use2.private_subnet_ids

  net_ingress_vault_security_group_ids = [module.prereqs_use2.bastion_security_group_id]
  net_ingress_vault_cidr_blocks        = [data.aws_vpc.primary.cidr_block]

  net_ingress_ssh_security_group_ids = [module.prereqs_use2.bastion_security_group_id]
  net_ingress_lb_security_group_ids  = [module.prereqs_use2.bastion_security_group_id]
  net_ingress_lb_cidr_blocks         = [data.aws_vpc.primary.cidr_block] #, "${local.w2_bastion_private_ip}/32"] shouldn't be needed, subset of full VPC CIDR

  create_route53_vault_dns_record      = true
  route53_vault_hosted_zone_name       = local.r53_zone
  route53_vault_hosted_zone_is_private = true

  custom_target_group_arns = [aws_lb_target_group.vault_public_pr.arn]

  #------------------------------------------------------------------------------
  # AWS Secrets Manager installation secrets and AWS KMS unseal key
  #------------------------------------------------------------------------------
  sm_vault_license_arn      = module.prereqs_use2.vault_license_secret_arn
  sm_vault_tls_cert_arn     = module.prereqs_use2.vault_tls_cert_secret_arn
  sm_vault_tls_cert_key_arn = module.prereqs_use2.vault_tls_privkey_secret_arn
  sm_vault_tls_ca_bundle    = null # publicly trusted cert from Let's Encrypt, so no CA bundle
  vault_seal_awskms_key_arn = aws_kms_key.unseal_use2.arn

  #------------------------------------------------------------------------------
  # Compute
  #------------------------------------------------------------------------------
  vm_key_pair_name = local.key_pair_name
  vm_instance_type = "t3a.medium"
  asg_node_count   = 6
  vm_image_id      = data.aws_ami.hc_base_rhel9_e2.id
  ec2_os_distro    = "rhel"

  depends_on = [
    module.prereqs_use2,
    aws_kms_key.unseal_use2
  ]
}

# Must be manually repointed in the case of a failover
resource "aws_route53_record" "vault_cname" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.vault_fqdn
  type    = "CNAME"
  ttl     = 300
  records = [local.vault_primary_fqdn]
}

# THESE were for testing combinations of public/private
# module "vault_hvd_public_private" {
#   source = "git@github.com:hashicorp/terraform-aws-vault-enterprise-hvd?ref=main"
#   #------------------------------------------------------------------------------
#   # Common
#   #------------------------------------------------------------------------------
#   friendly_name_prefix = "vault-pub-priv"
#   vault_fqdn           = local.vault_whatever
#   # later
#   # vault_version        = "1.21.3+ent"

#   #------------------------------------------------------------------------------
#   # Networking
#   #------------------------------------------------------------------------------
#   net_vpc_id            = local.vpc_id
#   load_balancing_scheme = "EXTERNAL"
#   net_vault_subnet_ids  = data.aws_subnets.private_subnets.ids
#   net_lb_subnet_ids     = data.aws_subnets.public_subnets.ids

#   net_ingress_vault_security_group_ids = [local.bastion_security_group]
#   net_ingress_ssh_security_group_ids   = [local.bastion_security_group]
#   net_ingress_lb_cidr_blocks           = ["71.168.85.118/32"]

#   create_route53_vault_dns_record      = true
#   route53_vault_hosted_zone_name       = local.r53_zone
#   route53_vault_hosted_zone_is_private = false

#   #------------------------------------------------------------------------------
#   # AWS Secrets Manager installation secrets and AWS KMS unseal key
#   #------------------------------------------------------------------------------
#   sm_vault_license_arn      = aws_secretsmanager_secret.vault_license.arn
#   sm_vault_tls_cert_arn     = aws_secretsmanager_secret.vault_tls_cert.arn
#   sm_vault_tls_cert_key_arn = aws_secretsmanager_secret.vault_tls_privkey.arn
#   sm_vault_tls_ca_bundle    = null # publicly trusted cert from Let's Encrypt, so no CA bundle
#   vault_seal_awskms_key_arn = aws_kms_key.unseal.arn

#   #------------------------------------------------------------------------------
#   # Compute
#   #------------------------------------------------------------------------------
#   vm_key_pair_name = local.key_pair_name
#   vm_instance_type = "t3a.medium"
#   asg_node_count   = 3

#   depends_on = [
#     aws_secretsmanager_secret_version.vault_license,
#     aws_secretsmanager_secret_version.vault_tls_cert,
#     aws_secretsmanager_secret_version.vault_tls_privkey,
#     aws_kms_key.unseal
#   ]
# }

# module "vault_hvd_public_public" {
#   source = "git@github.com:hashicorp/terraform-aws-vault-enterprise-hvd?ref=main"
#   #------------------------------------------------------------------------------
#   # Common
#   #------------------------------------------------------------------------------
#   friendly_name_prefix = "vault-pub-pub"
#   vault_fqdn           = local.vault_foo
#   # later
#   # vault_version        = "1.21.3+ent"

#   #------------------------------------------------------------------------------
#   # Networking
#   #------------------------------------------------------------------------------
#   net_vpc_id            = local.vpc_id
#   load_balancing_scheme = "EXTERNAL"
#   net_vault_subnet_ids  = data.aws_subnets.public_subnets.ids
#   net_lb_subnet_ids     = data.aws_subnets.public_subnets.ids

#   net_ingress_vault_cidr_blocks = ["71.168.85.118/32"]
#   net_ingress_ssh_cidr_blocks   = ["71.168.85.118/32"]
#   net_ingress_lb_cidr_blocks    = ["71.168.85.118/32"]

#   create_route53_vault_dns_record      = true
#   route53_vault_hosted_zone_name       = local.r53_zone
#   route53_vault_hosted_zone_is_private = false

#   #------------------------------------------------------------------------------
#   # AWS Secrets Manager installation secrets and AWS KMS unseal key
#   #------------------------------------------------------------------------------
#   sm_vault_license_arn      = aws_secretsmanager_secret.vault_license.arn
#   sm_vault_tls_cert_arn     = aws_secretsmanager_secret.vault_tls_cert.arn
#   sm_vault_tls_cert_key_arn = aws_secretsmanager_secret.vault_tls_privkey.arn
#   sm_vault_tls_ca_bundle    = null # publicly trusted cert from Let's Encrypt, so no CA bundle
#   vault_seal_awskms_key_arn = aws_kms_key.unseal.arn

#   #------------------------------------------------------------------------------
#   # Compute
#   #------------------------------------------------------------------------------
#   vm_key_pair_name = local.key_pair_name
#   vm_instance_type = "t3a.medium"
#   asg_node_count   = 3

#   depends_on = [
#     aws_secretsmanager_secret_version.vault_license,
#     aws_secretsmanager_secret_version.vault_tls_cert,
#     aws_secretsmanager_secret_version.vault_tls_privkey,
#     aws_kms_key.unseal
#   ]
# }
