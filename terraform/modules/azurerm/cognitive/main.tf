resource "azurerm_cognitive_account" "account" {
  name                          = "cog-${var.name}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "AIServices"
  project_management_enabled    = true
  custom_subdomain_name         = "cog-${var.name}"
  public_network_access_enabled = var.enable_private_networking ? false : true
  local_auth_enabled            = false

  sku_name = "S0"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
