#!/bin/bash

CURRENT_DATE=$(date +"%Y%m%d")
CURRENT_YEAR=$(date +"%Y")
CURRENT_MONTH=$(date +"%m")

OUTPUT_DIR="inventory/$(date +"%Y/%m/%d")"
mkdir -p "${OUTPUT_DIR}"

find inventory/ -type d -path "inventory/????/??/*" | while read -r dir; do
    removeable_path="${dir#inventory/}"
    
    if [[ "$removeable_path" < "${CURRENT_YEAR}/${CURRENT_MONTH}/01" ]]; then
        echo "Removing old directory: $dir"
        rm -rf "$dir"
    fi
done

SQL_FILES=($(ls sql_queries/*.sql | xargs -n 1 basename -s .sql))

for file in "${SQL_FILES[@]}"; do
    steampipe query --output csv < "sql_queries/${file}.sql" > "${OUTPUT_DIR}/${file}_${CURRENT_DATE}.csv"
done