output "id" {
  description = "The ID of the API Management Service"
  value       = azurerm_api_management.apim.id
}

output "name" {
  description = "The name of the API Management Service"
  value       = azurerm_api_management.apim.name
}

output "private_ip_addresses" {
  description = "The Private IP addresses of the API Management Service"
  value       = azurerm_api_management.apim.private_ip_addresses
}


