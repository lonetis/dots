# ==============================================================================
# Environment Variables
# ==============================================================================

# PATH: custom binaries
export PATH="$PATH:$HOME/.bin"

# PATH: chromium development (depot_tools)
export PATH="$PATH:$HOME/repos/chromium.googlesource.com/chromium/tools/depot_tools"

# PATH: google antigravity
export PATH="$PATH:$HOME/.antigravity/antigravity/bin"

# SSH: 1password ssh agent
export SSH_AUTH_SOCK="~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# Git: prevent git from showing home directory as a git repository in child directories
export GIT_CEILING_DIRECTORIES="$HOME"

# ==============================================================================
# Shell Integrations
# ==============================================================================

# Starship prompt (https://github.com/starship/starship)
eval "$(starship init zsh)"

# ZSH Autosuggestions (https://github.com/zsh-users/zsh-autosuggestions)
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Docker completions (https://docs.docker.com/engine/cli/completion/)
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit

# ==============================================================================
# Aliases
# ==============================================================================

# Chrome: stable channel
alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"

# Chrome: canary channel
alias canary="/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary"

# Chrome: beta channel
alias beta="/Applications/Google\ Chrome\ Beta.app/Contents/MacOS/Google\ Chrome\ Beta"

# Chrome: dev channel
alias dev="/Applications/Google\ Chrome\ Dev.app/Contents/MacOS/Google\ Chrome\ Dev"

# Dotfiles: open yadm-managed dotfiles in VS Code
alias dots-code='GIT_DIR="$HOME/.local/share/yadm/repo.git" GIT_WORK_TREE="$HOME" code "$HOME"'

# Dotfiles: stage, commit (per CLAUDE.md commit conventions), and push yadm changes via claude
alias dots-commit='claude -p "Run \`yadm status\` and \`yadm diff\` to review changes, then stage all changes with \`yadm add\`, create a commit with \`yadm commit\` following the configured commit conventions, and push with \`yadm push\`." --allowedTools "Bash"'

# Dotfiles: dump global Brewfile with descriptions
alias dots-brew-bundle-dump='brew bundle dump --global --force --describe'
