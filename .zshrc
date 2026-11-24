# ==============================================================================
# Colors
# ==============================================================================

# Apple HIG: system colors and iOS system grays as hex, one array per appearance (https://developer.apple.com/design/human-interface-guidelines/color#Specifications)
# Use them as %F{$hig_dark[red]} in prompts and print -P, or fg=$hig_dark[gray] in highlight styles
typeset -A hig_light=(
  red    '#FF383C'  orange '#FF8D28'  yellow '#FFCC00'  green  '#34C759'
  mint   '#00C8B3'  teal   '#00C3D0'  cyan   '#00C0E8'  blue   '#0088FF'
  indigo '#6155F5'  purple '#CB30E0'  pink   '#FF2D55'  brown  '#AC7F5E'
  gray   '#8E8E93'  gray2  '#AEAEB2'  gray3  '#C7C7CC'  gray4  '#D1D1D6'
  gray5  '#E5E5EA'  gray6  '#F2F2F7'
)
typeset -A hig_dark=(
  red    '#FF4245'  orange '#FF9230'  yellow '#FFD600'  green  '#30D158'
  mint   '#00DAC3'  teal   '#00D2E0'  cyan   '#3CD3FE'  blue   '#0091FF'
  indigo '#6D7CFF'  purple '#DB34F2'  pink   '#FF375F'  brown  '#B78A66'
  gray   '#8E8E93'  gray2  '#636366'  gray3  '#48484A'  gray4  '#3A3A3C'
  gray5  '#2C2C2E'  gray6  '#1C1C1E'
)
typeset -A hig_light_contrast=(
  red    '#E9152D'  orange '#C55300'  yellow '#A16A00'  green  '#008932'
  mint   '#008575'  teal   '#008198'  cyan   '#007EAE'  blue   '#1E6EF4'
  indigo '#564ADE'  purple '#B02FC2'  pink   '#E7124D'  brown  '#956D51'
  gray   '#6C6C70'  gray2  '#8E8E93'  gray3  '#AEAEB2'  gray4  '#BCBCC0'
  gray5  '#D8D8DC'  gray6  '#EBEBF0'
)
typeset -A hig_dark_contrast=(
  red    '#FF6165'  orange '#FFA056'  yellow '#FEDF43'  green  '#4AD968'
  mint   '#54DFCB'  teal   '#3BDDEC'  cyan   '#6DD9FF'  blue   '#5CB8FF'
  indigo '#A7AAFF'  purple '#EA8DFF'  pink   '#FF8AC4'  brown  '#DBA679'
  gray   '#AEAEB2'  gray2  '#7C7C80'  gray3  '#545456'  gray4  '#444446'
  gray5  '#363638'  gray6  '#242426'
)

# ==============================================================================
# Shell Integrations
# ==============================================================================

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
