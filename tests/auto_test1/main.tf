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
module "sonarqube-aci-test" {
  source = "../.."
}