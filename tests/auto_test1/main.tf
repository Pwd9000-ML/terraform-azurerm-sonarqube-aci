terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

##################################################
# MODULE TO TEST                                 #
##################################################
module "sonarcube-aci" {
  source            = "../.."
  aci_dns_label     = var.aci_dns_label
  sonarqube_rg_name = var.sonarqube_rg_name
  caddy_config      = var.caddy_config
}