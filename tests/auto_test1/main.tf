#terraform {
#  backend "azurerm" {}
#}

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
  sonarqube_rg_name = var.sonarqube_rg_name
  caddy_config      = var.caddy_config
}