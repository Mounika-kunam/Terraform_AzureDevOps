terraform {
    required_providers {
        azurerm ={
            source = "hashicorp/azurerm"
            version = "=2.46.0"
        }

    }
}

#Configuring the Microsoft Azure Provider
provider "azurerm" {
    features {}
}

terraform {
    backend "azurerm" {
        storage_account_name = "__terraformstorageaccount__"
        container_name       = "tfstate"
        key                  = "terraform.tfstate"
        access_key           = "__storagekey__" #Required to authenticate to AzureStorage acount.
        features {}                             #Rather than defining this inline, the Access key can also be sourced
                                                #from an Environment Variable.   
    }

}


resource "azurerm_resource_group" "rg" {
    name      = "${var.rgname}"
    location  = "${var.rglocation}"
}

resource "azurerm_virtual_network" "vnet1" {
    name                = "${var.prefix}-11"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            =  "${azurem_resource_group.rg.location}"
    address_space       =  ["${var.vnet_cidr_prefix}"]      
}

resource "azurem_subnet" "subnet1" {
    name                 = "subnet1"
    virtual_network_name = "${azurerm_virtual_network.vnet1.name}"
    resource_group_name  = "${azurerm_resource_group.rg.name}"
    address_prefixes     = ["${var.subnet1_cidr_prefix}"]
}

resource "azurerm_network_security_group" "nsg1" {
    name                 = "${var.prefix}-nsg1"
    resource_group_name  = "${azurerm_resource_group.rg.name}"  
    location             = "${azurem_resource_group.rg.location}"   
}

#Below N/w security Rule allows RDP from any network

resource "azurerm_network_security_rule" "rdp" {
    name                               = "rdp"
    resource_group_name                = "${azurerm_resource_group.rg.name}"
    networknetwork_security_group_name = "${azurerm_network_security_group.nsg1.name}"   
    priority                           =  102
    direction                          =  "Inbound"
    access                             =  "Allow"
    protocol                           =  "TCP"
    source_port_range                  =  "*"
    destination_port_range             =  "3389"
    source_address_prefix              =  "*"
    destination_address_prefix         =  "*"

}   

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc" {
    subnet_id                          = azurerem_subnet.subnet1.id
    network_security_group_id          = azurerm_network_security_group.nsg1.id
}

resource "azurerm_network_interface" "nic1" {
    name                    = "${var.prefix}-nic"
    resource_group_name     = azurerm_resource_group.rg.name
    location                = azurerm_resource_group.rg.location

    ip_configuration {
        name                     = "internal"
        subnet_id                =  azurerem_subnet.subnet1.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_windows_virtual_machine" "main" {
    name                    = "${var.prefix}-vm01"
    resource_group_name     = azurerm_resource_group.rg.name
    location                = azurerm_resource_group.rg.location
    size                    = "Standard_B1s"
    admin_username          =  "adminuser"
    admin_password          =  "P@ssw$rd#11"
    network_interface_ids = [azurerm_network_interface.nic1.id]

    source_image_reference {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       =  "2012-2-Datacenter"
      version   =  "latest"
    }

    os_disk {
        storgae_account_type ="Standard_LRS"
        caching              = "ReadWrite"
      
    }
}



