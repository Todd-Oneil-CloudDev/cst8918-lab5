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