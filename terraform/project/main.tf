module "resource_group" {
  source = "../modules/azurerm/resource_group"

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
