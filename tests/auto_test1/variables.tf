variable "sonarqube_rg_name" {
  type        = string
  default     = "Terraform-Sonarqube-aci"
  description = "Name of the existing resource group. (var.create_rg=false) / Name of the resource group to create. (var.create_rg=true)."
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
    container_image                 = "caddy:latest" #Check for more versions/tags here: https://hub.docker.com/_/caddy
    container_cpu                   = 1
    container_memory                = 1
    container_environment_variables = null
    container_commands              = ["caddy", "reverse-proxy", "--from", "custom.domain.com", "--to", "localhost:9000"]
  }
  description = "Caddy container configuration object to create caddy reverse proxy aci."
}