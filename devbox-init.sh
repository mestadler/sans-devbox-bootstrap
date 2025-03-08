#!/bin/bash

# devbox-init.sh
# 
# Description:
#   This script initializes a dev box with necessary system configurations,
#   packages, and system settings. Should be run as root.
#
# Usage:
#   sudo ./devbox-init.sh [path_to_env_file]
#
# Arguments:
#   [path_to_env_file]: Optional path to the environment file (default: .env)
#
# Note:
#   - This script should be run as root.
#   - After completion, run user-config-deploy.sh separately as a regular user.
#
# /mes - https://github.com/mestadler/sans-devbox-bootstrap

set -e

SCRIPT_VERSION="3.0"
LAST_UPDATED="2025-03-08"

# Ensure /usr/bin is in the PATH
export PATH="/usr/bin:$PATH"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root."
    echo "Usage: sudo $0 [path_to_env_file]"
    exit 1
fi

# Handle environment file
ENV_FILE="${1:-.env}"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE file does not exist."
    echo "Please create it from .env_example before continuing."
    exit 1
fi

# Function to read .env file
load_env() {
    set -a
    source "$ENV_FILE"
    set +a
}

# Load environment variables
load_env

echo "PATH after loading .env: $PATH"

export DEBIAN_FRONTEND=noninteractive

# Set up logging
LOG_FILE="./devbox_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Starting devbox-init.sh version $SCRIPT_VERSION (Last updated: $LAST_UPDATED)"
echo "Setup started at $(date)"

# Test if common commands are accessible
for cmd in tee ls cat grep; do
    if command -v $cmd > /dev/null 2>&1; then
        echo "$cmd is available at $(which $cmd)"
    else
        echo "Error: $cmd is not found in PATH"
        exit 1
    fi
done

echo "Configuring locale and timezone..."
locale-gen "$LANG" || { echo "Failed to generate locale"; exit 1; }
update-locale LANG="$LANG" LC_ALL="$LC_ALL" || { echo "Failed to update locale"; exit 1; }
timedatectl set-timezone "$TZ" || { echo "Failed to set timezone"; exit 1; }

echo "Configuring network settings..."
hostnamectl set-hostname "" || { echo "Warning: Failed to set hostname"; }
sed -i '/127.0.1.1/d' /etc/hosts
echo "127.0.0.1 localhost" | tee -a /etc/hosts
echo "::1 localhost ip6-localhost ip6-loopback" | tee -a /etc/hosts

echo "Updating package lists..."
apt update || { echo "Failed to update package lists"; exit 1; }

echo "Installing packages..."
# shellcheck disable=SC2086
apt install -y $PACKAGES || { echo "Failed to install packages"; exit 1; }

echo "Performing full system upgrade..."
apt dist-upgrade -y || { echo "Failed to perform system upgrade"; exit 1; }

echo "Configuring automatic security updates..."
apt install -y unattended-upgrades || { echo "Failed to install unattended-upgrades"; exit 1; }
dpkg-reconfigure -plow unattended-upgrades || { echo "Failed to configure unattended-upgrades"; exit 1; }

echo "Setting up Starship globally"
curl -fsSL https://starship.rs/install.sh | sh -s -- -y || { echo "Failed to install Starship"; exit 1; }

echo "Setting up Kubernetes..."
if command -v gpg > /dev/null 2>&1; then
    mkdir -p /etc/apt/keyrings
    curl -fsSL "https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

    apt update
    apt install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl
    systemctl enable --now kubelet
else
    echo "Warning: gpg command not found. Skipping Kubernetes setup."
fi

# Create a temporary user configuration script that can be run later
USER_PROMPT_SCRIPT="/tmp/run_user_config.sh"
cat > "$USER_PROMPT_SCRIPT" << 'EOF'
#!/bin/bash
cat << "PROMPT"

====================================================================
                SYSTEM CONFIGURATION COMPLETE
====================================================================

To complete the user-level configuration, please run:

    ./devbox-user-init.sh .env

as your regular user (not root).
====================================================================

PROMPT
EOF

chmod +x "$USER_PROMPT_SCRIPT"

# Cleanup
echo "Cleaning up..."
apt autoremove -y
apt clean

echo "System setup complete at $(date)"
echo "Please reboot your system when convenient."

# Display the prompt for user configuration
bash "$USER_PROMPT_SCRIPT"
