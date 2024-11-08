#!/bin/bash

# Error handling
set -e

# Create output file
echo "Creating output file..."
{
    echo "Date and Time:"
    date
} > /home/amitdemo/output.txt

# Upload to blob and create folders using PowerShell
pwsh << 'EOF'
# Connect using managed identity
Connect-AzAccount -Identity

# Get the storage account
$storageAccount = Get-AzStorageAccount -ResourceGroupName "CoE" -Name "amitdemovm"
$context = $storageAccount.Context

# Upload the file to the first folder
Set-AzStorageBlobContent -File "/home/amitdemo/output.txt" -Container "amitdemovm" -Blob "folder01/demo01" -Context $context

# Create the second empty folder
New-AzStorageContainer -Name "amitdemovm" -Context $context -Path "folder02"

Write-Output "Script executed successfully. The files have been uploaded to the container."
EOF