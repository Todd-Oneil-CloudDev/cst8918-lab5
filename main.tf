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
  security_rule {
    description = "inbound ssh"
    name = "inbound-ssh"
    priority = 102
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    }
  security_rule {
    description = "inbound web"
    name = "inbound-web"
    priority = 103
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "80"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    }
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

# assign the NSG only to the NIC outlined above
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

data "cloudinit_config" "ws-init" {
  gzip = false
  base64_encode = true

  part {
    filename = "init.sh"
    content_type = "text/x-shellscript"
    content = file("${path.module}/init.sh")
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name = "${var.labelPrefix}-vm"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location = azurerm_resource_group.resourceGroup.location
  size = "Standard_B2s"
  network_interface_ids = [ azurerm_network_interface.nic.id ]
  admin_username = var.admin_username
  custom_data = data.cloudinit_config.ws-init.rendered

  admin_ssh_key {
    username = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching = "ReadWrite"
  }
}

output "rg-name" {
  value = azurerm_resource_group.resourceGroup.name
}
output "public-ip" {
  value = azurerm_public_ip.pip.ip_address
}