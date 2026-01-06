output "endpoint" {
  value = azurerm_cognitive_account.account.endpoint
}

output "primary_access_key" {
  value     = azurerm_cognitive_account.account.primary_access_key
  sensitive = true
}

output "name" {
  value = azurerm_cognitive_account.account.name
}

output "id" {
  value = azurerm_cognitive_account.account.id
}

