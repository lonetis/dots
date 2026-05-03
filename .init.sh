#!/usr/bin/env bash
set -euo pipefail

# Clone over HTTPS (no SSH key needed on a fresh machine), then switch the
# remote to SSH after clone so future pull/push use the 1Password SSH agent.
DOTS_REPO_HTTPS="https://github.com/lonetis/dots.git"
DOTS_REPO_SSH="git@github.com:lonetis/dots.git"

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew already installed."
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  echo "brew not found in PATH after installation." >&2
  exit 1
fi

if ! command -v yadm >/dev/null 2>&1; then
  echo "Installing yadm..."
  brew install yadm
else
  echo "yadm already installed."
fi

if ! command -v git-crypt >/dev/null 2>&1; then
  echo "Installing git-crypt..."
  brew install git-crypt
else
  echo "git-crypt already installed."
fi

YADM_REPO="${XDG_DATA_HOME:-$HOME/.local/share}/yadm/repo.git"

if [[ -d "$YADM_REPO" ]]; then
  echo "Dotfiles already cloned, pulling latest..."
  yadm pull
  echo "Re-running bootstrap..."
  yadm bootstrap
else
  echo "Cloning dotfiles from ${DOTS_REPO_HTTPS}..."
  yadm clone --bootstrap "${DOTS_REPO_HTTPS}"
  echo "Switching remote to SSH (${DOTS_REPO_SSH})..."
  yadm remote set-url origin "${DOTS_REPO_SSH}"
fi

echo "Done."
