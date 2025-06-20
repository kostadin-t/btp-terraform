terraform {
  required_providers {
    btp = {
      source  = "SAP/btp"
      version = "~> 1.13.0"
    }
  }
}

# Configure the BTP Provider
provider "btp" {
  globalaccount = var.globalaccount
}