#!/usr/bin/env bash
set -euo pipefail

DOTS_REPO="git@github.com:lonetis/dots.git"

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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

YADM_REPO="${XDG_DATA_HOME:-$HOME/.local/share}/yadm/repo.git"

if [[ -d "$YADM_REPO" ]]; then
  echo "Dotfiles already cloned, pulling latest..."
  yadm pull
  echo "Re-running bootstrap..."
  yadm bootstrap
else
  echo "Cloning dotfiles from ${DOTS_REPO}..."
  yadm clone --bootstrap "${DOTS_REPO}"
fi

echo "Done."
