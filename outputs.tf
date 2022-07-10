##################################################
# OUTPUTS                                        #
##################################################
output "sonarqube_aci_rg_id" {
  value       = var.create_rg ? tostring(azurerm_resource_group.sonarqube_rg[0].id) : ""
  description = "Output Resource Group ID. (Only if new resource group was created as part of this deployment)"
}

output "sonarqube_aci_kv_id" {
  value       = azurerm_key_vault.sonarqube_kv.id
  description = "The resource ID for the sonarqube key vault."
}

output "sonarqube_aci_sa_id" {
  value       = azurerm_storage_account.sonarqube_shares.id
  description = "The resource ID for the sonarqube storage account hosting file shares."
}

output "sonarqube_aci_mssql_id" {
  value       = azurerm_mssql_server.sonarqube_mssql.id
  description = "The resource ID for the sonarqube MSSQL Server instance."
}