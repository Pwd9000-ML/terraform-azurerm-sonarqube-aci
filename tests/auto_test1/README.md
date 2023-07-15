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
| <a name="module_sonarcube-aci"></a> [sonarcube-aci](#module\_sonarcube-aci) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [random_integer.number](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_sonarqube_rg_name"></a> [sonarqube\_rg\_name](#input\_sonarqube\_rg\_name) | Name of the existing resource group. (var.create\_rg=false) / Name of the resource group to create. (var.create\_rg=true). | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->