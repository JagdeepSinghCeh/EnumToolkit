#!/bin/bash

INPUT_FILE=$1
OUTPUT_FILE=$2

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <input_file> <output_file>"
    exit 1
fi

touch "$OUTPUT_FILE"

# Check for live subdomains
echo "Running httprobe :"
cat "$INPUT_FILE" | httprobe -prefer-https | sed 's|https\?://||' > "$OUTPUT_FILE"

echo "[+] Alive subdomains saved to $OUTPUT_FILE."
