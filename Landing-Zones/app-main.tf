provider "azapi" {
}

provider "azurerm" {
  skip_provider_registration = true

  features {
  }
  storage_use_azuread = true # enable this only after Apps' code has been updated to use system assigned identity
  # This flag can introduce errors. One potential error is that the authentication does not work 
  # because Azure did not back integrate the new Storage Account roles to previous Owner role. 
  # If this happens, try to reassign or recreate a Service Principal with Owner rights for Terraform agent.
}

terraform {
  backend "azurerm" {
    key              = "app.tfstate"
    use_azuread_auth = true
  }
}

locals {
  name       = var.name == null ? var.landing_zone_name : var.name
  name_short = var.name_short == null ? var.landing_zone_name_short : var.name_short

  resource_name_prefix       = var.variant == null || var.variant == "" ? local.name : "${local.name}-${var.variant}"
  resource_name_prefix_short = var.variant == null || var.variant == "" ? local.name_short : "${local.name_short}-${var.variant}"

  target_resource_group_name = azurerm_resource_group.target.name
  target_location            = var.location
}

data "azurerm_client_config" "current" {
}

data "azurerm_subscription" "current" {
}

module "landing_zone" {
  source = "git::https://.........."

  name       = var.landing_zone_name
  name_short = var.landing_zone_name_short
  variant    = var.variant
  namespace  = var.namespace

  application_insights = [""]
}

resource "azurerm_resource_group" "target" {
  name     = "rg-${local.resource_name_prefix}-app"
  location = local.target_location

  lifecycle {
    ignore_changes = [
      tags["AppAdoItId"],
      tags["Stage"],
    ]
  }
}
