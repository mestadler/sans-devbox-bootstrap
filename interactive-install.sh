#!/bin/bash
# install.sh - DevBox Bootstrap Installation Script
# 
# This script automates the installation of devbox-init.sh and devbox-user-init.sh 
# from the sans-devbox-bootstrap repository.
#
# Usage: bash -c "$(curl -sSL https://raw.githubusercontent.com/mestadler/sans-devbox-bootstrap/main/install.sh)"
#
# Authors: Martin Stadler
# Last Updated: 2025-03-08

set -e

REPO_OWNER="mestadler"
REPO_NAME="sans-devbox-bootstrap"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH"
TEMP_DIR=$(mktemp -d)
ENV_FILE="$TEMP_DIR/.env"

# Terminal colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}        DevBox Bootstrap Installation Script${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""
echo -e "This script will download and install the development environment"
echo -e "setup scripts from ${CYAN}github.com/$REPO_OWNER/$REPO_NAME${NC}."
echo ""
echo -e "The setup happens in two phases:"
echo -e "  1. ${YELLOW}System setup${NC} (requires root privileges)"
echo -e "  2. ${YELLOW}User configuration${NC} (runs as your user)"
echo ""
echo -e "You will be prompted for some information to customize your setup."
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
download_file "$BASE_URL/.env_example" "$TEMP_DIR/.env_example"

# Make scripts executable
chmod +x "$TEMP_DIR/devbox-init.sh"
chmod +x "$TEMP_DIR/devbox-user-init.sh"

# Collect information for the .env file
echo -e "${YELLOW}Setting up environment configuration...${NC}"

# Start with the example file
cp "$TEMP_DIR/.env_example" "$ENV_FILE"

# Ask for essential information
read -p "Enter your full name: " DEBFULLNAME
read -p "Enter your email address: " DEBEMAIL
read -p "Enter your GitHub username (leave blank if not using GitHub): " GITHUB_USERNAME
read -sp "Enter your GitHub token (leave blank if not using GitHub): " GITHUB_TOKEN
echo ""
read -sp "Enter your OpenAI API key (leave blank if not using shell_gpt): " OPENAI_API_KEY
echo ""

# Set timezone using the system's timezone if possible
TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "Europe/London")

# Customize the .env file with user input
sed -i "s/DEBFULLNAME=\"Your Full Name\"/DEBFULLNAME=\"$DEBFULLNAME\"/" "$ENV_FILE"
sed -i "s/DEBEMAIL=\"your-email@example.com\"/DEBEMAIL=\"$DEBEMAIL\"/" "$ENV_FILE"

if [ ! -z "$GITHUB_USERNAME" ]; then
    sed -i "s/GITHUB_USERNAME=\"your-github-username\"/GITHUB_USERNAME=\"$GITHUB_USERNAME\"/" "$ENV_FILE"
    
    # Set repo URL to user's fork if they likely have one, otherwise keep original
    sed -i "s|REPO_URL=\"https://github.com/username/devbox-setup.git\"|REPO_URL=\"https://github.com/$GITHUB_USERNAME/sans-devbox-bootstrap.git\"|" "$ENV_FILE"
fi

if [ ! -z "$GITHUB_TOKEN" ]; then
    sed -i "s/GITHUB_TOKEN=\"your-github-token\"/GITHUB_TOKEN=\"$GITHUB_TOKEN\"/" "$ENV_FILE"
fi

if [ ! -z "$OPENAI_API_KEY" ]; then
    sed -i "s/OPENAI_GPT_API_KEY=\"your-openai-api-key\"/OPENAI_GPT_API_KEY=\"$OPENAI_API_KEY\"/" "$ENV_FILE"
    sed -i "s/OPENAI_API_KEY=\"\$OPENAI_GPT_API_KEY\"/OPENAI_API_KEY=\"$OPENAI_API_KEY\"/" "$ENV_FILE"
fi

# Set timezone based on system or default
sed -i "s/TZ=\"Europe\/London\"/TZ=\"$TZ\"/" "$ENV_FILE"

# Proceed with installation
echo -e "${YELLOW}Starting system installation (requires sudo)...${NC}"
echo -e "This will run the devbox-init.sh script with root privileges to install system packages."
echo -e "The .env file has been created at ${CYAN}$ENV_FILE${NC}"
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
    # Copy .env file to home directory first
    cp "$ENV_FILE" "$HOME/.env"
    echo -e "Environment file copied to ${CYAN}$HOME/.env${NC}"
    
    # Remove temporary directory
    rm -rf "$TEMP_DIR"
    echo -e "Temporary files removed."
else
    echo -e "Temporary files kept at ${CYAN}$TEMP_DIR${NC}"
    echo -e "Environment file is at ${CYAN}$ENV_FILE${NC}"
fi

echo ""
echo -e "${GREEN}Installation process complete!${NC}"
echo -e "${YELLOW}You may need to restart your shell or log out and back in${NC}"
echo -e "${YELLOW}for all changes to take effect.${NC}"
echo ""
echo -e "${CYAN}============================================================${NC}"
