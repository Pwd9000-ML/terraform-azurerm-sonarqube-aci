[![Automated-Dependency-Tests-and-Release](https://github.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/actions/workflows/dependency-tests.yml/badge.svg)](https://github.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/actions/workflows/dependency-tests.yml) [![Dependabot](https://badgen.net/badge/Dependabot/enabled/green?icon=dependabot)](https://dependabot.com/)

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

**Sonarqube** is exposed over TCP port 9000, and uses a production-ready reverse proxy [(caddy)](https://caddyserver.com/docs/) using the [sidecar pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/sidecar). Caddy will "automagically" take care of the SSL certificate setup, configuration and automatically proxy traffic to the sonarqube instance using ['Lets Encrypt certs'](https://letsencrypt.org/). Caddy requires **zero configuration** and provides out of the box secure **https://** access to your sonarqube instance using your own **custom domain**.

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
    enable_https_traffic_only = true
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
    container_image                 = "caddy:latest" #Check for more versions/tags here: https://hub.docker.com/_/caddy
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
```

**NOTE:** Remember to create a **DNS 'CNAME'** record on your DNS provider to point your **"custom.domain.com"** to **(dnslabel).(azureregion).azurecontainer.io**
