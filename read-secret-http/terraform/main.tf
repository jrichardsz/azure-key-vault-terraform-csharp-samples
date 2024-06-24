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

resource "null_resource" "function_app_build" {
  provisioner "local-exec" {
    command = "rm -rf ../output && dotnet build ../src/FunctionApp.csproj  --configuration Release --output ../output"
  }
}

# Create ZIP file containing the function code
data "archive_file" "file_function_app" {
  type        = "zip"
  source_dir  = "../output"
  output_path = "function.zip"
  excludes = [ "local.settings.json", ".funcignore", ".gitignore", "getting_started.md", "README.md" ]
}

# Use Azure CLI to push a Zip deployment using remote build https://docs.microsoft.com/en-us/azure/azure-functions/functions-deployment-technologies#key-concepts
locals {
    publish_code_command = "az functionapp deployment source config-zip --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_windows_function_app.azure_function.name} --src ${data.archive_file.file_function_app.output_path}"
}

resource "null_resource" "function_app_publish" {
  provisioner "local-exec" {
    command = local.publish_code_command
  }
  depends_on = [local.publish_code_command]
  triggers = {
    # Only redeploy if zip file content changed
    input_json = filemd5(data.archive_file.file_function_app.output_path)
    publish_code_command = local.publish_code_command
  }
}