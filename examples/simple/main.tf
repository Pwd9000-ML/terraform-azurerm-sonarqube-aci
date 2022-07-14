provider "azurerm" {
  features {}
}

module "sonarcube-aci" {
  source = "Pwd9000-ML/sonarqube-aci/azurerm"

  sonarqube_rg_name = "Terraform-Sonarqube-aci-demo"
  caddy_config = {
    container_name                  = "caddy-reverse-proxy"
    container_image                 = "caddy:latest" #Check for more versions/tags here: https://hub.docker.com/_/caddy
    container_cpu                   = 1
    container_memory                = 1
    container_environment_variables = null
    container_commands              = ["caddy", "reverse-proxy", "--from", "custom.domain.com", "--to", "localhost:9000"]
  }
}