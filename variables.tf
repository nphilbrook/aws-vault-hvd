variable "TFC_WORKSPACE_SLUG" {
  description = "The org/ws of the HCP Terraform workspace. Auto-injected by the platform."
  type        = string
}

variable "vault_license_secret_value" {
  description = "Literal vault License."
  type        = string
}

variable "public_lb_ingress_ips" {
  description = "List of CIDR blocks allowed to reach the public-facing Vault load balancers (e.g. [\"203.0.113.10/32\"])."
  type        = list(string)
  default     = []
}
variable "tf_organization" {
  type    = string
  default = "philbrook"
}

variable "mysql_db_name" {
  description = "Initial MySQL database name created on the RDS instance."
  type        = string
  default     = "appdb"
}

variable "mysql_master_username" {
  description = "Master username for the MySQL RDS instance."
  type        = string
  default     = "dbadmin"
}

variable "mysql_instance_class" {
  description = "RDS instance class for the MySQL database."
  type        = string
  default     = "db.t3.micro"
}

variable "mysql_allocated_storage" {
  description = "Initial allocated storage in GiB for the MySQL database."
  type        = number
  default     = 20
}

variable "mysql_max_allocated_storage" {
  description = "Maximum storage autoscaling limit in GiB for the MySQL database."
  type        = number
  default     = 100
}

variable "mysql_engine_version" {
  description = "Optional MySQL engine version override."
  type        = string
  default     = null
}

variable "mysql_backup_retention_period" {
  description = "Number of days to retain automated backups."
  type        = number
  default     = 7
}

variable "mysql_multi_az" {
  description = "Whether the MySQL RDS instance should be deployed in Multi-AZ mode."
  type        = bool
  default     = false
}

variable "mysql_publicly_accessible" {
  description = "Whether the MySQL RDS instance should be publicly accessible."
  type        = bool
  default     = false
}

variable "mysql_skip_final_snapshot" {
  description = "Whether to skip the final snapshot when the database is destroyed."
  type        = bool
  default     = true
}