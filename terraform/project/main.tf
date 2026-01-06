locals {
  resource_group_name = "rg-${var.workload}-${var.environment_prefix}-${var.suffix}"
  actual_data_location = var.data_location != "" ? var.data_location : var.location
}

module "resource_group" {
  source = "../modules/azurerm/resource_group"

  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}

module "vnet" {
  source = "../modules/azurerm/virtual_network"

  name                = "vnet-${var.workload}-${var.environment_prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags
}

module "subnet_apim" {
  source = "../modules/azurerm/subnet"

  name                 = "snet-apim"
  resource_group_name  = module.resource_group.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

module "subnet_pe" {
  source = "../modules/azurerm/subnet"

  name                 = "snet-pe"
  resource_group_name  = module.resource_group.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

module "network_security_group" {
  source = "../modules/azurerm/network_security_group"

  name                = "nsg-apim"
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags

  security_rules = [
    {
      name                       = "AllowApimManagement"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3443"
      source_address_prefix      = "ApiManagement"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "AllowClientAccess"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "AllowAzureLoadBalancer"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "6390"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "VirtualNetwork"
    }
  ]
}

module "nsg_association" {
  source = "../modules/azurerm/nsg_association"

  subnet_id                 = module.subnet_apim.id
  network_security_group_id = module.network_security_group.id
}

module "api_management" {
  source = "../modules/azurerm/api_management"

  name                = "apim-${var.workload}-${var.environment_prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = module.resource_group.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email
  sku                 = var.apim_sku
  sku_count           = var.apim_sku_count
  tags                = var.tags

  subnet_id            = module.subnet_apim.id
  virtual_network_type = "External"
}

module "api_management_backend" {
  source = "../modules/azurerm/api_management_backend"

  name                = "openai-backend"
  resource_group_name = module.resource_group.name
  api_management_name = module.api_management.name
  protocol            = "http"
  url                 = "${trimsuffix(module.cognitive.endpoint, "/")}/openai"
}

module "api_management_api" {
  source = "../modules/azurerm/api_management_api"

  name                  = "openai-api"
  resource_group_name   = module.resource_group.name
  api_management_name   = module.api_management.name
  revision              = "1"
  display_name          = "Azure OpenAI API"
  path                  = "openai"
  protocols             = ["https"]
  service_url           = module.cognitive.endpoint
  subscription_required = false
  content_format        = "openapi-link"
  content_value         = "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable/2024-02-01/inference.json"
}

module "api_management_api_policy" {
  source = "../modules/azurerm/api_management_api_policy"

  api_name            = module.api_management_api.name
  api_management_name = module.api_management.name
  resource_group_name = module.resource_group.name

  xml_content = <<XML
<policies>
  <inbound>
    <cors allow-credentials="false">
      <allowed-origins>
        <origin>*</origin>
      </allowed-origins>
      <allowed-methods>
        <method>GET</method>
        <method>POST</method>
        <method>OPTIONS</method>
      </allowed-methods>
      <allowed-headers>
        <header>*</header>
      </allowed-headers>
    </cors>
    <llm-token-limit
      counter-key="@(context.Request.IpAddress)"
      tokens-per-minute="5000"
      token-quota="50000"
      token-quota-period="Hourly"
      estimate-prompt-tokens="true"
      remaining-tokens-variable-name="remainingTokens"
      tokens-consumed-variable-name="tokensConsumed" />
    <base />
    <set-backend-service backend-id="${module.api_management_backend.name}" />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML
}

module "storage_account" {
  source = "../modules/azurerm/storage_account"

  name                = "st${var.workload}${var.environment_prefix}${var.suffix}"
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags
}

module "key_vault" {
  source = "../modules/azurerm/key_vault"

  name                = "kv-${var.workload}-${var.environment_prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags
}

module "log_analytics" {
  source = "../modules/azurerm/log_analytics"

  name                = "log-${var.workload}-${var.environment_prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags
}

module "application_insights" {
  source = "../modules/azurerm/application_insights"

  name                = "appi-${var.workload}-${var.environment_prefix}-${var.suffix}"
  location            = var.location
  resource_group_name = module.resource_group.name
  workspace_id        = module.log_analytics.id
  tags                = var.tags
}

module "cognitive" {
  source = "../modules/azurerm/cognitive/"

  name                    = "${var.workload}-${var.environment_prefix}-${var.suffix}"
  location                = var.location
  resource_group_name     = module.resource_group.name
  storage_account_id      = module.storage_account.id
  key_vault_id            = module.key_vault.id
  application_insights_id = module.application_insights.id
  tags                    = var.tags

  enable_private_networking = true
}

module "cognitive_private_dns_zone" {
  source = "../modules/azurerm/private_dns_zone"

  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = module.resource_group.name
  tags                = var.tags
}

module "cognitive_private_endpoint" {
  source = "../modules/azurerm/private_endpoint"

  name                           = "${var.workload}-${var.environment_prefix}-${var.suffix}"
  location                       = var.location
  resource_group_name            = module.resource_group.name
  subnet_id                      = module.subnet_pe.id
  private_connection_resource_id = module.cognitive.id
  subresource_names              = ["account"]
  private_dns_zone_ids           = [module.cognitive_private_dns_zone.id]
  tags                           = var.tags
}

module "cognitive_private_dns_zone_virtual_network_link" {
  source = "../modules/azurerm/private_dns_zone_virtual_network_link"

  name                  = "pdznl-${var.workload}-${var.environment_prefix}-${var.suffix}"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = module.cognitive_private_dns_zone.name
  virtual_network_id    = module.vnet.vnet_id
}

module "cognitive_project" {
  source = "../modules/azurerm/cognitive_project"

  name                 = "${var.workload}-${var.environment_prefix}-${var.suffix}"
  location             = var.location
  cognitive_account_id = module.cognitive.id
  tags                 = var.tags
}

module "cognitive_deployment" {
  source = "../modules/azurerm/cognitive_deployment"

  deployment_name      = var.openai_deployment_name
  cognitive_account_id = module.cognitive.id
  model_name           = var.openai_model_name
  model_version        = var.openai_model_version
  model_sku_name       = var.openai_model_sku_name
  model_sku_capacity   = var.openai_model_sku_capacity

  depends_on = [ module.cognitive_project ]
}

