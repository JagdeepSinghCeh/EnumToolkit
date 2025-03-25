#!/bin/bash

INPUT_FILE=$1
OUTPUT_FILE=$2

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <input_file> <output_file>"
    exit 1
fi

touch "$OUTPUT_FILE"

# Detect CMS for each live subdomain
while read -r domain; do
    echo "Scanning $domain for CMS..."
    whatweb "$domain" >> "$OUTPUT_FILE"
done < "$INPUT_FILE"

echo "[+] CMS detection results saved to $OUTPUT_FILE."


