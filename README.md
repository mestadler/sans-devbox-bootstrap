# DevBox Setup

DevBox Setup is a collection of scripts and configuration files to quickly set up a development environment on Debian-based systems. It automates the installation of essential packages, system configuration, and user-specific settings to get you up and running quickly.

## Version

- Current Version: 2.0
- Last Updated: 2025-03-09

## Features

- **Two-Phase Setup**: Separates system setup from user configuration
- **Customizable**: Fully configurable through environment variables
- **Comprehensive**: Installs development tools, programming languages, utilities, and more
- **Kubernetes Ready**: Sets up Kubernetes automatically
- **User Environment**: Configures shell, editor, git, and other developer tools
- **Multiple Installation Methods**: Choose from one-line installers or manual setup

## Quick Start

### Option 1: Automatic Installation (Recommended for New Users)

Run the following command to start the interactive installation process:

```bash
bash -c "$(curl -sSL https://raw.githubusercontent.com/mestadler/sans-devbox-bootstrap/main/install.sh)"
```

This will:
1. Download the necessary scripts
2. Ask for your configuration preferences
3. Create a customized environment file
4. Run the system setup (requires sudo)
5. Run the user configuration

### Option 2: Installation with Existing .env File

If you already have a configured `.env` file, use:

```bash
bash -c "$(curl -sSL https://raw.githubusercontent.com/mestadler/sans-devbox-bootstrap/main/install-local-env.sh)" _ /path/to/your/.env
```

### Option 3: Manual Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/mestadler/sans-devbox-bootstrap.git
   cd sans-devbox-bootstrap
   ```

2. Create your environment file:
   ```bash
   cp .env_example .env
   ```

3. Edit `.env` with your specific details:
   ```bash
   nano .env
   ```

4. Run the system setup script:
   ```bash
   sudo ./devbox-init.sh .env
   ```

5. Run the user configuration script:
   ```bash
   ./devbox-user-init.sh .env
   ```

## Understanding the Scripts

### devbox-init.sh

This script performs system-level setup and must be run as root:

- Configures system locale and timezone
- Sets up network settings
- Installs specified packages
- Performs a full system upgrade
- Configures automatic security updates
- Sets up Kubernetes

### devbox-user-init.sh

This script handles user-specific configurations and must be run as a regular user:

- Clones your configuration repository
- Deploys dotfiles (.bashrc, .vimrc, etc.)
- Sets up special configuration files
- Configures development tools
- Provides a dry-run option for testing

## Configuration

The `.env` file contains all necessary configuration settings. Key sections include:

### System Configuration
```bash
LANG="en_GB.UTF-8"
LC_ALL="en_GB.UTF-8"
TZ="Europe/London"
KUBERNETES_VERSION="1.32.2-00"
PACKAGES="apt-transport-https apt-utils [...]"
```

### User Configuration
```bash
GITHUB_USERNAME="your-github-username"
DEBFULLNAME="Your Full Name"
DEBEMAIL="your-email@example.com"
REPO_URL="https://github.com/username/devbox-setup.git"
DOTFILES=".bashrc .bashrc-developer .gitconfig .vimrc .sgptrc"
```

### API Keys and Application Settings
```bash
GITHUB_TOKEN="your-github-token"
OPENAI_GPT_API_KEY="your-openai-api-key"
DEFAULT_MODEL="gpt-4o-2024-05-13"
```

## Customization

### Package Selection

Modify the `PACKAGES` variable in `.env` to customize what software gets installed.

### Repository Configuration

By default, user configuration files are cloned from your specified repository. Update the `REPO_URL` in your `.env` file to use your own repository.

### Dotfiles

The `DOTFILES` variable defines which configuration files are managed by the script. Add or remove files as needed.

## Advanced Usage

### Dry Run

To test user configuration without making changes:

```bash
./devbox-user-init.sh .env --dry-run
```

### Individual Dotfiles

You can selectively update dotfiles by modifying the `DOTFILES` variable in your `.env` file.

## Security Note

The `.env` file contains sensitive information such as API keys and tokens. Keep it secure and do not share it publicly.

## Supported Environments

- Debian-based distributions (Debian, Ubuntu, etc.)
- Tested on Ubuntu 22.04 LTS and Debian 11

## Contributing

Contributions to improve DevBox Setup are welcome. Please feel free to submit pull requests or create issues for bugs and feature requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to all devs who have shared their dotfiles and configurations
- Special appreciation to the open-source community for the tools and packages included
