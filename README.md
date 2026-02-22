# dotfiles

Personal configuration files for shell and developer tooling, managed across multiple machines via symlinks.

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

## Archived environments

Old configs are preserved as git tags rather than kept in the working tree:

| Tag | Description |
|---|---|
| `archive/122-server` | Lab server config (Vivado, CPLEX, anaconda) |

To inspect an archived config:

```bash
git show archive/122-server:122/.zshrc
```
