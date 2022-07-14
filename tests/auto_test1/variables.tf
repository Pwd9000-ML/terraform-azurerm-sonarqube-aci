variable "sonarqube_rg_name" {
  type        = string
  description = "Name of the existing resource group. (var.create_rg=false) / Name of the resource group to create. (var.create_rg=true)."
}

variable "aci_dns_label" {
  type        = string
  default     = "sonarqube-aci"
  description = "DNS label to assign onto the Azure Container Group."
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
  description = "Caddy container configuration object to create caddy reverse proxy aci."
}