#!/bin/bash
# bootstrap.sh — Set up Claude Code dotfiles symlinks
# Run once per machine after cloning dotfiles

set -e

DOTFILES_CLAUDE="$HOME/dotfiles/claude"
CLAUDE_DIR="$HOME/.claude"

echo "Setting up Claude Code dotfiles..."

mkdir -p "$CLAUDE_DIR"

for item in settings.json CLAUDE.md keybindings.json hooks skills rules; do
    src="$DOTFILES_CLAUDE/$item"
    dst="$CLAUDE_DIR/$item"

    # Skip if source doesn't exist
    [ -e "$src" ] || continue

    # Back up existing non-symlink files
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "Backing up: $dst -> ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi

    ln -sf "$src" "$dst"
    echo "Linked: $dst"
done

# Make hook scripts executable
chmod +x "$DOTFILES_CLAUDE/hooks/"*.sh 2>/dev/null || true

echo "Done."
