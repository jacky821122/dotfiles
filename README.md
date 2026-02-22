# dotfiles

Personal configuration files for shell and developer tooling, managed across multiple machines via symlinks.

## Structure

```
dotfiles/
├── bootstrap.sh       # One-command setup for a new machine
├── wsl/
│   └── .zshrc         # Shell config for Windows WSL
└── claude/
    ├── CLAUDE.md      # Global Claude Code working principles
    ├── settings.json  # Model and hooks configuration
    ├── bootstrap.sh   # Claude-only setup (called by root bootstrap)
    ├── hooks/
    │   ├── session-start.sh        # SessionStart: prints git/project context
    │   └── auto-approve-readonly.sh # PermissionRequest: auto-approves Read/Glob/Grep
    └── skills/
        └── setup-hooks/            # /setup-hooks skill for configuring new hooks
```

## Setup on a new machine

```bash
git clone <repo> ~/dotfiles
bash ~/dotfiles/bootstrap.sh
```

The bootstrap script detects the environment (WSL / macOS / Linux) and symlinks the appropriate shell config. Claude Code config is always applied regardless of environment.

To set up Claude Code only:

```bash
bash ~/dotfiles/claude/bootstrap.sh
```

## Adding a new environment

Create a directory matching the detected environment name (`wsl`, `mac`, `linux`) and add a `.zshrc`:

```
dotfiles/
└── mac/
    └── .zshrc
```

The root `bootstrap.sh` will pick it up automatically.

## Claude Code config

詳細的設定說明與設計理念見 [claude/README.md](claude/README.md)。



`~/.claude/` contains many runtime files that should not be version-controlled (credentials, history, project cache). Only the following are managed here and symlinked individually:

| Symlink | Source |
|---|---|
| `~/.claude/settings.json` | `claude/settings.json` |
| `~/.claude/CLAUDE.md` | `claude/CLAUDE.md` |
| `~/.claude/hooks` | `claude/hooks/` |
| `~/.claude/skills` | `claude/skills/` |
| `~/.claude/rules` | `claude/rules/` |

## Archived environments

Old configs are preserved as git tags rather than kept in the working tree:

| Tag | Description |
|---|---|
| `archive/122-server` | Lab server config (Vivado, CPLEX, anaconda) |

To inspect an archived config:

```bash
git show archive/122-server:122/.zshrc
```
