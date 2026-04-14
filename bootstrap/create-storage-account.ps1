#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates a resource group, storage account, and blob container for Terraform remote state.

.PARAMETER ResourceGroupName
    Name of the resource group to create.

.PARAMETER Location
    Azure region for all resources.

.PARAMETER StorageAccountName
    Globally unique storage account name (3-24 lowercase alphanumeric).

.PARAMETER ContainerName
    Blob container name for state files.
#>

param(
    [string] $ResourceGroupName = "rg-terraform-state",
    [string] $Location = "eastus",
    [Parameter(Mandatory)] [string] $StorageAccountName,
    [string] $ContainerName = "tfstate"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Validate storage account name ---
if ($StorageAccountName -notmatch '^[a-z0-9]{3,24}$') {
    Write-Error "Storage account name must be 3-24 lowercase alphanumeric characters."
    exit 1
}

# --- Create resource group ---
Write-Host "Creating resource group: $ResourceGroupName in $Location ..."
az group create `
    --name $ResourceGroupName `
    --location $Location `
    --tags Environment=shared Purpose=terraform-state | Out-Null

# --- Create storage account ---
Write-Host "Creating storage account: $StorageAccountName ..."
az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2 `
    --min-tls-version TLS1_2 `
    --allow-blob-public-access false `
    --tags Environment=shared Purpose=terraform-state | Out-Null

# --- Enable blob versioning ---
Write-Host "Enabling blob versioning ..."
az storage account blob-service-properties update `
    --account-name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --enable-versioning true | Out-Null

# --- Create blob container ---
Write-Host "Creating blob container: $ContainerName ..."
az storage container create `
    --name $ContainerName `
    --account-name $StorageAccountName `
    --auth-mode login | Out-Null

# --- Output summary ---
$subscriptionId = az account show --query id -o tsv

Write-Host "`n=============================="
Write-Host " Terraform Backend Config"
Write-Host "=============================="
Write-Host ""
Write-Host "Add this to your providers.tf inside the terraform {} block:"
Write-Host ""
Write-Host '  backend "azurerm" {'
Write-Host "    resource_group_name  = `"$ResourceGroupName`""
Write-Host "    storage_account_name = `"$StorageAccountName`""
Write-Host "    container_name       = `"$ContainerName`""
Write-Host '    key                  = "network.tfstate"'
Write-Host '    use_oidc             = true'
Write-Host '  }'
Write-Host ""
Write-Host "Then run: terraform init -migrate-state"
