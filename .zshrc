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

# Chrome: stable, canary, beta, dev channel
alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
alias canary="/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary"
alias beta="/Applications/Google\ Chrome\ Beta.app/Contents/MacOS/Google\ Chrome\ Beta"
alias dev="/Applications/Google\ Chrome\ Dev.app/Contents/MacOS/Google\ Chrome\ Dev"

# Claude Code: personal login, NDS company OAuth token (1Password Environment) for inference
alias claude-nds="op run --no-masking --environment obpmof5e6ahyvo33iwr7ukqxc4 -- sh -c 'CLAUDE_CODE_OAUTH_TOKEN=\"\$NDS_CLAUDE_CODE_OAUTH_TOKEN\" exec claude \"\$@\"' claude-nds"
