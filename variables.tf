##################################################
# VARIABLES                                      #
##################################################
###Common###
variable "tags" {
  type = map(string)
  default = {
    Terraform   = "True"
    Description = "Sonarqube aci with caddy"
    Author      = "Marcel Lupo"
    GitHub      = "https://github.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci"
  }
  description = "A map of key value pairs that is used to tag resources created."
}

variable "location" {
  type        = string
  default     = "uksouth"
  description = "Location in azure where resources will be created. (Only in effect on newly created Resource Group when var.create_rg=true)"
}

###Resource Group###
variable "create_rg" {
  type        = bool
  default     = true
  description = "Create a new resource group for this deployment. (Set to false to use existing resource group)"
}

variable "sonarqube_rg_name" {
  type        = string
  default     = "Terraform-Sonarqube-aci"
  description = "Name of the existing resource group. (var.create_rg=false) / Name of the resource group to create. (var.create_rg=true)."
}

###Key Vault###
variable "kv_config" {
  type = object({
    name = string
    sku  = string
  })
  description = "Key Vault configuration object to create azure key vault to store sonarqube aci sql creds."
  nullable    = false
}

###Storage Account###
variable "sa_config" {
  type = object({
    name                     = string
    account_kind             = string
    account_tier             = string
    account_replication_type = string
    access_tier              = string
    min_tls_version          = string
    is_hns_enabled           = bool
  })
  description = "Storage configuration object to create persistent azure file shares for sonarqube aci."
  nullable    = false
}

variable "shares_config" {
  type = list(object({
    share_name = string
    quota_gb   = number
  }))
  default = [
    {
      share_name = "data"
      quota_gb   = 10
    },
    {
      share_name = "extensions"
      quota_gb   = 10
    },
    {
      share_name = "logs"
      quota_gb   = 10
    },
    {
      share_name = "conf"
      quota_gb   = 1
    }
  ]
  description = "Sonarqube file shares"
}

###Azure SQL Server###
variable "pass_length" {
  type        = number
  default     = 36
  description = "Password length for sql admin creds. (Stored in sonarqube key vault)"
}

variable "sql_admin_username" {
  type        = string
  default     = "Sonar-Admin"
  description = "Username for sql admin creds. (Stored in sonarqube key vault)"
}

variable "mssql_config" {
  type = object({
    name    = string
    version = string
  })
  description = "MSSQL configuration object to create persistent SQL server instance for sonarqube aci."
  nullable    = false
}

variable "mssql_fw_rules" {
  type = list(list(string))
  default = [
    ["Allow All Azure IPs", "0.0.0.0", "0.0.0.0"]
  ]
  description = "List of SQL firewall rules in format: [[rule1, startIP, endIP],[rule2, startIP, endIP]] etc."
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
    backup_interval_in_hours    = number
  })
  default = {
    db_name                     = "sonarqubemssqldb9000"
    collation                   = "SQL_Latin1_General_CP1_CS_AS"
    create_mode                 = "Default"
    license_type                = null
    max_size_gb                 = 128
    min_capacity                = 1
    auto_pause_delay_in_minutes = 60
    read_scale                  = false
    sku_name                    = "GP_S_Gen5_2"
    storage_account_type        = "Zone"
    zone_redundant              = false
    point_in_time_restore_days  = 7
    backup_interval_in_hours    = 24
  }
  description = "MSSQL database configuration object to create persistent azure SQL db for sonarqube aci."
}

###Container Group - ACIs###
variable "aci_dns_label" {
  type        = string
  description = "DNS label to assign onto the Azure Container Group."
  nullable    = false
}

variable "aci_group_config" {
  type = object({
    container_group_name = string
    ip_address_type      = string
    os_type              = string
    restart_policy       = string
  })
  description = "Container group configuration object to create sonarqube aci with caddy reverse proxy."
  nullable    = false
}

variable "sonar_config" {
  type = object({
    container_name                  = string
    container_image                 = string
    container_cpu                   = number
    container_memory                = number
    container_environment_variables = map(string)
    container_commands              = list(string)
  })
  default = {
    container_name                  = "sonarqube-server"
    container_image                 = "ghcr.io/metrostar/quartz/ironbank/big-bang/sonarqube-9:9.9.4-community"
    container_cpu                   = 2
    container_memory                = 8
    container_environment_variables = null
    container_commands              = []
  }
  description = "Sonarqube container configuration object to create sonarqube aci."
}

variable "caddy_config" {
  type = object({
    container_name                  = string
    container_image                 = string
    container_cpu                   = number
    container_memory                = number
    container_environment_variables = map(string)
    container_commands              = list(string)
  })
  default = {
    container_name                  = "caddy-reverse-proxy"
    container_image                 = "ghcr.io/sashkab/docker-caddy2/docker-caddy2:latest"
    container_cpu                   = 1
    container_memory                = 1
    container_environment_variables = null
    container_commands              = ["caddy", "reverse-proxy", "--from", "custom.domain.com", "--to", "localhost:9000"]
  }
  description = "Caddy container configuration object to create caddy reverse proxy aci."
}