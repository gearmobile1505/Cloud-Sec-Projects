#!/bin/bash
# Azure Sentinel KQL Testing Infrastructure Cleanup Script
# This script removes duplicate resource groups and storage accounts

set -e

echo "🧹 Starting cleanup of duplicate Azure resources..."

# Resource Groups to delete (keep sentinel-kql-dev-dev-rg)
DUPLICATE_RGS=(
    "sentinel-kql-dev-dev-rg-pbvjsz0a"
    "sentinel-kql-dev-dev-rg-a5gcinb9"
)

# Storage accounts to delete (keep the latest one)
DUPLICATE_STORAGE_ACCOUNTS=(
    "sentinelkqlstate15"
    "sentinelkqlstate17"
    "sentinelkqlstate18"
    "sentinelkqlstate19"
    "sentinelkqlstate20"
    "sentinelkqlstate21"
)

echo "📋 Resources to be deleted:"
echo "Resource Groups:"
for rg in "${DUPLICATE_RGS[@]}"; do
    echo "  - $rg"
done

echo "Storage Accounts:"
for sa in "${DUPLICATE_STORAGE_ACCOUNTS[@]}"; do
    echo "  - $sa"
done

echo ""
read -p "⚠️  Are you sure you want to delete these resources? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Cleanup cancelled."
    exit 1
fi

echo "🗑️  Deleting duplicate resource groups..."
for rg in "${DUPLICATE_RGS[@]}"; do
    echo "Deleting resource group: $rg"
    az group delete --name "$rg" --yes --no-wait
done

echo "🗑️  Deleting duplicate storage accounts..."
for sa in "${DUPLICATE_STORAGE_ACCOUNTS[@]}"; do
    echo "Deleting storage account: $sa"
    az storage account delete --name "$sa" --resource-group "terraform-state-rg" --yes
done

echo "✅ Cleanup initiated!"
echo "📝 Note: Resource group deletions are running in the background and may take several minutes."
echo ""
echo "🎯 Remaining resources:"
echo "  - Resource Group: sentinel-kql-dev-dev-rg (with all your Sentinel infrastructure)"
echo "  - Storage Account: sentinelkqlstate22 (latest Terraform state)"
echo ""
echo "🚀 Next steps:"
echo "1. Wait for cleanup to complete (5-10 minutes)"
echo "2. Update Terraform configuration to use fixed naming (no random suffixes)"
echo "3. Import existing resources into Terraform state"
