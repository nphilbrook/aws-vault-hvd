variable "TFC_WORKSPACE_SLUG" {
  description = "The org/ws of the HCP Terraform workspace. Auto-injected by the platform."
  type        = string
}

variable "vault_license_secret_value" {
  description = "Literal vault License."
  type        = string
}
