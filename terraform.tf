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
      version = "~>2.23"
    }
    # local = {
    #   source  = "hashicorp/local"
    #   version = "~>2.5"
    # }
    # archive = {
    #   source  = "hashicorp/archive"
    #   version = "~>2.7"
    # }
  }
}
