#!/usr/bin/env bash
set -euo pipefail

# Homebrew first: git-crypt (001) and every later step that installs software need it.
# .init.sh installs it already; this covers a `yadm bootstrap` run without it. The runner
# puts /opt/homebrew/bin on PATH, so the later steps find a Homebrew installed here.

if [[ ! -x /opt/homebrew/bin/brew ]]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
