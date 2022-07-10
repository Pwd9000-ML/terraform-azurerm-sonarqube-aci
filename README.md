# terraform-azurerm-sonarqube-aci
Public registry module

Public Terraform Registry module for setting up an AZURE hosted Sonarqube ACI instance incl. persistent PaaS Database (Azure SQL), PaaS File Share (Azure Files) and custom domain using reverse proxy (Caddy) sidecar container.

This module will build the following azure resources:

- Azure Resource Group
- Azure Storage account and file shares
- Azure SQL instance and external database
- Azure Container Group containing:
  - SonarQube container instance
  - Caddy Reverse Proxy container instance
