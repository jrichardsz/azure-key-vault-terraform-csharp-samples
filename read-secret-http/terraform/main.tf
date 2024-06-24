terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.0.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.108.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.37.1"
    }
  }
}

# Random provider
provider "random" {}

# Subscription provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Azure Active Directory
provider "azuread" {}

resource "azurerm_resource_group" "rg" {
  name = "rg-${var.base_name}-${var.environment}-${format("%02s",var.base_instance)}"
  location = var.location
}

# NOTE: Usually you would separate the deployment of the code from the provisioning of infrastructure by using separate pipelines.
# This example combines both steps into one Terraform for simplicity.

# Create ZIP file containing the function code

resource "null_resource" "function_app_build" {
  provisioner "local-exec" {
    command = "rm function.zip && dotnet build ../src/FunctionApp.csproj  --configuration Release --output ../output"
  }
}

data "archive_file" "file_function_app" {
  type        = "zip"
  source_dir  = "../output"
  output_path = "function.zip"
  excludes = [ "local.settings.json", ".funcignore", ".gitignore", "getting_started.md", "README.md" ]
  depends_on = [null_resource.function_app_build]
}

resource "null_resource" "function_app_publish" {
  provisioner "local-exec" {
    command = "az functionapp deployment source config-zip --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_windows_function_app.azure_function.name} --src ${data.archive_file.file_function_app.output_path}"
  }
  depends_on = [data.archive_file.file_function_app]
}