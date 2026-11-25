#!/usr/bin/env bash
set -euo pipefail

# Builds the OmniWM helper that Karabiner's OmniWM bindings run (see .docs/omniwm.md). Only
# its Go sources are tracked; the Karabiner build rebuilds it after every change.
npm --prefix "$HOME/.config/karabiner-config" run helper
