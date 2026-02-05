terraform {
  cloud {
    organization = "philbrook"

    workspaces {
      name = "aws-vault-hvd"
    }
  }
}
