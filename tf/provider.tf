terraform {
  required_version = ">= 1.2.0"
  required_providers {
    vra = {
      source  = "vmware/vra"
      version = "~> 0.11.0"
    }
  }
}

provider "vra" {
  url          = var.url
  refresh_token = var.refresh_token
  organization = var.organization
  insecure     = var.insecure
}
