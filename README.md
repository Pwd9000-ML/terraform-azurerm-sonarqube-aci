[![Manual-Tests-and-Release](https://github.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/actions/workflows/manual-test-release.yml/badge.svg)](https://github.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/actions/workflows/manual-test-release.yml) [![Automated-Dependency-Tests-and-Release](https://github.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/actions/workflows/dependency-tests.yml/badge.svg)](https://github.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/actions/workflows/dependency-tests.yml) [![Dependabot](https://badgen.net/badge/Dependabot/enabled/green?icon=dependabot)](https://dependabot.com/)

# Module: Sonarqube Azure Container Instance (+ Automatic SSL)

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/master/assets/caddy02.png)

## Description

Public Terraform Registry module for setting up an AZURE hosted **Sonarqube Azure Container Instance (ACI)** including: persistent PaaS Database **(Azure SQL)**, persistent PaaS File Shares **(Azure Files)** and support for custom domain using reverse proxy **(Caddy)** sidecar container.  

Also see this module for creating a **VNET integrated** instance of SonarQube using a private `.local` DNS zone and self-signed Certificate. [VNET integrated SonarQube Azure Container Instance (+ Automatic SSL self-signed certificate)](https://github.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci-internal).  

The module will build the following Azure resources:

- Azure Resource Group (Optional)
- Azure Key Vault (Used to store MSSQL sa username and password)
- Azure Storage account and file shares (Used for persistent storage for sonarqube container)
- Azure MSSQL instance and MSSQL database (Used for persistent database for sonarqube container)
- Azure Container Group:
  - Sonarqube container instance
  - Caddy Reverse Proxy container instance (Automatic SSL for custom domain via Let's Encrypt)

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/master/assets/rg.png)

**Sonarqube** is exposed over TCP port 9000, and uses a production-ready reverse proxy [(caddy)](https://caddyserver.com/docs/) using the [sidecar pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/sidecar/?wt.mc_id=DT-MVP-5004771). Caddy will "automagically" take care of the SSL certificate setup, configuration and automatically proxy traffic to the sonarqube instance using ['Lets Encrypt certs'](https://letsencrypt.org/). Caddy requires **zero configuration** and provides out of the box secure **https://** access to your sonarqube instance using your own **custom domain**.

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/master/assets/caddy01.png)

**NOTE:** There are some [rate limits](https://letsencrypt.org/docs/rate-limits/) using **Let's Encrypt**

More information can also be found here: [caddy documentation](https://caddyserver.com/docs/quick-starts/reverse-proxy).  
Custom domain can be configured by giving your **"custom.domain.com"** value in the variable, `var.caddy_config` as shown in the snippet below.  
See [Examples](https://github.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/tree/master/examples) for more details.  

```hcl
#Terraform caddy container commands:
container_commands = ["caddy", "reverse-proxy", "--from", "custom.domain.com", "--to", "localhost:9000"]
```

After resource creation, get the DNS-Label of the container group: **(dnslabel).(azureregion).azurecontainer.io**:

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/master/assets/dnslabel02.png)

Ensure you create a **DNS 'CNAME'** on your DNS provider for your **'custom.domain.com'** to point to the DNS label FQDN of the ACI container group.

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/master/assets/dns01.png)

Once the sonarqube instance is up and running, log in and change the default password:

- **User:** _Admin_
- **Password:** _Admin_

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/master/assets/default.png)

Sonarqube container image reference: [Sonarqube docker image tags](https://hub.docker.com/_/sonarqube)  
Caddy container image reference: [Caddy docker image tags](https://hub.docker.com/_/caddy)

## Example 1

Simple example where the entire solution is built in a new Resource Group (Default).  
This example requires very limited input. Only specify an Azure Resource Group and **required** variable values and supply your own **custom domain (FQDN)** you want to link to the Let's encrypt cert using `caddy_config` and the container group DNS label using `aci_dns_label`.  

```hcl
provider "azurerm" {
  features {}
}

resource "random_integer" "number" {
  min = 0001
  max = 9999
}

module "sonarcube-aci" {
  source = "Pwd9000-ML/sonarqube-aci/azurerm"

  sonarqube_rg_name = "Terraform-Sonarqube-aci-simple-demo"
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
    access_tier               = "Hot"
    is_hns_enabled            = false
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
```

**NOTE:** Remember to create a **DNS 'CNAME'** record on your DNS provider to point your **"custom.domain.com"** to **(dnslabel).(azureregion).azurecontainer.io**

## Example 2

Advanced example where the entire solution is built in an existing Resource Group (And supplying all possible variable values).  
This example shows all configurable inputs.

```hcl
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
  pass_length        = 24
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
    container_image                 = "ghcr.io/metrostar/quartz/ironbank/big-bang/sonarqube-9:9.9.4-community"
    container_cpu                   = 2
    container_memory                = 8
    container_environment_variables = null
    container_commands              = []
  }
  caddy_config = {
    container_name                  = "caddy-reverse-proxy"
    container_image                 = "ghcr.io/sashkab/docker-caddy2/docker-caddy2:latest"
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
```

**NOTE:** Remember to create a **DNS 'CNAME'** record on your DNS provider to point your **"custom.domain.com"** to **(dnslabel).(azureregion).azurecontainer.io**

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.5 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.110.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.110.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_container_group.sonarqube_aci](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group) | resource |
| [azurerm_key_vault.sonarqube_kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_key_vault_secret.password_secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.username_secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_mssql_database.sonarqube_mssql_db](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_database) | resource |
| [azurerm_mssql_firewall_rule.sonarqube_mssql_fw_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_firewall_rule) | resource |
| [azurerm_mssql_server.sonarqube_mssql](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_server) | resource |
| [azurerm_resource_group.sonarqube_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.kv_role_assigment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_storage_account.sonarqube_sa](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_share.sonarqube](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) | resource |
| [azurerm_storage_share_file.sonar_properties](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share_file) | resource |
| [random_password.sql_admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_resource_group.sonarqube_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aci_dns_label"></a> [aci\_dns\_label](#input\_aci\_dns\_label) | DNS label to assign onto the Azure Container Group. | `string` | n/a | yes |
| <a name="input_aci_group_config"></a> [aci\_group\_config](#input\_aci\_group\_config) | Container group configuration object to create sonarqube aci with caddy reverse proxy. | <pre>object({<br>    container_group_name = string<br>    ip_address_type      = string<br>    os_type              = string<br>    restart_policy       = string<br>  })</pre> | n/a | yes |
| <a name="input_caddy_config"></a> [caddy\_config](#input\_caddy\_config) | Caddy container configuration object to create caddy reverse proxy aci. | <pre>object({<br>    container_name                  = string<br>    container_image                 = string<br>    container_cpu                   = number<br>    container_memory                = number<br>    container_environment_variables = map(string)<br>    container_commands              = list(string)<br>  })</pre> | <pre>{<br>  "container_commands": [<br>    "caddy",<br>    "reverse-proxy",<br>    "--from",<br>    "custom.domain.com",<br>    "--to",<br>    "localhost:9000"<br>  ],<br>  "container_cpu": 1,<br>  "container_environment_variables": null,<br>  "container_image": "ghcr.io/sashkab/docker-caddy2/docker-caddy2:latest",<br>  "container_memory": 1,<br>  "container_name": "caddy-reverse-proxy"<br>}</pre> | no |
| <a name="input_create_rg"></a> [create\_rg](#input\_create\_rg) | Create a new resource group for this deployment. (Set to false to use existing resource group) | `bool` | `true` | no |
| <a name="input_kv_config"></a> [kv\_config](#input\_kv\_config) | Key Vault configuration object to create azure key vault to store sonarqube aci sql creds. | <pre>object({<br>    name = string<br>    sku  = string<br>  })</pre> | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Location in azure where resources will be created. (Only in effect on newly created Resource Group when var.create\_rg=true) | `string` | `"uksouth"` | no |
| <a name="input_mssql_config"></a> [mssql\_config](#input\_mssql\_config) | MSSQL configuration object to create persistent SQL server instance for sonarqube aci. | <pre>object({<br>    name    = string<br>    version = string<br>  })</pre> | n/a | yes |
| <a name="input_mssql_db_config"></a> [mssql\_db\_config](#input\_mssql\_db\_config) | MSSQL database configuration object to create persistent azure SQL db for sonarqube aci. | <pre>object({<br>    db_name                     = string<br>    collation                   = string<br>    create_mode                 = string<br>    license_type                = string<br>    max_size_gb                 = number<br>    min_capacity                = number<br>    auto_pause_delay_in_minutes = number<br>    read_scale                  = bool<br>    sku_name                    = string<br>    storage_account_type        = string<br>    zone_redundant              = bool<br>    point_in_time_restore_days  = number<br>    backup_interval_in_hours    = number<br>  })</pre> | <pre>{<br>  "auto_pause_delay_in_minutes": 60,<br>  "backup_interval_in_hours": 24,<br>  "collation": "SQL_Latin1_General_CP1_CS_AS",<br>  "create_mode": "Default",<br>  "db_name": "sonarqubemssqldb9000",<br>  "license_type": null,<br>  "max_size_gb": 128,<br>  "min_capacity": 1,<br>  "point_in_time_restore_days": 7,<br>  "read_scale": false,<br>  "sku_name": "GP_S_Gen5_2",<br>  "storage_account_type": "Zone",<br>  "zone_redundant": false<br>}</pre> | no |
| <a name="input_mssql_fw_rules"></a> [mssql\_fw\_rules](#input\_mssql\_fw\_rules) | List of SQL firewall rules in format: [[rule1, startIP, endIP],[rule2, startIP, endIP]] etc. | `list(list(string))` | <pre>[<br>  [<br>    "Allow All Azure IPs",<br>    "0.0.0.0",<br>    "0.0.0.0"<br>  ]<br>]</pre> | no |
| <a name="input_pass_length"></a> [pass\_length](#input\_pass\_length) | Password length for sql admin creds. (Stored in sonarqube key vault) | `number` | `36` | no |
| <a name="input_sa_config"></a> [sa\_config](#input\_sa\_config) | Storage configuration object to create persistent azure file shares for sonarqube aci. | <pre>object({<br>    name                     = string<br>    account_kind             = string<br>    account_tier             = string<br>    account_replication_type = string<br>    access_tier              = string<br>    min_tls_version          = string<br>    is_hns_enabled           = bool<br>  })</pre> | n/a | yes |
| <a name="input_shares_config"></a> [shares\_config](#input\_shares\_config) | Sonarqube file shares | <pre>list(object({<br>    share_name = string<br>    quota_gb   = number<br>  }))</pre> | <pre>[<br>  {<br>    "quota_gb": 10,<br>    "share_name": "data"<br>  },<br>  {<br>    "quota_gb": 10,<br>    "share_name": "extensions"<br>  },<br>  {<br>    "quota_gb": 10,<br>    "share_name": "logs"<br>  },<br>  {<br>    "quota_gb": 1,<br>    "share_name": "conf"<br>  }<br>]</pre> | no |
| <a name="input_sonar_config"></a> [sonar\_config](#input\_sonar\_config) | Sonarqube container configuration object to create sonarqube aci. | <pre>object({<br>    container_name                  = string<br>    container_image                 = string<br>    container_cpu                   = number<br>    container_memory                = number<br>    container_environment_variables = map(string)<br>    container_commands              = list(string)<br>  })</pre> | <pre>{<br>  "container_commands": [],<br>  "container_cpu": 2,<br>  "container_environment_variables": null,<br>  "container_image": "ghcr.io/metrostar/quartz/ironbank/big-bang/sonarqube-9:9.9.4-community",<br>  "container_memory": 8,<br>  "container_name": "sonarqube-server"<br>}</pre> | no |
| <a name="input_sonarqube_rg_name"></a> [sonarqube\_rg\_name](#input\_sonarqube\_rg\_name) | Name of the existing resource group. (var.create\_rg=false) / Name of the resource group to create. (var.create\_rg=true). | `string` | `"Terraform-Sonarqube-aci"` | no |
| <a name="input_sql_admin_username"></a> [sql\_admin\_username](#input\_sql\_admin\_username) | Username for sql admin creds. (Stored in sonarqube key vault) | `string` | `"Sonar-Admin"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of key value pairs that is used to tag resources created. | `map(string)` | <pre>{<br>  "Author": "Marcel Lupo",<br>  "Description": "Sonarqube aci with caddy",<br>  "GitHub": "https://github.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci",<br>  "Terraform": "True"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sonarqube_aci_container_group_id"></a> [sonarqube\_aci\_container\_group\_id](#output\_sonarqube\_aci\_container\_group\_id) | The container group ID. |
| <a name="output_sonarqube_aci_kv_id"></a> [sonarqube\_aci\_kv\_id](#output\_sonarqube\_aci\_kv\_id) | The resource ID for the sonarqube key vault. |
| <a name="output_sonarqube_aci_mssql_db_id"></a> [sonarqube\_aci\_mssql\_db\_id](#output\_sonarqube\_aci\_mssql\_db\_id) | The resource ID for the sonarqube MSSQL database. |
| <a name="output_sonarqube_aci_mssql_db_name"></a> [sonarqube\_aci\_mssql\_db\_name](#output\_sonarqube\_aci\_mssql\_db\_name) | The name of the sonarqube MSSQL database. |
| <a name="output_sonarqube_aci_mssql_id"></a> [sonarqube\_aci\_mssql\_id](#output\_sonarqube\_aci\_mssql\_id) | The resource ID for the sonarqube MSSQL Server instance. |
| <a name="output_sonarqube_aci_rg_id"></a> [sonarqube\_aci\_rg\_id](#output\_sonarqube\_aci\_rg\_id) | Output Resource Group ID. (Only if new resource group was created as part of this deployment). |
| <a name="output_sonarqube_aci_sa_id"></a> [sonarqube\_aci\_sa\_id](#output\_sonarqube\_aci\_sa\_id) | The resource ID for the sonarqube storage account hosting file shares. |
| <a name="output_sonarqube_aci_share_ids"></a> [sonarqube\_aci\_share\_ids](#output\_sonarqube\_aci\_share\_ids) | List of resource IDs of each of the sonarqube file shares. |
<!-- END_TF_DOCS -->