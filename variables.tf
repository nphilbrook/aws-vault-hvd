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
