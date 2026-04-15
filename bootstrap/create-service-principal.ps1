#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates a service principal for GitHub Actions with federated credentials (OIDC)
    and grants it Contributor access to the subscription + Storage Blob Data Contributor
    on the Terraform state storage account.

.PARAMETER AppName
    Display name for the Azure AD application / service principal.

.PARAMETER GitHubOrg
    GitHub organization or username that owns the repository.

.PARAMETER GitHubRepo
    GitHub repository name.

.PARAMETER SubscriptionId
    Azure subscription ID. Defaults to the current az CLI subscription.

.PARAMETER StateResourceGroup
    Resource group containing the Terraform state storage account.

.PARAMETER StateStorageAccount
    Name of the Terraform state storage account.
#>

param(
    [Parameter(Mandatory)] [string] $AppName,
    [Parameter(Mandatory)] [string] $GitHubOrg,
    [Parameter(Mandatory)] [string] $GitHubRepo,
    [string] $SubscriptionId,
    [string] $StateResourceGroup = "rg-terraform-state",
    [string] $StateStorageAccount
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Resolve subscription ---
if (-not $SubscriptionId) {
    $SubscriptionId = (az account show --query id -o tsv)
    Write-Host "Using current subscription: $SubscriptionId"
}

# --- Create Azure AD application ---
Write-Host "`nCreating Azure AD application: $AppName ..."
$appId = az ad app create --display-name $AppName --query appId -o tsv
Write-Host "Application (client) ID: $appId"

# --- Create service principal ---
Write-Host "`nCreating service principal ..."
az ad sp create --id $appId | Out-Null
$spObjectId = az ad sp show --id $appId --query id -o tsv
Write-Host "Service principal object ID: $spObjectId"

# --- Add federated credential for GitHub Actions OIDC ---
$subjects = @(
    "repo:${GitHubOrg}/${GitHubRepo}:ref:refs/heads/main"
)

$tempFile = [System.IO.Path]::GetTempFileName()
try {
    foreach ($subject in $subjects) {
        $credName = ($subject -replace "[^a-zA-Z0-9]", "-").TrimEnd("-")
        # Truncate to 120 chars (Azure limit)
        if ($credName.Length -gt 120) { $credName = $credName.Substring(0, 120) }

        Write-Host "  Adding federated credential: $subject"
        $body = @{
            name        = $credName
            issuer      = "https://token.actions.githubusercontent.com"
            subject     = $subject
            audiences   = @("api://AzureADTokenExchange")
            description = "GitHub Actions OIDC - $subject"
        } | ConvertTo-Json
        $body | Set-Content -Path $tempFile -Encoding utf8

        az ad app federated-credential create --id $appId --parameters "@$tempFile" | Out-Null
    }
} finally {
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}

# --- Assign Contributor on subscription ---
Write-Host "`nAssigning Contributor role on subscription ..."
az role assignment create `
    --assignee-object-id $spObjectId `
    --assignee-principal-type ServicePrincipal `
    --role "Contributor" `
    --scope "/subscriptions/$SubscriptionId" | Out-Null

# --- Assign Storage Blob Data Contributor on state storage (if provided) ---
if ($StateStorageAccount) {
    Write-Host "Assigning Storage Blob Data Contributor on $StateStorageAccount ..."
    $storageId = az storage account show `
        --name $StateStorageAccount `
        --resource-group $StateResourceGroup `
        --query id -o tsv

    az role assignment create `
        --assignee-object-id $spObjectId `
        --assignee-principal-type ServicePrincipal `
        --role "Storage Blob Data Contributor" `
        --scope $storageId | Out-Null
}

# --- Get tenant ID ---
$tenantId = az account show --query tenantId -o tsv

# --- Output summary ---
Write-Host "`n=============================="
Write-Host " GitHub Actions Secrets"
Write-Host "=============================="
Write-Host "Set these as repository secrets in GitHub:"
Write-Host ""
Write-Host "  AZURE_CLIENT_ID       = $appId"
Write-Host "  AZURE_TENANT_ID       = $tenantId"
Write-Host "  AZURE_SUBSCRIPTION_ID = $SubscriptionId"
Write-Host ""
Write-Host "No client secret needed — OIDC federated credentials are configured."
Write-Host ""
Write-Host "In your GitHub Actions workflow, use:"
Write-Host ""
Write-Host '  - uses: azure/login@v2'
Write-Host '    with:'
Write-Host '      client-id: ${{ secrets.AZURE_CLIENT_ID }}'
Write-Host '      tenant-id: ${{ secrets.AZURE_TENANT_ID }}'
Write-Host '      subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}'
