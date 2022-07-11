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
resource "azurerm_storage_account" "sonarqube_sa" {
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
#Sonarqube shares
resource "azurerm_storage_share" "sonarqube" {
  for_each             = { for n in var.shares_config : n.share_name => n }
  name                 = each.value.share_name
  quota                = each.value.quota_gb
  storage_account_name = azurerm_storage_account.sonarqube_sa.name
}
#Upload config file
resource "azurerm_storage_share_file" "sonar_properties" {
  name             = "sonar.properties"
  storage_share_id = azurerm_storage_share.sonarqube["conf"].id
  #source           = abspath("${path.root}/sonar.properties")
  source = abspath("../../sonar.properties")
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
  tags = var.tags
}

###Container Group - ACIs###
resource "azurerm_container_group" "sonarqube_aci" {
  resource_group_name = var.create_rg ? tostring(azurerm_resource_group.sonarqube_rg[0].name) : tostring(data.azurerm_resource_group.sonarqube_rg[0].name)
  location            = var.create_rg ? tostring(azurerm_resource_group.sonarqube_rg[0].location) : tostring(data.azurerm_resource_group.sonarqube_rg[0].location)
  #values from variable aci_config object
  name            = lower("${var.aci_group_config.container_group_name}${random_integer.number.result}")
  ip_address_type = var.aci_group_config.ip_address_type
  dns_name_label  = var.aci_group_config.dns_label
  os_type         = var.aci_group_config.os_type
  restart_policy  = var.aci_group_config.restart_policy
  tags            = var.tags

  container {
    name   = "sonarqube-server"
    image  = "sonarqube:lts-community"
    cpu    = 2
    memory = 8
    #environment_variables = {
    #  WEBSITES_CONTAINER_START_TIME_LIMIT = 400
    #}    
    secure_environment_variables = {
      SONARQUBE_JDBC_URL      = "jdbc:sqlserver://${azurerm_mssql_server.sonarqube_mssql.name}.database.windows.net:1433;database=${azurerm_mssql_database.sonarqube_mssql_db.name};user=${azurerm_key_vault_secret.username_secret.value}@${azurerm_mssql_server.sonarqube_mssql.name};password=${azurerm_key_vault_secret.password_secret.value};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"
      SONARQUBE_JDBC_USERNAME = azurerm_key_vault_secret.username_secret.value
      SONARQUBE_JDBC_PASSWORD = azurerm_key_vault_secret.password_secret.value
    }

    ports {
      port     = 9000
      protocol = "TCP"
    }

    volume {
      name                 = "data"
      mount_path           = "/opt/sonarqube/data"
      share_name           = "data"
      storage_account_name = azurerm_storage_account.sonarqube_sa.name
      storage_account_key  = azurerm_storage_account.sonarqube_sa.primary_access_key
    }

    volume {
      name                 = "extensions"
      mount_path           = "/opt/sonarqube/extensions"
      share_name           = "extensions"
      storage_account_name = azurerm_storage_account.sonarqube_sa.name
      storage_account_key  = azurerm_storage_account.sonarqube_sa.primary_access_key
    }

    volume {
      name                 = "logs"
      mount_path           = "/opt/sonarqube/logs"
      share_name           = "logs"
      storage_account_name = azurerm_storage_account.sonarqube_sa.name
      storage_account_key  = azurerm_storage_account.sonarqube_sa.primary_access_key
    }

    volume {
      name                 = "conf"
      mount_path           = "/opt/sonarqube/conf"
      share_name           = "conf"
      storage_account_name = azurerm_storage_account.sonarqube_sa.name
      storage_account_key  = azurerm_storage_account.sonarqube_sa.primary_access_key
    }
  }

  container {
    name     = "caddy-ssl-server"
    image    = "caddy:latest"
    cpu      = "1"
    memory   = "1"
    commands = ["caddy", "reverse-proxy", "--from", "sonar.pwd9000.com", "--to", "localhost:9000"]

    ports {
      port     = 443
      protocol = "TCP"
    }

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  depends_on = [azurerm_storage_share_file.sonar_properties]

  #  dynamic "container" {
  #    for_each = var.container_config
  #    content {
  #      name = container_config.value.container_name
  #      image = container_config.value.container_image
  #      cpu = container_config.value.container_cpu
  #      memory = container_config.value.container_memory
  #      commands = lookup(container_config.value.container_commands, " ", null)

  #      dynamic "ports" {
  #        for_each = toset(rewrite_rule.value["ports"] ? [1] : [])
  #        content {
  #          port = 
  #          protocol =
  #        }


  #     }
  # }
}