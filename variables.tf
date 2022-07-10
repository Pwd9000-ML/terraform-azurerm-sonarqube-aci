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

###Storage Account###
variable "storage_config" {
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