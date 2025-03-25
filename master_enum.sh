#!/bin/bash

# Colors for output
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

echo "Enter the target IP/Domain:"
read DOMAIN

# Check if the user has provided an IP/domain
if [[ -z $DOMAIN ]]; then
  echo "IP/Domain cannot be empty!"
  exit 1
fi

BASE_DIR="PROJECTS"
mkdir -p "$BASE_DIR" || exit 1

OUTPUT_DIR="$BASE_DIR/$DOMAIN"
mkdir -p "$OUTPUT_DIR"

# Paths for module outputs
SUBDOMAINS_FILE="$OUTPUT_DIR/subdomains.txt"
ALIVE_FILE="$OUTPUT_DIR/alive_subdomains.txt"
PORT_SCAN_FILE="$OUTPUT_DIR/port_scan.txt"
CMS_DETECTION_FILE="$OUTPUT_DIR/cms_detect.txt"

# Logging function
log() {
    echo -e "${GREEN}MASTER SCRIPT ${YELLOW} $1${RESET}"
}

# Error handling
error() {
    echo -e "${RED}[-] Error: $1${RESET}"
    exit 1
}

# Run subdomain enumeration
log "Starting Subdomain Enumeration..."
bash ./sub/subdomain_enum.sh "$DOMAIN" "$SUBDOMAINS_FILE" || error "Subdomain enumeration failed."

# Find alive subdomains
log "Probing for Alive Subdomains..."
bash ./sub/alive_checker.sh "$SUBDOMAINS_FILE" "$ALIVE_FILE" || error "Alive check failed."

# Perform port scanning
log "Performing Port Scanning..."
#bash ./sub/port_scan.sh "$ALIVE_FILE" "$PORT_SCAN_FILE" || error "Port scanning failed."

# Detect CMS
log "Detecting CMS..."
bash ./sub/cms_detection.sh "$ALIVE_FILE" "$CMS_DETECTION_FILE" || error "CMS detection failed."

# Summary
echo -e "${GREEN}________________________________________________${RESET}"
log "Enumeration completed. Results saved in $OUTPUT_DIR."
tree "$OUTPUT_DIR"
