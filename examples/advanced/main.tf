provider "azurerm" {
  features {}
}

resource "random_integer" "number" {
  min = 0001
  max = 9999
}

module "sonarcube-aci" {
  source = "Pwd9000-ML/sonarqube-aci/azurerm"

  create_rg         = false
  sonarqube_rg_name = "pwd9000-sonarqube-aci-demo" #provide existing RG name (location for resources will be based on existing RG location)
  kv_config = {
    name = "sonarqubekv${random_integer.number.result}"
    sku  = "standard"
  }
  sa_config = {
    name                      = "sonarqubesa${random_integer.number.result}"
    account_kind              = "StorageV2"
    account_tier              = "Standard"
    account_replication_type  = "LRS"
    min_tls_version           = "TLS1_2"
    enable_https_traffic_only = true
    access_tier               = "Hot"
    is_hns_enabled            = false
  }
  shares_config = [
    {
      share_name = "data"
      quota_gb   = 10
    },
    {
      share_name = "extensions"
      quota_gb   = 5
    },
    {
      share_name = "logs"
      quota_gb   = 5
    },
    {
      share_name = "conf"
      quota_gb   = 1
    }
  ]
  pass_length        = 36
  sql_admin_username = "Sonar-Admin"
  mssql_config = {
    name    = "sonarqubemssql${random_integer.number.result}"
    version = "12.0"
  }
  mssql_fw_rules = [
    ["Allow All Azure IPs", "0.0.0.0", "0.0.0.0"]
  ]
  mssql_db_config = {
    db_name                     = "sonarqubemssqldb${random_integer.number.result}"
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
  aci_dns_label = "sonarqube-aci-${random_integer.number.result}"
  aci_group_config = {
    container_group_name = "sonarqubeaci${random_integer.number.result}"
    ip_address_type      = "Public"
    os_type              = "Linux"
    restart_policy       = "OnFailure"
  }
  sonar_config = {
    container_name                  = "sonarqube-server"
    container_image                 = "sonarqube:lts-community" #Check for more versions/tags here: https://hub.docker.com/_/sonarqube
    container_cpu                   = 2
    container_memory                = 8
    container_environment_variables = null
    container_commands              = []
  }
  caddy_config = {
    container_name                  = "caddy-reverse-proxy"
    container_image                 = "caddy:latest" #Check for more versions/tags here: https://hub.docker.com/_/caddy
    container_cpu                   = 1
    container_memory                = 1
    container_environment_variables = null
    container_commands              = ["caddy", "reverse-proxy", "--from", "custom.domain.com", "--to", "localhost:9000"]
  }
  tags = {
    Terraform   = "True"
    Description = "Sonarqube aci with caddy"
    Author      = "Marcel Lupo"
    GitHub      = "https://github.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci"
  }
}