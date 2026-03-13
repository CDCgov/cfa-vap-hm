#!/usr/bin/env bash
set -euo pipefail

# 1. Install nix if not already installed
echo "> Detecting if you already have nix installed..."
if ! command -v nix &> /dev/null; then
    echo ">> Nix not detected... installing from https://nixos.org/nix/install..."
    sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
else
    echo ">> Nix already installed... skipping this step!"
fi

# 2. Enable nix-command and flakes if not already enabled
NIX_CONF="$HOME/.config/nix/nix.conf"
echo ""
echo "> Making nix config folder if it doesn't already exist..."
mkdir -p "$(dirname "$NIX_CONF")"
echo ""
echo "> Checking your nix config; will create and enable run commands and flakes if it doesn't exist."
if ! grep -q 'experimental-features.*nix-command.*flakes' "$NIX_CONF" 2>/dev/null; then
    echo ">> Turning on nix commands and flakes..."
    echo "experimental-features = nix-command flakes" >> "$NIX_CONF"
else
    echo ">> Nix experimental features already enabled."
fi

# 3. Install and initialize home-manager using the flake
echo ""
echo "> Checking if home-manager is available in your shell..."
if ! command -v home-manager &> /dev/null; then
    echo ">> home-manager not found in PATH. Installing, then switching to config defined in flake.nix."
    echo ""
    nix run home-manager -- init --switch --flake "$HOME/.config/home-manager" --impure
else
    echo ">> home-manager is already available in your shell. Skipping install but switching to config in flake.nix"
    echo ""
    home-manager switch --flake "$HOME/.config/home-manager" --impure
fi
