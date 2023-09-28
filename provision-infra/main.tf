provider "azurerm" {
  version = "=3.0.0"
  features {}
    /*backend "azurerm" {
    resource_group_name  = "ISS-IAC"
    storage_account_name = "tfstoragestateiss001"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    storage_account_access_key = data.azurerm_storage_account.storage_account.primary_access_key
  }*/
}
# Define a variable to set a prefix for resource names
variable "deployment_name_prefix" {
  description = "A prefix for resource names"
  type        = string
  default     = "myapp"
}

# Create an Azure resource group with a name that includes the deployment name prefix

resource "azurerm_resource_group" "rg" {
  name     = "${var.deployment_name_prefix}-ISS-IAC"
  location = "swedencentral"
}

# Create an Azure virtual network with a name that includes the deployment name prefix
resource "azurerm_virtual_network" "vnet" {
    name                = "${var.deployment_name_prefix}-issswevnet"
    address_space       = ["10.40.0.0/16"]
    location            = "swedencentral"
    resource_group_name = azurerm_resource_group.rg.name

    tags = {
        environment = "dev"
    }
}

# Create an Azure subnet for the app service with a name that includes the deployment name prefix

resource "azurerm_subnet" "apps" {
  name                 = "${var.deployment_name_prefix}-apps-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.40.0.0/25"]
  delegation {
    name = "appservice-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Create an Azure subnet for the API app service with a name that includes the deployment name prefix

resource "azurerm_subnet" "apis" {
    name                 = "${var.deployment_name_prefix}-apis-subnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.40.1.0/24"]
    delegation {
    name = "apiappservice-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
    }
}

# Create a new App Service Plan (compute for App Service)

resource "azurerm_service_plan" "app_service_plan" {
    name                = "${var.deployment_name_prefix}-linuxasp"
    location            = "swedencentral"
    resource_group_name = azurerm_resource_group.rg.name

    sku_name = "B1"
    os_type = "Linux"
}

# Create a new App Service

resource "azurerm_linux_web_app" "app_service" {
    name                = "${var.deployment_name_prefix}-myappservice"
    location            = "swedencentral"
    resource_group_name = azurerm_resource_group.rg.name
    service_plan_id = azurerm_service_plan.app_service_plan.id

    site_config {
        always_on = true
    }

    app_settings = {
        "WEBSITE_LOAD_USER_PROFILE" = "1"
    }

    depends_on = [
        azurerm_subnet.apps,
        azurerm_subnet.apis
    ]
}
resource "azurerm_app_service_virtual_network_swift_connection" "example" {
  app_service_id = azurerm_linux_web_app.app_service.id
  subnet_id      = azurerm_subnet.apps.id
}
# Create a new Cognitive Services resource

 resource "azurerm_cognitive_account" "cognitive_account" {
    name                = "${var.deployment_name_prefix}-isstestcognitiveaccount"
    location            = "swedencentral"
    resource_group_name = azurerm_resource_group.rg.name
    kind                = "CognitiveServices"
    sku_name            = "S0"
    identity {
      type = "SystemAssigned"
    }

}

# Create a new private endpoint for the Cognitive Services resource

resource "azurerm_private_endpoint" "cognitive_account" {
    name                = "${var.deployment_name_prefix}-mycognitiveaccount-pec"
    location            = "swedencentral"
    resource_group_name = azurerm_resource_group.rg.name
    subnet_id           = azurerm_subnet.apis.id

    private_service_connection {
        name                           = "isscognitiveaccount_psc"
        is_manual_connection           = false
        subresource_names              = ["searchService"]
        private_connection_resource_id = azurerm_cognitive_account.cognitive_account.id
    }
    depends_on = [ azurerm_cognitive_account.cognitive_account ]
}
