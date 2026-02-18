provider "aws" {
  region = local.primary_region
}

provider "aws" {
  region = local.secondary_region
  alias  = "secondary"
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

provider "tfe" {
  organization = "philbrook"
}
