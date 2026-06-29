#!/bin/bash
# bootstrap.sh — Full dotfiles setup for a new machine
# Usage: bash ~/dotfiles/bootstrap.sh

set -e

DOTFILES="$HOME/dotfiles"

detect_env() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "mac"
    else
        echo "linux"
    fi
}

ENV=$(detect_env)
echo "Environment: $ENV"

# Shell config
ENV_DIR="$DOTFILES/$ENV"
if [ -d "$ENV_DIR" ]; then
    if [ -f "$ENV_DIR/.zshrc" ]; then
        [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ] && mv "$HOME/.zshrc" "$HOME/.zshrc.bak" && echo "Backed up: ~/.zshrc"
        ln -sf "$ENV_DIR/.zshrc" "$HOME/.zshrc"
        echo "Linked: ~/.zshrc"
    fi
    if [ -f "$ENV_DIR/.vimrc" ]; then
        [ -f "$HOME/.vimrc" ] && [ ! -L "$HOME/.vimrc" ] && mv "$HOME/.vimrc" "$HOME/.vimrc.bak" && echo "Backed up: ~/.vimrc"
        ln -sf "$ENV_DIR/.vimrc" "$HOME/.vimrc"
        echo "Linked: ~/.vimrc"
    fi
else
    echo "No shell config found for environment '$ENV' (create $ENV_DIR/ to add one)"
fi
