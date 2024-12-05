provider "azurerm" {
  skip_provider_registration = true

  features {
  }
  storage_use_azuread = true # enable this only after Apps' code has been updated to use system assigned identity
  # This flag can introduce errors. One potential error is that the authentication does not work 
  # because Azure did not back integrate the new Storage Account roles to previous Owner role. 
  # If this happens, try to reassign or recreate a Service Principal with Owner rights for Terraform agent.
}

data "azurerm_client_config" "current" {
}

data "terraform_remote_state" "app" {
  backend = "azurerm"

  config = {
    storage_account_name = var.backend_storage_account_name
    container_name       = var.backend_container_name
    key                  = "app.tfstate"

    use_azuread_auth = true
  }

  defaults = {
    key_vault = {
      name = "undefined"
    }
  }
}

locals {
  name       = var.name == null ? var.landing_zone_name : var.name
  name_short = var.name_short == null ? var.landing_zone_name_short : var.name_short

  resource_name_prefix       = var.variant == null || var.variant == "" ? local.name : "${local.name}-${var.variant}"
  resource_name_prefix_short = var.variant == null || var.variant == "" ? local.name_short : "${local.name_short}-${var.variant}"

}

module "landing_zone" {
  source = "git::https://........."

  name       = var.landing_zone_name
  name_short = var.landing_zone_name_short
  variant    = var.variant
  namespace  = var.namespace
}

resource "azurerm_cosmosdb_account" "instance" {
  name                               = "cosmos-${var.namespace}-${local.resource_name_prefix}-main"
  location                           = var.location
  resource_group_name                = data.terraform_remote_state.app.outputs.target_resource_group.name
  default_identity_type              = join("=", ["UserAssignedIdentity", module.landing_zone.customer_managed_key.key_msi_id])
  offer_type                         = "Standard"
  local_authentication_disabled      = true
  access_key_metadata_writes_enabled = false
  key_vault_key_id                   = module.landing_zone.customer_managed_key.key_cmk_versionless_id
  public_network_access_enabled      = var.public_access

  ip_range_filter = join(",", var.kfw_allowed_ip_ranges)

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level = "Strong"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [data.terraform_remote_state.app.outputs.backend_identity_id, module.landing_zone.customer_managed_key.key_msi_id]
  }

  lifecycle {
    ignore_changes = [
      tags["AppAdoItId"],
      tags["Stage"]
    ]
  }
}

resource "azurerm_key_vault_secret" "cosmos_db_secrets" {
  for_each = {
    "COSMOS-DB-URI" = azurerm_cosmosdb_account.instance.endpoint
  }

  name            = each.key
  value           = each.value
  key_vault_id    = data.terraform_remote_state.app.outputs.key_vault.id
  expiration_date = var.secret_expiration_date
  content_type    = "Credential"
}

resource "azurerm_private_endpoint" "cosmosdb" {
  name                = "pe-${local.resource_name_prefix_short}-cosmosdb"
  resource_group_name = data.terraform_remote_state.app.outputs.target_resource_group.name
  location            = data.terraform_remote_state.app.outputs.target_location

  subnet_id = module.landing_zone.spoke.subnets.backend_tier_endpoints.id

  private_service_connection {
    name                           = "pc-${azurerm_cosmosdb_account.instance.name}-cosmosdb"
    private_connection_resource_id = azurerm_cosmosdb_account.instance.id
    is_manual_connection           = false
    subresource_names              = ["SQL"]
  }

  lifecycle {
    ignore_changes = [
      private_dns_zone_group,
      tags["AppAdoItId"],
      tags["Stage"],
    ]
  }
}

resource "azurerm_cosmosdb_sql_database" "default" {
  name                = "jaki-db"
  resource_group_name = azurerm_cosmosdb_account.instance.resource_group_name
  account_name        = azurerm_cosmosdb_account.instance.name
}

resource "azurerm_cosmosdb_sql_container" "hgps" {
  name                  = "hgps"
  resource_group_name   = azurerm_cosmosdb_account.instance.resource_group_name
  account_name          = azurerm_cosmosdb_account.instance.name
  database_name         = azurerm_cosmosdb_sql_database.default.name
  partition_key_path    = "/id"
  partition_key_version = 1

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }
  }
}

resource "azurerm_cosmosdb_sql_container" "documents" {
  name                  = "documents"
  resource_group_name   = azurerm_cosmosdb_account.instance.resource_group_name
  account_name          = azurerm_cosmosdb_account.instance.name
  database_name         = azurerm_cosmosdb_sql_database.default.name
  partition_key_path    = "/id"
  partition_key_version = 1

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }
  }
}

resource "azurerm_cosmosdb_sql_container" "comments" {
  name                  = "comments"
  resource_group_name   = azurerm_cosmosdb_account.instance.resource_group_name
  account_name          = azurerm_cosmosdb_account.instance.name
  database_name         = azurerm_cosmosdb_sql_database.default.name
  partition_key_path    = "/id"
  partition_key_version = 1

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }
  }
}

resource "azurerm_cosmosdb_sql_role_definition" "default" {
  resource_group_name = azurerm_cosmosdb_account.instance.resource_group_name
  account_name        = azurerm_cosmosdb_account.instance.name
  name                = "csrd-write-jaki-${var.variant}-db"
  assignable_scopes   = ["${azurerm_cosmosdb_account.instance.id}/dbs/jaki-db"]

  permissions {
    data_actions = [
      "Microsoft.DocumentDB/databaseAccounts/readMetadata",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*"
    ]
  }
}

resource "azurerm_cosmosdb_sql_role_definition" "readonly" {
  resource_group_name = azurerm_cosmosdb_account.instance.resource_group_name
  account_name        = azurerm_cosmosdb_account.instance.name
  name                = "csrd-read-jaki-${var.variant}-db"
  assignable_scopes   = ["${azurerm_cosmosdb_account.instance.id}/dbs/jaki-db"]

  permissions {
    data_actions = [
      "Microsoft.DocumentDB/databaseAccounts/readMetadata",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/read",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/executeQuery",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/readChangeFeed",
    ]
  }
}

resource "azurerm_cosmosdb_sql_role_assignment" "default" {
  resource_group_name = azurerm_cosmosdb_account.instance.resource_group_name
  account_name        = azurerm_cosmosdb_account.instance.name
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.default.id
  principal_id        = data.terraform_remote_state.app.outputs.backend_identity_principal_id
  scope               = "${azurerm_cosmosdb_account.instance.id}/dbs/jaki-db"
}

resource "azurerm_cosmosdb_sql_role_assignment" "read_user" {
  for_each            = toset(var.read_principal_ids)
  resource_group_name = azurerm_cosmosdb_account.instance.resource_group_name
  account_name        = azurerm_cosmosdb_account.instance.name
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.readonly.id
  principal_id        = each.value
  scope               = "${azurerm_cosmosdb_account.instance.id}/dbs/jaki-db"
}

resource "azurerm_cosmosdb_sql_role_assignment" "write_user" {
  for_each            = toset(var.write_principal_ids)
  resource_group_name = azurerm_cosmosdb_account.instance.resource_group_name
  account_name        = azurerm_cosmosdb_account.instance.name
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.default.id
  principal_id        = each.value
  scope               = "${azurerm_cosmosdb_account.instance.id}/dbs/jaki-db"
}
