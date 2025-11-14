#!/bin/bash

# Colors
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

echo -e "${YELLOW}============================="
echo -e "  INSTALLING ALL ENUM TOOLS"
echo -e "=============================${RESET}"

# Update system
# echo -e "${GREEN}[+] Updating system...${RESET}"
# sudo apt update -y
# sudo apt upgrade -y

# Install Nmap
echo -e "${GREEN}[+] Installing Nmap...${RESET}"
sudo apt install -y nmap

# Install SMB tools
echo -e "${GREEN}[+] Installing SMB tools (smbclient)...${RESET}"
sudo apt install -y smbclient samba-common-bin

# Install WhatWeb
echo -e "${GREEN}[+] Installing WhatWeb...${RESET}"
sudo apt install -y whatweb

# Install Gobuster
echo -e "${GREEN}[+] Installing Gobuster...${RESET}"
sudo apt install -y gobuster

# Install Nikto
echo -e "${GREEN}[+] Installing Nikto...${RESET}"
sudo apt install -y nikto

# Install SecLists (for wordlists)
echo -t "${GREEN}[+] Installing SecLists...${RESET}"
sudo apt install -y seclists

# Ensure rockyou wordlist is extracted
if [ -f /usr/share/wordlists/rockyou.txt.gz ]; then
    echo -e "${GREEN}[+] Extracting rockyou.txt...${RESET}"
    sudo gzip -dk /usr/share/wordlists/rockyou.txt.gz
fi

# Install Subfinder
echo -e "${GREEN}[+] Installing Subfinder...${RESET}"
sudo apt install -y subfinder || {
    echo -e "${YELLOW}[!] Subfinder apt package missing, installing via Go...${RESET}"
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
}

# Install Assetfinder
echo -e "${GREEN}[+] Installing Assetfinder...${RESET}"
go install github.com/tomnomnom/assetfinder@latest

# Install Amass
echo -e "${GREEN}[+] Installing amass...${RESET}"
sudo apt install -y amass || {
    echo -e "${YELLOW}[!] Amass apt package missing, installing via snap...${RESET}"
    sudo snap install amass
}

# Install Httprobe
echo -e "${GREEN}[+] Installing httprobe...${RESET}"
go install github.com/tomnomnom/httprobe@latest

# Add Go binaries to PATH
if ! grep -q "export PATH=\$PATH:\$HOME/go/bin" ~/.bashrc; then
    echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
    source ~/.bashrc
fi

echo -e "${GREEN}[+] Installation Completed!"
echo -e "All tools are ready to use!${RESET}"

