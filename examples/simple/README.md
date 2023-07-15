# Description

Simple example where the entire solution is built in a new Resource Group (Default).  
This example requires very limited input. Only specify an Azure Resource Group and **required** variable values, and supply your own **custom domain (FQDN)** you want to link to the Let's encrypt cert using `caddy_config` and the container group DNS label using `aci_dns_label`.

## Usage

1. Clone or copy the files in this path to a local directory and open a command prompt.
2. Amend `main.tf` with desired variables.
3. Log into azure using CLI "az login".
4. **BUILD:**

    ```hcl
    terraform init
    terraform plan -out deploy.tfplan
    terraform apply deploy.tfplan
    ```

5. **DESTROY:**

    ```hcl
    terraform plan -destroy -out destroy.tfplan
    terraform apply destroy.tfplan
    ```

## DNS Config

After resource creation, get the DNS-Label of the container group: **(dnslabel).(azureregion).azurecontainer.io** and add a **DNS 'CNAME'** on your DNS provider for your **'custom.domain.com'** to point to the DNS label FQDN of the ACI container group:

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/master/assets/dns01.png)  

## Change the default password

Once the sonarqube instance is up and running, log in and change the default password:

- **User:** _Admin_
- **Password:** _Admin_

![image.png](https://raw.githubusercontent.com/Pwd9000-ML/terraform-azurerm-sonarqube-aci/master/assets/default.png)

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_sonarcube-aci"></a> [sonarcube-aci](#module\_sonarcube-aci) | Pwd9000-ML/sonarqube-aci/azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [random_integer.number](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->