# Configure the Terraform runtime requirements..
terraform {
  required_version = ">= 1.1.0"

  required_providers {
    # Azure Resource Manager provider and version
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.3"
    }
  }
}

# Define providers and their config params
provider "azurerm" {
  # Leave the features block empty to accept all defaults
  features {}
}

provider "cloudinit" {
  # Configuration options
}

variable "labelPrefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "dani0197" # Update this
}

variable "region" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "Canada Central" # Update this if needed
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "daniyal" # Update this if needed
}

resource "azurerm_resource_group" "main" {
  name     = "${var.labelPrefix}-A05-RG"
  location = var.region
}

