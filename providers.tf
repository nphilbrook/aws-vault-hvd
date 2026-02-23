provider "aws" {
  region = local.primary_region
  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  region = local.secondary_region
  alias  = "secondary"
  default_tags {
    tags = local.common_tags
  }
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

provider "tfe" {
  organization = "philbrook"
}
