terraform {
  required_version = ">=1.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.30"
    }
    # terracurl = {
    #   source  = "devops-rob/terracurl"
    #   version = "~>1.2"
    # }
    acme = {
      source  = "vancluever/acme"
      version = "2.43.0"
    }
    # local = {
    #   source  = "hashicorp/local"
    #   version = "~>2.5"
    # }
    # archive = {
    #   source  = "hashicorp/archive"
    #   version = "~>2.7"
    # }
    random = {
      source  = "hashicorp/random"
      version = "~>3.8"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~>0.74"
    }
    # environment = {
    #   source  = "EppO/environment"
    # }
  }
}
