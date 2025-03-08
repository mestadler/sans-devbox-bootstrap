#!/bin/bash

# devbox-user-init.sh
#
# Description:
#   This script deploys user-specific configurations, including dotfiles and
#   special configuration files. It should be run after devbox-init.sh.
#
# Usage:
#   ./devbox-user-init.sh <path_to_env_file> [--dry-run]
#
# Arguments:
#   <path_to_env_file>: Path to the environment file containing configuration variables
#   --dry-run: Optional flag to run the script without making changes
#
# Note:
#   - This script expects environment variables like REPO_URL, DOTFILES, and SPECIAL_CONFIGS
#     to be defined in the environment file.
#   - It will clone a configuration repository, deploy dotfiles, and handle special configs.
#
# /mes - https://github.com/mestadler/sans-devbox-bootstrap

set -e
SCRIPT_VERSION="2.0"
LAST_UPDATED="2025-03-08"

# Function to display usage information
usage() {
    echo "Usage: $0 <path_to_env_file> [--dry-run]"
    echo "  <path_to_env_file>: Path to the environment variables file"
    echo "  --dry-run: Optional flag to run the script without making changes"
    exit 1
}

# Check if running as root (should NOT be run as root)
if [ "$(id -u)" -eq 0 ]; then
    echo "Error: This script should NOT be run as root."
    echo "Please run as your regular user."
    exit 1
fi

# Check if env file path is provided
if [ "$#" -lt 1 ]; then
    echo "Error: No environment file specified."
    usage
fi

ENV_FILE="$1"
shift

# Check if env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file $ENV_FILE does not exist."
    echo "Current working directory: $(pwd)"
    echo "Contents of current directory:"
    ls -la
    exit 1
fi

# Source the environment file
source "$ENV_FILE"

# Check for required variables
for var in REPO_URL DOTFILES SPECIAL_CONFIGS; do
    if [ -z "${!var}" ]; then
        echo "Error: $var is not set in $ENV_FILE"
        exit 1
    fi
done

# Print key variables for verification
echo "Checking environment variables:"
echo "ENV_FILE: $ENV_FILE"
echo "REPO_URL: $REPO_URL"
echo "DOTFILES: $DOTFILES"
echo "SPECIAL_CONFIGS: $SPECIAL_CONFIGS"

# Check for dry run flag
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "Dry run mode enabled. No changes will be made."
fi

# Logging setup
LOG_FILE="$HOME/devbox_user_init.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Starting devbox-user-init.sh version $SCRIPT_VERSION (Last updated: $LAST_UPDATED)"
echo "Deployment started at $(date)"

# Function to backup and copy files
backup_and_copy() {
    local file="$1"
    if [[ -e "$HOME/$file" ]]; then
        echo "Backing up existing $file to $file.old"
        $DRY_RUN || mv "$HOME/$file" "$HOME/$file.old"
    fi
    echo "Copying $file to $HOME"
    $DRY_RUN || cp "$file" "$HOME/$file"
}

# Function to backup and copy files to specific directories
backup_and_copy_to_dir() {
    local source_file="$1"
    local target_file="$2"
    local target_dir=$(dirname "$target_file")
    $DRY_RUN || mkdir -p "$target_dir"
    if [[ -e "$target_file" ]]; then
        echo "Backing up existing $(basename "$target_file") to $(basename "$target_file").old"
        $DRY_RUN || mv "$target_file" "$target_file.old"
    fi
    echo "Copying $source_file to $target_file"
    $DRY_RUN || cp "$source_file" "$target_file"
}

# Check for git command
if ! command -v git &> /dev/null; then
    echo "Error: git command not found. Please install git."
    exit 1
fi

# Create temporary directory for cloning
TEMP_DIR="$HOME/config_temp"
if [ -d "$TEMP_DIR" ]; then
    echo "Cleaning up existing temporary directory"
    $DRY_RUN || rm -rf "$TEMP_DIR"
fi

# Clone the repository
echo "Cloning configuration repository from $REPO_URL"
$DRY_RUN || git clone "$REPO_URL" "$TEMP_DIR" || { 
    echo "Error: Failed to clone repository from $REPO_URL"
    exit 1
}

# Change to the cloned repository directory
$DRY_RUN || cd "$TEMP_DIR" || {
    echo "Error: Failed to change to directory $TEMP_DIR"
    exit 1
}

# If dry run, just change to the current directory for testing
if $DRY_RUN; then
    cd "$(pwd)"
else
    # Verify we're in the right directory
    if [ ! -d "$(pwd)/.git" ]; then
        echo "Error: Not in a git repository directory. Clone may have failed."
        exit 1
    fi
fi

# Deploy dotfiles
echo "Deploying dotfiles..."
IFS=' ' read -ra DOTFILE_ARRAY <<< "$DOTFILES"
for file in "${DOTFILE_ARRAY[@]}"; do
    if [ ! -f "$file" ] && [ "$DRY_RUN" = false ]; then
        echo "Warning: Dotfile $file not found in repository"
        continue
    fi
    backup_and_copy "$file"
done

# Handle special configuration files
echo "Deploying special configuration files..."
IFS=' ' read -ra SPECIAL_CONFIG_ARRAY <<< "$SPECIAL_CONFIGS"
for config in "${SPECIAL_CONFIG_ARRAY[@]}"; do
    IFS=':' read -ra CONFIG_PARTS <<< "$config"
    source_file="${CONFIG_PARTS[0]}"
    target_file="${CONFIG_PARTS[1]}"
    
    if [ ! -f "$source_file" ] && [ "$DRY_RUN" = false ]; then
        echo "Warning: Source file $source_file not found in repository"
        continue
    fi
    
    backup_and_copy_to_dir "$source_file" "$target_file"
done

# Special handling for Neovim configuration
if $DRY_RUN; then
    echo "[Dry run] Would create symlinks for Neovim configuration"
else
    # Create Neovim config directory if it doesn't exist
    mkdir -p "$HOME/.config/nvim"
    
    # If init.nvim was deployed, make sure init.vim also exists as a symlink
    if [ -f "$HOME/.config/nvim/init.nvim" ] && [ ! -f "$HOME/.config/nvim/init.vim" ]; then
        echo "Creating symlink from init.nvim to init.vim for Neovim compatibility"
        ln -sf "$HOME/.config/nvim/init.nvim" "$HOME/.config/nvim/init.vim"
    fi
    
    # If init.vim was deployed, make sure init.nvim also exists as a symlink
    if [ -f "$HOME/.config/nvim/init.vim" ] && [ ! -f "$HOME/.config/nvim/init.nvim" ]; then
        echo "Creating symlink from init.vim to init.nvim for Neovim compatibility"
        ln -sf "$HOME/.config/nvim/init.vim" "$HOME/.config/nvim/init.nvim"
    fi
fi

# Source the .bashrc file to apply changes if not in dry run mode
if [[ -e "$HOME/.bashrc" ]] && [ "$DRY_RUN" = false ]; then
    echo "Sourcing $HOME/.bashrc to apply changes"
    source "$HOME/.bashrc" || echo "Warning: Failed to source $HOME/.bashrc"
fi

# Clean up
echo "Cleaning up temporary files"
$DRY_RUN || rm -rf "$TEMP_DIR"

echo "User initialization complete at $(date)"
if [ "$DRY_RUN" = false ]; then
    echo "You may need to restart your shell or log out and back in for all changes to take effect."
fi
