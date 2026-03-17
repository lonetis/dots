# Path
export PATH="$PATH:/Users/louis/.bin" # custom binaries
export PATH="$PATH:/Users/louis/repos/chromium.googlesource.com/chromium/tools/depot_tools" # chromium development
export PATH="$PATH:/Users/louis/.antigravity/antigravity/bin" # google antigravity

# SSH
export SSH_AUTH_SOCK="~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# Git
export GIT_CEILING_DIRECTORIES="$HOME" # prevent git from showing home directory as a git repository in child directories

# https://github.com/starship/starship
eval "$(starship init zsh)"

# https://github.com/zsh-users/zsh-autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Docker completions
fpath=(/Users/louis/.docker/completions $fpath)
autoload -Uz compinit
compinit

# Chrome aliases
alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
alias canary="/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary"
alias beta="/Applications/Google\ Chrome\ Beta.app/Contents/MacOS/Google\ Chrome\ Beta"
alias dev="/Applications/Google\ Chrome\ Dev.app/Contents/MacOS/Google\ Chrome\ Dev"
