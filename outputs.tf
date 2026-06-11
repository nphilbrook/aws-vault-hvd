output "vault_load_balancer_security_group_id" {
  value = module.vault_hvd_primary.vault_load_balancer_security_group_id
}

output "mysql_db_endpoint" {
  value = aws_db_instance.mysql.address
}

output "mysql_db_port" {
  value = aws_db_instance.mysql.port
}

output "mysql_secret_arn" {
  value = aws_secretsmanager_secret.mysql_master_password.arn
}

output "mysql_secret_name" {
  value = aws_secretsmanager_secret.mysql_master_password.name
}

output "mysql_security_group_id" {
  value = aws_security_group.mysql.id
}

output "mysql_command_line_redacted" {
  value = format(
    "mysql --host=%s --port=%s --user=%s --password='<redacted>' --protocol=tcp --ssl-mode=REQUIRED --database=%s",
    aws_db_instance.mysql.address,
    aws_db_instance.mysql.port,
    var.mysql_master_username,
    var.mysql_db_name,
  )
}

# Temporary — remove after token inspection
# output "tfe_token_value" {
#   value     = data.environment_variables.tfe_token.items["TFE_TOKEN"]
#   sensitive = false
# }
