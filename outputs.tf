output "vault_load_balancer_security_group_id" {
  value = module.vault_hvd_primary.vault_load_balancer_security_group_id
}

# Temporary — remove after token inspection
# output "tfe_token_value" {
#   value     = data.environment_variables.tfe_token.items["TFE_TOKEN"]
#   sensitive = false
# }
