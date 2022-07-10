##################################################
# VARIABLES                                      #
##################################################
###Common###
variable "tags" {
  type = map(string)
  default = {
    Terraform   = "True"
    Description = "Sonarqube aci demo built with Terraform"
    Author      = "Marcel Lupo"
    GitHub      = "https://github.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci"
  }
  description = "Optional Input - A map of key value pairs that is used to tag resources created."
}

variable "location" {
  type        = string
  default     = "uksouth"
  description = "Optional Input - Location in azure where resources will be created. (Only in effect on newly created Resource Group when var.create_rg=true)"
}

###Resource Group###
variable "create_rg" {
  type        = bool
  default     = true
  description = "Optional Input - Create a new resource group for this deployment. (Set to false to use existing resource group)"
}

variable "sonarqube_rg_name" {
  type        = string
  default     = "Terraform-Sonarqube-aci"
  description = "Optional Input - Name of the existing resource group. (var.create_rg=false) / Name of the resource group to create. (var.create_rg=true)."
}

###Key Vault###
variable "kv_config" {
  type = object({
    name = string
    sku  = string
  })
  default = {
    name = "sonarqubekv"
    sku  = "standard"
  }
  description = "Optional Input - Key Vault configuration object to create azure key vault to store sonarqube aci sql creds."
}

###Storage Account###
variable "sa_config" {
  type = object({
    name                      = string
    account_kind              = string
    account_tier              = string
    account_replication_type  = string
    access_tier               = string
    enable_https_traffic_only = bool
    min_tls_version           = string
    is_hns_enabled            = bool
    data_quota_gb             = number
    extensions_quota_gb       = number
    logs_quota_gb             = number
  })
  default = {
    name                      = "sonarqubesa"
    account_kind              = "StorageV2"
    account_tier              = "Standard"
    account_replication_type  = "LRS"
    min_tls_version           = "TLS1_2"
    enable_https_traffic_only = true
    access_tier               = "Hot"
    is_hns_enabled            = false
    data_quota_gb             = 10
    extensions_quota_gb       = 10
    logs_quota_gb             = 10
  }
  description = "Optional Input - Storage configuration object to create persistent azure file shares for sonarqube aci."
}

###Azure SQL Server###
variable "pass_length" {
  type        = number
  default     = 24
  description = "Optional Input - Password length for sql admin creds. (Stored in sonarqube key vault)"
}

variable "sql_admin_username" {
  type        = string
  default     = "Sonar-Admin"
  description = "Optional Input - Username for sql admin creds. (Stored in sonarqube key vault)"
}

variable "mssql_config" {
  type = object({
    name    = string
    version = string
  })
  default = {
    name    = "sonarqubemssql"
    version = "12.0"
  }
  description = "Optional Input - MSSQL configuration object to create persistent SQL server instance for sonarqube aci."
}

variable "mssql_fw_rules" {
  type = list(list(string))
  default = [
    ["Allow All Azure IPs", "0.0.0.0", "0.0.0.0"]
  ]
  description = "list of SQL firewall rules in format: [[rule1, startIP, endIP],[rule2, startIP, endIP]] etc."
}

###MSSQL Database###
variable "mssql_db_config" {
  type = object({
    db_name                     = string
    collation                   = string
    create_mode                 = string
    license_type                = string
    max_size_gb                 = number
    min_capacity                = number
    auto_pause_delay_in_minutes = number
    read_scale                  = bool
    sku_name                    = string
    storage_account_type        = string
    zone_redundant              = bool
    point_in_time_restore_days  = number
    ltr_weekly_retention        = string
    ltr_week_of_year            = number
  })
  default = {
    db_name                     = "sonarqubemssqldb"
    collation                   = "SQL_Latin1_General_CP1_CS_AS"
    create_mode                 = "Default"
    license_type                = "LicenseIncluded"
    max_size_gb                 = 32
    min_capacity                = 1
    auto_pause_delay_in_minutes = 60
    read_scale                  = false
    sku_name                    = "GP_S_Gen5_1"
    storage_account_type        = "Zone"
    zone_redundant              = false
    point_in_time_restore_days  = 7
    ltr_weekly_retention        = "P7D"
    ltr_week_of_year            = 1
  }
  description = "Optional Input - MSSQL database configuration object to create persistent azure SQL db for sonarqube aci."
}


