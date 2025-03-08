# ~/.bashrc: Executed by Bash for interactive shells.

# Exit early if not running interactively to prevent unnecessary processing.
[ -z "$PS1" ] && return

# --- Security ---
# Auto-logout after 100 minutes of inactivity (customize this value as needed)
export TMOUT=6000

# --- Tokens ---
# Replace this with a prompt or secure method to load API keys
# Prompt the user for OpenAI API key if not already set
if [ -z "$OPENAI_GPT_API_KEY" ] && [ -f ~/.tokens/openai_gpt_api_key ]; then
    export OPENAI_GPT_API_KEY=$(cat ~/.tokens/openai_gpt_api_key)
elif [ -z "$OPENAI_GPT_API_KEY" ]; then
    read -sp "Enter your OpenAI GPT API Key: " OPENAI_GPT_API_KEY
    echo
    export OPENAI_GPT_API_KEY
fi

# --- Editor settings ---
# Set Neovim as the default editor
alias vi='nvim'
export EDITOR='nvim'
export VISUAL='nvim'

# --- History settings ---
# Enable history appending instead of overwriting when closing the shell
shopt -s histappend
# Improve history size management
HISTSIZE=5000
HISTFILESIZE=10000

# --- Window size management ---
# Update the window size after each command for programs that require it
shopt -s checkwinsize

# --- Prompt customization ---
# Customize command prompt to show last command exit status
PROMPT_COMMAND='LAST_COMMAND_STATUS=$?'

# --- Alias definitions ---
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -lAh'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# --- Apt alias definitions ---
# APT aliases - short and long forms
alias saptu='sudo apt update'
alias saptg='sudo apt upgrade'
alias saptf='sudo apt full-upgrade'
alias sapti='sudo apt install'
alias saptr='sudo apt remove'
alias sapta='sudo apt autoremove'
alias saptp='sudo apt purge'
alias apts='apt search'
alias aptsh='apt show'
alias aptl='apt list'
alias aptlu='apt list --upgradable'
alias saptc='sudo apt clean'
alias saptac='sudo apt autoclean'

# Keeping some long form aliases for clarity
alias apt-update='saptu'
alias apt-upgrade='saptg'
alias apt-full-upgrade='saptf'
alias apt-install='sapti'
alias apt-remove='saptr'
alias apt-autoremove='sapta'
alias apt-purge='saptp'
alias apt-search='apts'
alias apt-show='aptsh'
alias apt-list='aptl'
alias apt-list-upgradable='aptlu'
alias apt-clean='saptc'
alias apt-autoclean='saptac'

# Function for a full system update
sapt-update-all() {
    saptu
    saptf -y
    sapta -y
    saptc
    echo "System update complete."
}
alias apt-update-all='sapt-update-all'

# --- Color support ---
# Enable color support for 'ls' and directory colors
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# --- Programmable completion ---
# Enable programmable completion features if available
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# --- Command history search ---
# Use fzf for searching through command history
bind '"\C-r": "\C-a fzf_history\n"'

# --- Custom configurations ---
# Source custom alias, export, and function files for user-specific configurations
for file in ~/.bash_aliases ~/.bash_exports ~/.bash_functions; do
    if [ -r "$file" ] && [ -f "$file" ]; then
        source "$file"
    elif [ -f "$file" ]; then
        echo "Warning: $file is not readable. Skipping."
    fi
done

# --- Build environment settings ---
# ccache configuration
export CCACHE_DIR="$HOME/.ccache"
export CC="ccache gcc"
export CXX="ccache g++"

# Optional: Set the maximum cache size
export CCACHE_MAXSIZE="20G"

# Function to configure ccache on shell start
configure_ccache() {
    ccache --max-size=$CCACHE_MAXSIZE
}

# Call the function
configure_ccache

# Optimization flags for building software
export CFLAGS="-O3 -march=native -mtune=native -pipe -mfpmath=sse -funroll-loops"
export CXXFLAGS="${CFLAGS}"

# Source the developer variables, functions, and aliases
if [ -f ~/.bashrc-developer ]; then
    . ~/.bashrc-developer
fi

# --- PATH settings ---
# Prepend the user's private bin directory to the PATH if it exists
if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi

# --- Python virtual environments ---
# Activate Python virtual environments more easily with virtualenvwrapper
if [ -f /usr/local/bin/virtualenvwrapper.sh ]; then
    export WORKON_HOME=$HOME/.virtualenvs
    source /usr/local/bin/virtualenvwrapper.sh
fi

# --- Platform-specific configurations ---
# Load platform-specific configurations from a separate file
if [ -f ~/.bashrc_platform ]; then
    source ~/.bashrc_platform
fi

# --- Additional environment settings ---
# Ensure paths and environment settings are properly configured
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
export PATH="$PATH:$HOME/.local/bin"

# Securely source other private or custom shell configurations
if [ -f "$HOME/.shelloracle.bash" ]; then
    source "$HOME/.shelloracle.bash"
fi

# --- Kitty terminal integration ---
# Add completion for the Kitty terminal if applicable
if [[ "$TERM" == "xterm-kitty" ]]; then
    source <(kitty + complete setup bash)
fi

# Initialize Starship prompt if installed
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# Function to list all aliases
list_aliases() {
    printf "%-20s %s\n" "Alias" "Command"
    printf "%-20s %s\n" "-----" "-------"
    alias | sort | sed "s/alias //" | sed "s/='/ /" | sed "s/'$//" | \
    while read -r line; do
        alias=$(echo $line | cut -d' ' -f1)
        command=$(echo $line | cut -d' ' -f2-)
        printf "%-20s %s\n" "$alias" "$command"
    done
}

# Alias for the list_aliases function
alias aliases='list_aliases'

# --- Completion message ---
echo "--- .bashrc successfully loaded ---"
