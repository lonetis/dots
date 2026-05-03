#!/usr/bin/env bash
set -euo pipefail

brew cleanup --prune=all
brew autoremove
