resource "azurerm_storage_account" "storage" {
  name                             = var.name
  location                         = var.location
  resource_group_name              = var.resource_group_name
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  shared_access_key_enabled        = false
  allow_nested_items_to_be_public  = false
  cross_tenant_replication_enabled = true
  tags                             = var.tags
}
