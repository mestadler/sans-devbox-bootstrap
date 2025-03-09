#!/bin/bash
#  - DevBox Bootstrap Installation with Local .env File
# 
# This script installs devbox-init.sh and devbox-user-init.sh from the sans-devbox-bootstrap repository
# using a local .env file that the user already has.
#
# Usage: bash -c "$(curl -sSL https://raw.githubusercontent.com/mestadler/sans-devbox-bootstrap/main/install-local-env.sh)" _ /path/to/your/.env
#
# Authors: Martin Stadler
# Last Updated: 2025-03-08

set -e

# Check if .env file path is provided
if [ -z "$1" ]; then
    echo "Error: No .env file path provided."
    echo "Usage: bash -c \"\$(curl -sSL https://raw.githubusercontent.com/mestadler/sans-devbox-bootstrap/main/install-local-env.sh)\" _ /path/to/your/.env"
    exit 1
fi

ENV_FILE="$1"

# Check if the file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

REPO_OWNER="mestadler"
REPO_NAME="sans-devbox-bootstrap"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH"
TEMP_DIR=$(mktemp -d)

# Terminal colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}   DevBox Bootstrap Installation with Local .env File${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""
echo -e "This script will download and install the development environment"
echo -e "setup scripts from ${CYAN}github.com/$REPO_OWNER/$REPO_NAME${NC}"
echo -e "using your local .env file:"
echo -e "${YELLOW}$ENV_FILE${NC}"
echo ""
echo -e "The setup happens in two phases:"
echo -e "  1. ${YELLOW}System setup${NC} (requires root privileges)"
echo -e "  2. ${YELLOW}User configuration${NC} (runs as your user)"
echo ""

# Function to download a file
download_file() {
    local url="$1"
    local destination="$2"
    echo -e "Downloading ${CYAN}$url${NC}..."
    curl -sSL "$url" -o "$destination"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error downloading $url${NC}"
        exit 1
    fi
}

# Check if required commands exist
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Error: $1 is required but not installed.${NC}"
        exit 1
    fi
}

check_command curl
check_command sudo

# Download the scripts
echo -e "${YELLOW}Downloading setup scripts...${NC}"
download_file "$BASE_URL/devbox-init.sh" "$TEMP_DIR/devbox-init.sh"
download_file "$BASE_URL/devbox-user-init.sh" "$TEMP_DIR/devbox-user-init.sh"

# Make scripts executable
chmod +x "$TEMP_DIR/devbox-init.sh"
chmod +x "$TEMP_DIR/devbox-user-init.sh"

# Proceed with installation
echo -e "${YELLOW}Starting system installation (requires sudo)...${NC}"
echo -e "This will run the devbox-init.sh script with root privileges to install system packages."
echo -e "Using your .env file from ${CYAN}$ENV_FILE${NC}"
echo ""
read -p "Proceed with system installation? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Run the system installation script
    sudo bash "$TEMP_DIR/devbox-init.sh" "$ENV_FILE"
    
    echo ""
    echo -e "${GREEN}System installation complete!${NC}"
    echo ""
    
    # Ask to proceed with user configuration
    echo -e "${YELLOW}Ready to run user configuration...${NC}"
    echo -e "This will set up your user environment, dotfiles, and configurations."
    read -p "Proceed with user configuration? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Run the user configuration script
        bash "$TEMP_DIR/devbox-user-init.sh" "$ENV_FILE"
        
        echo ""
        echo -e "${GREEN}User configuration complete!${NC}"
    else
        echo -e "${YELLOW}User configuration skipped.${NC}"
        echo -e "You can run it later with:"
        echo -e "  ${CYAN}bash $TEMP_DIR/devbox-user-init.sh $ENV_FILE${NC}"
    fi
else
    echo -e "${YELLOW}Installation canceled.${NC}"
    echo -e "You can run the scripts manually:"
    echo -e "  ${CYAN}sudo bash $TEMP_DIR/devbox-init.sh $ENV_FILE${NC}"
    echo -e "  ${CYAN}bash $TEMP_DIR/devbox-user-init.sh $ENV_FILE${NC}"
    exit 0
fi

# Clean up or leave files depending on user preference
read -p "Remove temporary installation files? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Remove temporary directory
    rm -rf "$TEMP_DIR"
    echo -e "Temporary files removed."
else
    echo -e "Temporary files kept at ${CYAN}$TEMP_DIR${NC}"
fi

echo ""
echo -e "${GREEN}Installation process complete!${NC}"
echo -e "${YELLOW}You may need to restart your shell or log out and back in${NC}"
echo -e "${YELLOW}for all changes to take effect.${NC}"
echo ""
echo -e "${CYAN}============================================================${NC}"
