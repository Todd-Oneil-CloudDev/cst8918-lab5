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
  depends_on = [ azurerm_resource_group.resourceGroup ]
}

resource "azurerm_subnet" "main" {
  name = "${var.labelPrefix}-subnet"
  virtual_network_name = azurerm_virtual_network.VNet.name
  resource_group_name = azurerm_resource_group.resourceGroup.name
  address_prefixes = [ "10.0.1.0/24" ]
  depends_on = [ azurerm_virtual_network.VNet ]
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.labelPrefix}-pip"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
  allocation_method   = "Dynamic"
  depends_on = [ azurerm_subnet.main ]
}

# For production it is not recommended to allow "*" for source_address_prefix
# This allows for any IP to reach the SSH port
resource "azurerm_network_security_group" "nsg" {
  name = "${var.labelPrefix}-nsg"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location = azurerm_resource_group.resourceGroup.location
  security_rule = [ 
    {
    name = "inbound-ssh"
    priority = 102
    direction = "Inbound"
    access = "allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    },
    {
    name = "inbound-web"
    priority = 103
    direction = "Inbound"
    access = "allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "80"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    }
   ]
}

resource "azurerm_network_interface" "nic" {
  name = "${var.labelPrefix}-nic"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location = azurerm_resource_group.resourceGroup.location
  
  ip_configuration {
    name = "primary"
    subnet_id = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}