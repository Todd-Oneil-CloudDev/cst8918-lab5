# configure terraform runtime requirements
terraform {
    required_version = ">= 1.1.0"

    required_providers {
      # Azure Resource Manager Provider and Version
      azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 3.0.2"
      }
      cloudinit = {
        source = "hashicorp/cloudinit"
        version = "2.3.3"
      }
    }
}

# Define providers and their configurations
provider "azurerm" {
    # Leave the features block empty to accept all defaults
  features {}
}

provider "cloudinit" {
    # configuration options
}

# Resource Creation And Configuration
resource "azurerm_resource_group" "resourceGroup" {
  name = "${var.labelPrefix}-A05-RG"
  location = var.region
}

resource "azurerm_virtual_network" "VNet" {
  resource_group_name = azurerm_resource_group.resourceGroup.name
  name = "${var.labelPrefix}-vnet"
  location = azurerm_resource_group.resourceGroup.location
  address_space = [ "10.0.0.0/16" ]
  subnet = [ {
    name = "${var.labelPrefix}-subnet"
    address_prefix = "10.0.1.0/24"
} ]
  depends_on = [ azurerm_resource_group.resourceGroup ]
}

