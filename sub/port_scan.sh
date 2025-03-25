#!/bin/bash

# Colors for output
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

INPUT_FILE=$1
OUTPUT_DIR=$2

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_DIR" ]; then
    echo -e "${RED}Usage: $0 <input_file> <output_directory>${RESET}"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
INITIAL_SCAN_FILE="$OUTPUT_DIR/initial_scan.txt"
PORT_SCAN_FILE="$OUTPUT_DIR/open_ports.txt"
LOG_DIR="$OUTPUT_DIR/logs"
mkdir -p "$LOG_DIR"

log() {
    echo -e "${GREEN}MASTER SCRIPT ${YELLOW} $1${RESET}"
}

while read DOMAIN; do
  log "Performing full port scan for $DOMAIN..."
  sudo nmap "$DOMAIN" -sS -vv -p- --min-rate 1000 --max-parallelism 100 -oG "$INITIAL_SCAN_FILE" 2>/dev/null

  log "Checking Open Ports..."
  open_ports=$(grep -oP '\d+/open' "$INITIAL_SCAN_FILE" | cut -d '/' -f 1)
  echo "$open_ports" > "$PORT_SCAN_FILE"
  log "Open Ports detected: $(cat "$PORT_SCAN_FILE")"

  for port in $open_ports; do
    OUTPUT_FILE="$LOG_DIR/port_${DOMAIN}_$port.txt"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~ $port SCAN ~~~~~~~~~~~~~~~~~~~~~~~~~" | tee -a "$OUTPUT_FILE"

    case $port in
      21)
        echo "FTP detected on port 21. Checking for anonymous login..." | tee -a "$OUTPUT_FILE"
        sudo nmap "$DOMAIN" -p 21 -vv --script=ftp-anon.nse >> "$OUTPUT_FILE" 2>/dev/null
        ;;
      22)
        echo "SSH detected on port 22. Searching for hints of usernames..." | tee -a "$OUTPUT_FILE"
        echo "If a username is found, do you want to run Hydra? (Enter 'NF' to skip or provide a username within 10 seconds):"
        read -t 10 ssh_user
        ssh_user=${ssh_user:-NF}
        if [[ $ssh_user != "NF" ]]; then
          echo "Running Hydra on SSH with username '$ssh_user'..." | tee -a "$OUTPUT_FILE"
          sudo hydra "$DOMAIN" -l "$ssh_user" -P /usr/share/wordlists/rockyou.txt ssh >> "$OUTPUT_FILE" 2>/dev/null
        else
          echo "Skipping Hydra for SSH." | tee -a "$OUTPUT_FILE"
        fi
        ;;
      80|443|8080|8443)
        echo "HTTP/HTTPS detected on port $port. Checking webpage details..." | tee -a "$OUTPUT_FILE"
        echo "Running Gobuster..." | tee -a "$OUTPUT_FILE"
        sudo gobuster dir -u "http://$DOMAIN" -w /usr/share/wordlists/dirb/common.txt -e php,html,js,py,ajax >> "$OUTPUT_FILE" 2>/dev/null
        echo "Running Nikto..." | tee -a "$OUTPUT_FILE"
        sudo nikto -h "$DOMAIN" >> "$OUTPUT_FILE" 2>/dev/null

        echo "Checking for login page..." | tee -a "$OUTPUT_FILE"
        echo "If a login page is found, do you want to run Hydra? (Enter 'NF' to skip or provide a username within 10 seconds):"
        read -t 10 http_user
        http_user=${http_user:-NF}
        if [[ $http_user != "NF" ]]; then
          echo "Running Hydra on HTTP/HTTPS with username '$http_user'..." | tee -a "$OUTPUT_FILE"
          sudo hydra "$DOMAIN" -l "$http_user" -P /usr/share/wordlists/rockyou.txt http-form-post >> "$OUTPUT_FILE" 2>/dev/null
        else
          echo "Skipping Hydra for HTTP/HTTPS." | tee -a "$OUTPUT_FILE"
        fi
        ;;
      445)
        echo "SMB detected on port 445. Checking for anonymous login..." | tee -a "$OUTPUT_FILE"
        smbclient -L "//$DOMAIN" -N >> "$OUTPUT_FILE" 2>/dev/null
        echo "Checking for common vulnerabilities..." | tee -a "$OUTPUT_FILE"
        sudo nmap "$DOMAIN" -p 21,22,80 -A -vv --script vuln >> "$OUTPUT_FILE" 2>/dev/null
        ;;
      3389)
        echo "RDP detected on port 3389. Checking for vulnerabilities..." | tee -a "$OUTPUT_FILE"
        sudo nmap "$DOMAIN" -p 3389 --script rdp-enum-encryption,rdp-vuln-ms12-020 -vv >> "$OUTPUT_FILE" 2>/dev/null
        ;;
      1433|3306)
        echo "Database service detected on port $port. Checking for vulnerabilities..." | tee -a "$OUTPUT_FILE"
        sudo nmap "$DOMAIN" -p $port --script=ms-sql-info,mysql-empty-password,mysql-brute -vv >> "$OUTPUT_FILE" 2>/dev/null
        ;;
      25|110|143|465|587|993|995)
        echo "Mail service detected on port $port. Checking for common vulnerabilities..." | tee -a "$OUTPUT_FILE"
        sudo nmap "$DOMAIN" -p $port --script smtp-enum-users,pop3-brute,imap-brute -vv >> "$OUTPUT_FILE" 2>/dev/null
        ;;
      53)
        echo "DNS service detected on port 53. Checking for DNS-related vulnerabilities..." | tee -a "$OUTPUT_FILE"
        sudo nmap "$DOMAIN" -p 53 --script dns-zone-transfer,dns-recursion -vv >> "$OUTPUT_FILE" 2>/dev/null
        ;;
      137|139)
        echo "NetBIOS service detected on port $port. Checking for vulnerabilities..." | tee -a "$OUTPUT_FILE"
        sudo nmap "$DOMAIN" -p $port --script nbstat,smb-enum-shares,smb-enum-users -vv >> "$OUTPUT_FILE" 2>/dev/null
        ;;
      *)
        echo "Port $port does not match specified checks. Skipping..." | tee -a "$OUTPUT_FILE"
        ;;
    esac
  done
done < "$INPUT_FILE"

log "Port Scan completed. Results saved in $OUTPUT_DIR."
tree "$OUTPUT_DIR"


