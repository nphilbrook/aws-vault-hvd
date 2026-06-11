locals {
  mysql_name_prefix    = replace(var.TFC_WORKSPACE_SLUG, "/", "-")
  mysql_secret_name    = format("%s-%s-master-password", local.mysql_name_prefix, var.mysql_db_name)
  mysql_db_name_prefix = format("%s-%s", local.mysql_name_prefix, var.mysql_db_name)
  mysql_engine_version = coalesce(var.mysql_engine_version, "8.4")
}

resource "aws_db_subnet_group" "mysql" {
  name       = format("%s-db-subnets", local.mysql_db_name_prefix)
  subnet_ids = data.aws_subnets.private_subnets.ids

  tags = merge(local.common_tags, {
    Name = format("%s-db-subnets", local.mysql_db_name_prefix)
  })
}

resource "aws_security_group" "mysql" {
  name        = format("%s-mysql-sg", local.mysql_db_name_prefix)
  description = "Security group for MySQL RDS"
  vpc_id      = local.w2_vpc_id

  tags = merge(local.common_tags, {
    Name = format("%s-mysql-sg", local.mysql_db_name_prefix)
  })
}

resource "aws_security_group_rule" "mysql_ingress_from_secondary" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.secondary.cidr_block]
  description       = "Allow MySQL access from us-east-2 via VPC peering"
  security_group_id = aws_security_group.mysql.id
}

ephemeral "random_password" "mysql_master" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "mysql_master_password" {
  name        = local.mysql_secret_name
  description = "Initial MySQL master password for ${local.mysql_db_name_prefix}"

  tags = merge(local.common_tags, {
    Name = local.mysql_secret_name
  })
}

resource "aws_secretsmanager_secret_version" "mysql_master_password" {
  secret_id                = aws_secretsmanager_secret.mysql_master_password.id
  secret_string_wo         = ephemeral.random_password.mysql_master.result
  secret_string_wo_version = 1
}

ephemeral "aws_secretsmanager_secret_version" "mysql_master_password" {
  secret_id = aws_secretsmanager_secret_version.mysql_master_password.secret_id
}

resource "aws_db_instance" "mysql" {
  identifier = local.mysql_db_name_prefix

  allocated_storage          = var.mysql_allocated_storage
  apply_immediately          = true
  auto_minor_version_upgrade = true
  backup_retention_period    = var.mysql_backup_retention_period
  db_name                    = var.mysql_db_name
  delete_automated_backups   = true
  engine                     = "mysql"
  engine_version             = local.mysql_engine_version
  instance_class             = var.mysql_instance_class
  max_allocated_storage      = var.mysql_max_allocated_storage
  multi_az                   = var.mysql_multi_az
  password_wo                = ephemeral.aws_secretsmanager_secret_version.mysql_master_password.secret_string
  password_wo_version        = aws_secretsmanager_secret_version.mysql_master_password.secret_string_wo_version
  publicly_accessible        = var.mysql_publicly_accessible
  skip_final_snapshot        = var.mysql_skip_final_snapshot
  storage_encrypted          = true
  storage_type               = "gp3"
  username                   = var.mysql_master_username
  vpc_security_group_ids     = [aws_security_group.mysql.id]
  db_subnet_group_name       = aws_db_subnet_group.mysql.name

  tags = merge(local.common_tags, {
    Name = local.mysql_db_name_prefix
  })
}
