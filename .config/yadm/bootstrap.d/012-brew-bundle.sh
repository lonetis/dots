#!/usr/bin/env bash
set -euo pipefail

# Match the Brewfile exactly: install missing, then remove anything not listed.
brew bundle install --global
brew bundle cleanup --global --force
