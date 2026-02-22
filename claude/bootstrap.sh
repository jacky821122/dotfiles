#!/bin/bash
# bootstrap.sh — Set up Claude Code dotfiles
# Run once per machine after cloning dotfiles, or re-run to apply updates

set -e

DOTFILES_CLAUDE="$HOME/dotfiles/claude"
CLAUDE_DIR="$HOME/.claude"

echo "Setting up Claude Code dotfiles..."

mkdir -p "$CLAUDE_DIR"

# settings.json: merge dotfiles fields into local file (preserves machine-specific settings)
merge_settings() {
    local src="$DOTFILES_CLAUDE/settings.json"
    local dst="$CLAUDE_DIR/settings.json"

    # Remove old symlink if present (migrating from symlink to merge approach)
    [ -L "$dst" ] && rm "$dst"

    python3 - << PYEOF
import json, os

src = "$src"
dst = "$dst"

with open(src) as f:
    dotfiles = json.load(f)

local = {}
if os.path.exists(dst):
    with open(dst) as f:
        local = json.load(f)

# Apply shared fields from dotfiles; preserve everything else
for key in ["model", "hooks", "permissions"]:
    if key in dotfiles:
        local[key] = dotfiles[key]

# enabledPlugins: deep merge — local explicit false takes precedence (machine-specific opt-out)
if "enabledPlugins" in dotfiles:
    local_plugins = local.get("enabledPlugins", {})
    for plugin, enabled in dotfiles["enabledPlugins"].items():
        if local_plugins.get(plugin) is not False:
            local_plugins[plugin] = enabled
    local["enabledPlugins"] = local_plugins

with open(dst, "w") as f:
    json.dump(local, f, indent=2)

print(f"Merged: {dst}")
PYEOF
}

merge_settings

# Symlink the rest
for item in CLAUDE.md keybindings.json hooks skills rules; do
    src="$DOTFILES_CLAUDE/$item"
    dst="$CLAUDE_DIR/$item"

    [ -e "$src" ] || continue

    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "Backing up: $dst -> ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi

    # Remove existing symlink before creating new one (avoids ln -sf nesting into symlinked dirs)
    [ -L "$dst" ] && rm "$dst"
    ln -sf "$src" "$dst"
    echo "Linked: $dst"
done

# Make hook scripts executable
chmod +x "$DOTFILES_CLAUDE/hooks/"*.sh 2>/dev/null || true

echo "Done."
