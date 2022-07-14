##################################################
# OUTPUTS                                        #
##################################################
output "sonarqube_aci_rg_id" {
  value       = var.create_rg ? tostring(azurerm_resource_group.sonarqube_rg[0].id) : ""
  description = "Output Resource Group ID. (Only if new resource group was created as part of this deployment)."
}

output "sonarqube_aci_kv_id" {
  value       = azurerm_key_vault.sonarqube_kv.id
  description = "The resource ID for the sonarqube key vault."
}

output "sonarqube_aci_sa_id" {
  value       = azurerm_storage_account.sonarqube_sa.id
  description = "The resource ID for the sonarqube storage account hosting file shares."
}

output "sonarqube_aci_share_ids" {
  value       = toset([for each in azurerm_storage_share.sonarqube : each.id])
  description = "List of resource IDs of each of the sonarqube file shares."
}

output "sonarqube_aci_mssql_id" {
  value       = azurerm_mssql_server.sonarqube_mssql.id
  description = "The resource ID for the sonarqube MSSQL Server instance."
}

output "sonarqube_aci_mssql_db_id" {
  value       = azurerm_mssql_database.sonarqube_mssql_db.id
  description = "The resource ID for the sonarqube MSSQL database."
}

output "sonarqube_aci_mssql_db_name" {
  value       = azurerm_mssql_database.sonarqube_mssql_db.name
  description = "The name of the sonarqube MSSQL database."
}

output "sonarqube_aci_container_group_id" {
  value       = azurerm_container_group.sonarqube_aci.id
  description = "The container group ID."
}