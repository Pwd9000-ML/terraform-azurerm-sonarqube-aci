##################################################
# DATA                                           #
##################################################
data "azurerm_resource_group" "sonarqube_rg" {
  count = var.create_rg != true ? 1 : 0
  name  = var.sonarqube_rg_name
}
data "azurerm_client_config" "current" {}

##################################################
# RESOURCES                                      #
##################################################
resource "random_integer" "number" {
  min = 0001
  max = 9999
}

###Resource Group###
resource "azurerm_resource_group" "sonarqube_rg" {
  count    = var.create_rg ? 1 : 0
  name     = var.sonarqube_rg_name
  location = var.location
  tags     = var.tags
}

###Key Vault###
#Create Key Vault with RBAC model (To save SQL admin Password and Username)
resource "azurerm_key_vault" "sonarqube_kv" {
  resource_group_name       = var.create_rg ? tostring(azurerm_resource_group.sonarqube_rg[0].name) : tostring(data.azurerm_resource_group.sonarqube_rg[0].name)
  location                  = var.create_rg ? tostring(azurerm_resource_group.sonarqube_rg[0].location) : tostring(data.azurerm_resource_group.sonarqube_rg[0].location)
  enable_rbac_authorization = true
  #values from variable kv_config object
  name      = lower("${var.kv_config.name}${random_integer.number.result}")
  sku_name  = var.kv_config.sku
  tenant_id = data.azurerm_client_config.current.tenant_id
  tags      = var.tags
}
#Add "self" permission to key vault RBAC
resource "azurerm_role_assignment" "kv_role_assigment" {
  for_each             = toset(["Key Vault Administrator"])
  role_definition_name = each.key
  scope                = azurerm_key_vault.sonarqube_kv.id
  principal_id         = data.azurerm_client_config.current.object_id
}

###Storage Account###
resource "azurerm_storage_account" "sonarqube_shares" {
  resource_group_name = var.create_rg ? tostring(azurerm_resource_group.sonarqube_rg[0].name) : tostring(data.azurerm_resource_group.sonarqube_rg[0].name)
  location            = var.create_rg ? tostring(azurerm_resource_group.sonarqube_rg[0].location) : tostring(data.azurerm_resource_group.sonarqube_rg[0].location)
  #values from variable sa_config object
  name                      = lower(substr("${var.sa_config.name}${random_integer.number.result}", 0, 24))
  account_kind              = var.sa_config.account_kind
  account_tier              = var.sa_config.account_tier
  account_replication_type  = var.sa_config.account_replication_type
  access_tier               = var.sa_config.access_tier
  enable_https_traffic_only = var.sa_config.enable_https_traffic_only
  min_tls_version           = var.sa_config.min_tls_version
  is_hns_enabled            = var.sa_config.is_hns_enabled
  tags                      = var.tags
}
#Sonarqube data share
resource "azurerm_storage_share" "sonarqube_data_share" {
  name                 = "data"
  storage_account_name = azurerm_storage_account.sonarqube_shares.name
  quota                = var.sa_config.data_quota_gb
}
#Sonarqube extensions share
resource "azurerm_storage_share" "sonarqube_extensions_share" {
  name                 = "extensions"
  storage_account_name = azurerm_storage_account.sonarqube_shares.name
  quota                = var.sa_config.extensions_quota_gb
}
#Sonarqube storage share
resource "azurerm_storage_share" "sonarqube_logs_share" {
  name                 = "logs"
  storage_account_name = azurerm_storage_account.sonarqube_shares.name
  quota                = var.sa_config.logs_quota_gb
}

###Azure SQL Server###
#Random Password
resource "random_password" "sql_admin_password" {
  length           = var.pass_length
  special          = true
  override_special = "/@\" "
}
#Add SQL admin Password and Username to Keyvault
resource "azurerm_key_vault_secret" "password_secret" {
  name         = "sonarq-sa-password"
  value        = random_password.sql_admin_password.result
  key_vault_id = azurerm_key_vault.sonarqube_kv.id
  depends_on = [
    azurerm_role_assignment.kv_role_assigment
  ]
}
resource "azurerm_key_vault_secret" "username_secret" {
  name         = "sonarq-sa-username"
  value        = var.sql_admin_username
  key_vault_id = azurerm_key_vault.sonarqube_kv.id
  depends_on = [
    azurerm_role_assignment.kv_role_assigment
  ]
}
#Create MSSQL server instance
resource "azurerm_mssql_server" "sonarqube_mssql" {
  resource_group_name = var.create_rg ? tostring(azurerm_resource_group.sonarqube_rg[0].name) : tostring(data.azurerm_resource_group.sonarqube_rg[0].name)
  location            = var.create_rg ? tostring(azurerm_resource_group.sonarqube_rg[0].location) : tostring(data.azurerm_resource_group.sonarqube_rg[0].location)
  #values from variable mssql_config object
  name                         = lower("${var.mssql_config.name}${random_integer.number.result}")
  version                      = var.mssql_config.version
  administrator_login          = azurerm_key_vault_secret.username_secret.value
  administrator_login_password = azurerm_key_vault_secret.password_secret.value
  tags                         = var.tags
}
#Set firewall to allow AzureIPs (Container instances)
resource "azurerm_mssql_firewall_rule" "sonarqube_mssql_fw_rules" {
  count            = length(var.mssql_fw_rules)
  server_id        = azurerm_mssql_server.sonarqube_mssql.id
  name             = var.mssql_fw_rules[count.index][0]
  start_ip_address = var.mssql_fw_rules[count.index][1]
  end_ip_address   = var.mssql_fw_rules[count.index][2]
}

###MSSQL Database###
resource "azurerm_mssql_database" "sonarqube_mssql_db" {
  server_id = azurerm_mssql_server.sonarqube_mssql.id
  #values from variable mssql_db_config object
  name                        = lower("${var.mssql_db_config.db_name}${random_integer.number.result}")
  collation                   = var.mssql_db_config.collation
  create_mode                 = var.mssql_db_config.create_mode
  license_type                = var.mssql_db_config.license_type
  max_size_gb                 = var.mssql_db_config.max_size_gb
  min_capacity                = var.mssql_db_config.min_capacity
  auto_pause_delay_in_minutes = var.mssql_db_config.auto_pause_delay_in_minutes
  read_scale                  = var.mssql_db_config.read_scale
  sku_name                    = var.mssql_db_config.sku_name
  storage_account_type        = var.mssql_db_config.storage_account_type
  zone_redundant              = var.mssql_db_config.zone_redundant
  short_term_retention_policy {
    retention_days = var.mssql_db_config.point_in_time_restore_days
  }
  long_term_retention_policy {
    weekly_retention = var.mssql_db_config.ltr_weekly_retention
    week_of_year     = var.mssql_db_config.ltr_week_of_year
  }
  tags = var.tags
}