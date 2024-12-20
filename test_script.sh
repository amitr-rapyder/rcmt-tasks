#!/bin/bash
set -e

source /home/amitdemo/vmtask/bin/activate


output_file="/home/amitdemo/inventory/$(date '+%Y/%m/%d')/output.xlsx"

mkdir -p "$(dirname "$output_file")"
export OUTPUT_FILE="$output_file"

list_subscriptions() {
    echo "=== Listing Subscriptions ==="

    az account list --output table
}

create_and_upload_file() {
    echo "Creating new file..."
    az login --identity > /dev/null || return 1

    storage_key=$(az storage account keys list \
        --resource-group "CoE" \
        --account-name "amitdemovm" \
        --query '[0].value' -o tsv) || return 1

    current_date=$(date '+%Y-%m-%d %H:%M:%S')
    subscription_id=$(az account show --query 'id' -o tsv)

    /home/amitdemo/command_script.sh

    echo "Merging csv files into single excel file"
    python3 /home/amitdemo/merge.py

    blob_path="$(date '+%Y/%m/%d')/${subscription_id}-daily-report.xlsx"

    az storage blob upload \
        --account-name "amitdemovm" \
        --account-key "$storage_key" \
        --container-name "amitdemovm" \
        --file "$output_file" \
        --name "$blob_path" \
        --overwrite || return 1

    echo "File uploaded to: $blob_path"
    return 0
}

test_date_access() {
    echo "Starting blob access check..."
    az login --identity > /dev/null || return 1

    storage_key=$(az storage account keys list \
        --resource-group "CoE" \
        --account-name "amitdemovm" \
        --query '[0].value' -o tsv) || return 1

    max_retries=2
    retry_count=0
    check_date=$(date -d "today" '+%Y/%m/%d')
    subscription_id=$(az account show --query 'id' -o tsv)
    target_blob_path="$check_date/${subscription_id}-daily-report.xlsx"

    echo "Checking for blob: $target_blob_path"

    while [ $retry_count -lt $max_retries ]; do
        ((retry_count++))
        echo "Attempt $retry_count of $max_retries"

        if az storage blob exists \
            --account-name "amitdemovm" \
            --account-key "$storage_key" \
            --container-name "amitdemovm" \
            --name "$target_blob_path" \
            --query "exists" \
            -o tsv | grep -q "true"; then

            blob_info=$(az storage blob show \
                --account-name "amitdemovm" \
                --account-key "$storage_key" \
                --container-name "amitdemovm" \
                --name "$target_blob_path" \
                --query "name" \
                -o tsv 2>/dev/null)

            if [ "$blob_info" = "$target_blob_path" ]; then
                echo "Blob found successfully"
                return 0
            fi
        fi

        echo "Blob not found - creating new file..."
        create_and_upload_file || return 1

        if [ $retry_count -eq $max_retries ]; then
            echo "Maximum retry attempts reached"
            return 1
        fi

        echo "Waiting 5 seconds before next attempt..."
        sleep 5
    done

    return 1
}

main() {
    echo "=== Script Started ==="

    list_subscriptions || {
        echo "Failed to list subscriptions"
        exit 1
    }

    if ! test_date_access; then
        echo "=== Script Failed ==="
        exit 1
    fi

    echo "=== Script Completed Successfully ==="
    exit 0
}

main