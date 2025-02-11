# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "<subscription id>"
  client_id       = "<service principal app id>"
  client_secret   = "<service principal password>"
  tenant_id       = "<service principal tenant id>"
}
resource "azurerm_resource_group" "rg" {
        name = "WTHTFRG"
        location = "eastus"
}
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "WTHVNetTF"
    address_space       = ["10.1.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.rg.name}"

    tags = {
        environment = "WTH Terraform"
    }
}

resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "default"
    resource_group_name  = "${azurerm_resource_group.rg.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.1.0.0/24"
}

resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "WTHNSG"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.rg.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "WTH Terraform"
    }
}
