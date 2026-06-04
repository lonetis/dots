# ==============================================================================
# Environment Variables
# ==============================================================================

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# PATH: local binaries
export PATH="$PATH:$HOME/.local/bin"

# PATH: user binaries
export PATH="$PATH:$HOME/.bin"

# PATH: chromium development (depot_tools)
export PATH="$PATH:$HOME/repos/chromium.googlesource.com/chromium/tools/depot_tools"

# PATH: google antigravity
export PATH="$PATH:$HOME/.antigravity/antigravity/bin"

# SSH: 1password ssh agent
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# Git: prevent git from showing home directory as a git repository in child directories
export GIT_CEILING_DIRECTORIES="$HOME"
