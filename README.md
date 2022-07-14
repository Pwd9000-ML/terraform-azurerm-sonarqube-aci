[![Automated-Dependency-Tests-and-Release](https://github.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/actions/workflows/dependency-tests.yml/badge.svg)](https://github.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/actions/workflows/dependency-tests.yml)

# Module: Sonarqube Azure Container Instance (+ Automatic SSL)

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/release/master/assets/caddy02.png)

## Description

Public Terraform Registry module for setting up an AZURE hosted **Sonarqube Azure Container Instance (ACI)** including: persistent PaaS Database **(Azure SQL)**, persistent PaaS File Shares **(Azure Files)** and support for custom domain using reverse proxy **(Caddy)** sidecar container.  

The module will build the following Azure resources:

- Azure Resource Group (Optional)
- Azure Key Vault (Used to store MSSQL sa username and password)
- Azure Storage account and file shares (Used for persistent storage for sonarqube container)
- Azure MSSQL instance and MSSQL database (Used for persistent database for sonarqube container)
- Azure Container Group:
  - Sonarqube container instance
  - Caddy Reverse Proxy container instance (Automatic SSL for custom domain via Let's Encrypt)

**Sonarqube** is exposed over TCP port 9000, and uses a production-ready reverse proxy [(caddy)](https://caddyserver.com/docs/) using the [sidecar pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/sidecar). Caddy will "automagically" take care of the SSL certificate setup, configuration and automatically proxy traffic to the sonarqube instance using ['Lets Encrypt certs'](https://letsencrypt.org/). Caddy requires **zero configuration** and provides out of the box secure **https://** access to your sonarqube instance using your own **custom domain**.

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/release/master/assets/caddy01.png)

**NOTE:** There are some [rate limits](https://letsencrypt.org/docs/rate-limits/) using **Let's Encrypt**

See **Examples** on caddy usage. More information can also be found here: [caddy documentation](https://caddyserver.com/docs/quick-starts/reverse-proxy).

```hcl
#Terraform caddy container commands:
container_commands = ["caddy", "reverse-proxy", "--from", "custom.domain.com", "--to", "localhost:9000"]
```

After all resources are created, get the DNS-Label of the container group **(sonarqube-aci.<azureregion>.azurecontainer.io)**:

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/release/master/assets/dnslabel.png)

Ensure you create a **DNS 'CNAME'** on your DNS provider for your **'custom.domain.com'** to point to the DNS label of the ACI container group.

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/release/master/assets/dns.png)

Once the sonarqube instance is up and running to log in and change the default password:
**Sonarqube Default Credentials**
User: _Admin_
Password _Admin_

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/release/master/assets/deault.png)

Sonarqube container image reference: [Sonarqube docker image tags](https://hub.docker.com/_/sonarqube)

## Module Input variables

- `tags` - (Optional) A map of key value pairs that is used to tag resources created.
- `location` - (Optional) Location in azure where resources will be created. (Only in effect on newly created Resource Group when `var.create_rg=true`).
- `create_rg` - (Optional) Create a new resource group for this deployment. (Set to `false` to use existing resource group).
- `sonarqube_rg_name` - (Optional) Name of the existing resource group. (`var.create_rg=false`) / Name of the resource group to create. (`var.create_rg=true`).
- `kv_config` - (Optional) Key Vault configuration object to create azure key vault to store sonarqube aci sql creds.
- `sa_config` - (Optional) Storage configuration object to create persistent azure file shares for sonarqube aci..
- `shares_config` - (Optional) Sonarqube file shares: `data`, `extensions`, `logs`, `conf`.
- `pass_length` - (Optional) Password length for sql admin creds. (Stored in sonarqube key vault).
- `sql_admin_username` - (Optional) Username for sql admin creds. (Stored in sonarqube key vault).
- `mssql_config` - (Optional) MSSQL configuration object to create persistent SQL server instance for sonarqube aci.
- `mssql_fw_rules` - (Optional) List of SQL firewall rules in format: `[[rule1, startIP, endIP],[rule2, startIP, endIP]]` etc.
- `mssql_db_config` - (Optional) MSSQL database configuration object to create persistent azure SQL db for sonarqube aci.
- `aci_group_config` - (Optional) Container group configuration object to create sonarqube aci with caddy reverse proxy.
- `sonar_config` - (Optional) Sonarqube container configuration object to create sonarqube aci.
- `caddy_config` - (Optional) Caddy container configuration object to create caddy reverse proxy aci.

## Module Outputs

- `sonarqube_aci_rg_id` - Output Resource Group ID. (Only if new resource group was created as part of this deployment).
- `sonarqube_aci_kv_id` - The resource ID for the sonarqube key vault.
- `sonarqube_aci_sa_id` - The resource ID for the sonarqube storage account hosting file shares.
- `sonarqube_aci_share_ids` - List of resource IDs of each of the sonarqube file shares.
- `sonarqube_aci_mssql_id` - The resource ID for the sonarqube MSSQL Server instance.
- `sonarqube_aci_mssql_db_id` - The resource ID for the sonarqube MSSQL database.
- `sonarqube_aci_mssql_db_name` - The name of the sonarqube MSSQL database.
- `sonarqube_aci_container_group_id` - The container group ID.

## Example 1

Simple example where a new Resource Group and Vnet will be created (Default).  
This example requires no input and will create a new resource group and vnet populated with demo subnets based on the default input variables.  

```hcl
provider "azurerm" {
    features {}
}

module "dynamic-subnets" {
    source  = "github.com/Pwd9000-ML/terraform-azurerm-dynamic-subnets"
}
```

## Example 2

Simple example where a new Vnet with custom DNS will be created in an existing resource group.  
This example requires an existing resource group and will create a new vnet populated with demo subnets based on the default input variables.  

```hcl
provider "azurerm" {
    features {}
}

module "dynamic-subnets" {
    source                  = "github.com/Pwd9000-ML/terraform-azurerm-dynamic-subnets"

    create_rg               = false     #Existing VNET Resource group name must be provided.
    virtual_network_rg_name = "Core-Networking-Rg"
    dns_entries             = ["10.1.0.10", "10.1.0.138"]
}
```

## Example 3

Simple example where subnets are populated dynamically onto an existing Vnet.  
This example requires an existing resource group and VNET that will be populated with demo subnets based on the default input variables.  
This example assumes a network address space of "10.1.0.0/22" with no subnets exists.  
For more advanced examples see: [examples](https://github.com/Pwd9000-ML/terraform-azurerm-dynamic-subnets/tree/master/examples)  

```hcl
provider "azurerm" {
    features {}
}

module "dynamic-subnets" {
    source                  = "github.com/Pwd9000-ML/terraform-azurerm-dynamic-subnets"

    create_rg               = false     #Existing VNET Resource group name must be provided.
    create_vnet             = false     #Existing VNET name must be provided.
    virtual_network_rg_name = "My-ResourceGroup-Name"
    virtual_network_name    = "My-VNET-Name"
}
```
