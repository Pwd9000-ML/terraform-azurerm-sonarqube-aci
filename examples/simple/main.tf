provider "azurerm" {
  features {}
}

resource "random_integer" "number" {
  min = 0001
  max = 9999
}

module "sonarcube-aci" {
  source  = "Pwd9000-ML/sonarqube-aci/azurerm"
  version = ">= 1.1.0"

  sonarqube_rg_name = "Terraform-Sonarqube-aci-simple-demo"
  kv_config = {
    name = "sonarqubekv${random_integer.number.result}"
    sku  = "standard"
  }
  sa_config = {
    name                     = "sonarqubesa${random_integer.number.result}"
    account_kind             = "StorageV2"
    account_tier             = "Standard"
    account_replication_type = "LRS"
    min_tls_version          = "TLS1_2"
    access_tier              = "Hot"
    is_hns_enabled           = false
  }
  mssql_config = {
    name    = "sonarqubemssql${random_integer.number.result}"
    version = "12.0"
  }
  aci_group_config = {
    container_group_name = "sonarqubeaci${random_integer.number.result}"
    ip_address_type      = "Public"
    os_type              = "Linux"
    restart_policy       = "OnFailure"
  }
  aci_dns_label = "sonarqube-aci-${random_integer.number.result}"
  caddy_config = {
    container_name                  = "caddy-reverse-proxy"
    container_image                 = "ghcr.io/sashkab/docker-caddy2/docker-caddy2:latest"
    container_cpu                   = 1
    container_memory                = 1
    container_environment_variables = null
    container_commands              = ["caddy", "reverse-proxy", "--from", "custom.domain.com", "--to", "localhost:9000"]
  }
}