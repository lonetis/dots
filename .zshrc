export PATH="$PATH:/Users/louis/.bin"
export PATH="$PATH:/Users/louis/.local/bin"
export PATH="$PATH:/Users/louis/Developer/depot_tools"

export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

#fpath+=~/.zfunc; autoload -Uz compinit; compinit

#zstyle ':completion:*' menu select
#export PATH="/opt/homebrew/bin:$PATH"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/louis/.lmstudio/bin"
# End of LM Studio CLI section

export GIT_CEILING_DIRECTORIES="$HOME"

alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
alias canary="/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary"

# https://github.com/starship/starship
# eval "$(starship init zsh)"

# https://github.com/zsh-users/zsh-autosuggestions
# source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Added by Antigravity
export PATH="/Users/louis/.antigravity/antigravity/bin:$PATH"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/louis/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

#export NVM_DIR="$HOME/.nvm"
#[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
#[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
