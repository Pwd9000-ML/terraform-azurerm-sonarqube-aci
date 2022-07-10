##################################################
# DATA                                           #
##################################################
data "azurerm_resource_group" "sonarqube_rg" {
  count = var.create_rg != true ? 1 : 0
  name  = var.sonarqube_rg_name
}

##################################################
# RESOURCES                                      #
##################################################

###Resource Group###
resource "azurerm_resource_group" "sonarqube_rg" {
  count    = var.create_rg ? 1 : 0
  name     = var.sonarqube_rg_name
  location = var.location
  tags     = var.tags
}

###Create Storage Account###
resource "random_integer" "sa_num" {
  min = 0001
  max = 9999
}
resource "azurerm_storage_account" "sonarqube_shares" {
  resource_group_name = var.create_rg ? tostring(azurerm_resource_group.sonarqube_rg_name[0].name) : tostring(data.azurerm_resource_group.sonarqube_rg_name[0].name)
  location            = var.create_rg ? tostring(azurerm_resource_group.sonarqube_rg_name[0].location) : tostring(data.azurerm_resource_group.sonarqube_rg_name[0].location)

  #values from variable config object
  name                      = lower(substr("${var.storage_config.name}${random_integer.sa_num.result}", 0, 24))
  account_kind              = var.storage_config.account_kind
  account_tier              = var.storage_config.account_tier
  account_replication_type  = var.storage_config.account_replication_type
  access_tier               = var.storage_config.access_tier
  enable_https_traffic_only = var.storage_config.enable_https_traffic_only
  min_tls_version           = var.storage_config.min_tls_version
  is_hns_enabled            = var.storage_config.is_hns_enabled

  #Apply tags
  tags = var.tags
}

#Sonarqube data share
resource "azurerm_storage_share" "sonarqube_data_share" {
  name                 = "data"
  storage_account_name = azurerm_storage_account.sonarqube_shares.name
  quota                = var.storage_config.data_quota_gb
}

#Sonarqube extensions share
resource "azurerm_storage_share" "sonarqube_extensions_share" {
  name                 = "extensions"
  storage_account_name = azurerm_storage_account.sonarqube_shares.name
  quota                = var.storage_config.extensions_quota_gb
}

#Sonarqube storage share
resource "azurerm_storage_share" "sonarqube_logs_share" {
  name                 = "logs"
  storage_account_name = azurerm_storage_account.sonarqube_shares.name
  quota                = var.storage_config.logs_quota_gb
}