#!/bin/bash

DOMAIN=$1
OUTPUT_FILE=$2

if [ -z "$DOMAIN" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <domain> <output_file>"
    exit 1
fi

touch "$OUTPUT_FILE"

# Subfinder
echo "Running subfinder"
subfinder -d "$DOMAIN" -v >> "$OUTPUT_FILE"

# Assetfinder
echo "Running assetfinder"
assetfinder --subs-only "$DOMAIN" >> "$OUTPUT_FILE"

# Amass
echo "Running amass"
amass enum -passive -d "$DOMAIN" -v>> "$OUTPUT_FILE"

# Clean and sort
sort -u "$OUTPUT_FILE" -o "$OUTPUT_FILE"
echo "[+] Subdomain enumeration completed. Results saved in $OUTPUT_FILE."

