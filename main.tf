# Configure the Terraform runtime requirements
terraform {
  required_version = ">= 1.1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
    }
  }
}

# Define providers and their config params
provider "azurerm" {
  features {}
}

provider "cloudinit" {
  # No configuration needed for cloudinit provider
}

# Variables
variable "labelPrefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "dani0197"
}

variable "region" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "Canada Central"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "daniyal"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.labelPrefix}-A05-RG"
  location = var.region
}

# Public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.labelPrefix}-public-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.labelPrefix}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "${var.labelPrefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "${var.labelPrefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${var.labelPrefix}-A05-NIC"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.labelPrefix}-ip-config"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Virtual Machine
resource "azurerm_virtual_machine" "main" {
  name                             = "${var.labelPrefix}-vm"
  location                         = azurerm_resource_group.main.location
  resource_group_name              = azurerm_resource_group.main.name
  network_interface_ids            = [azurerm_network_interface.main.id]
  vm_size                          = "Standard_B1s"  # Using a cheaper VM size for test deployment
  availability_set_id              = null
  delete_data_disks_on_termination = false
  delete_os_disk_on_termination    = false
  tags                             = {
    "Environment" = "Development"
    "Owner"       = "Daniyal"
  }

  os_profile {
    computer_name  = "${var.labelPrefix}-vm"
    admin_username = var.admin_username  # Use the variable for admin username
    admin_password = ""  # SSH-based authentication (no password)
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = file("/Users/Daniyal/Desktop/Courses/Cloud/Semester 2/devops infra/cst8918-w25-A05-dani0197/id_rsa.pub")
    }
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.labelPrefix}-osdisk"
    disk_size_gb      = 30
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
  }
}

# Cloud-init Config
data "cloudinit_config" "init" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/init.sh")
  }
}

# Output Values
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "public_ip_address" {
  description = "The public IP address of the VM"
  value       = azurerm_public_ip.main.ip_address
}
