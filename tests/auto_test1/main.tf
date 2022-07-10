terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

##################################################
# MODULE TO TEST                                 #
##################################################
module "sonarqube-aci-test" {
  source                  = "../.."
}