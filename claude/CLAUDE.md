# Global Claude Instructions

## Language & Communication

- 與使用者的討論一律使用台灣繁體中文，但 commit messages、技術性專有名詞、或你自己的思考等等可以保持英文，即使 skill / 工具內容是英文也不缺換語言。
- 回答預設簡短直接，有問題我會主動追問
- 不要當 yes man——如果覺得我的方向有問題，直接提出不同意見

## Working Style

- 非 trivial 的任務先從 plan mode 開始，對齊方向再動手
- Reading repo, document, code base 等理解任務時，盡量讀深入，不要只讀一部分覺得自己懂了就開始動作。除非你有把握理解我的想法或架構，否則不要裝懂。有任何不清楚或模糊的地方就向我詢問。我不介意多次來回問答互動直到你完全清楚狀況。
- Terminal-friendly output: Avoid Unicode glyphs that monospace terminals render or width-measure poorly — in particular enclosed/circled alphanumerics (e.g. ①②③, ⓵, ㊀, ⒈) and similar decorative East-Asian-width-ambiguous symbols. For enumeration use plain ASCII instead: 1. / 2. for lists, or (1) / (2) inline. Standard punctuation, Markdown tables, and a small set of common status emoji are fine.

## Environment

- User is using oh-my-zsh as default shell
- Do not directly edit `.zshrc` since it syncs with different machines. Edit `.zshrc.local` and `.alias` instead.
- **WSL ↔ Windows boundary** (this is a WSL2 environment):
  - Windows executables are not on PATH — call them by absolute path: PowerShell at
    `/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe`, `cmd.exe` at
    `/mnt/c/Windows/System32/cmd.exe`.
  - Output encoding: Windows tools default to non-UTF-8 (cp950 / UTF-16) and produce mojibake
    when fed back to the model. Force UTF-8 — PowerShell:
    `[Console]::OutputEncoding = [Text.Encoding]::UTF8`; `cmd`: run `chcp 65001` first.
  - Complex commands → write a single script file. A command with quotes / `$` / special chars
    passes through two quoting layers (zsh → PowerShell) and breaks easily; save it as a `.ps1`
    and run `powershell.exe -NoProfile -File <abs path>`.
  - Convert paths with `wslpath` (`-w` / `-u`); don't hand-edit `/mnt/c/...` ↔ `C:\...`.
  - Machine-specific facts (hostname, host/NAS IPs, GPU) live in the machine-local map imported
    at the bottom of this file — never hardcode them here (this file is public + shared across machines).
- When encountering issues such as missing tools, missing environment dependencies, uninstalled packages, etc., first confirm whether the project environment has not been properly set up. If it hasn’t, stop the current task and ask the user whether they want to set up the environment first. If the environment is already set up, and you believe the installation would be helpful for development or potentially useful in future sessions, proactively suggest the installation to the user. Do not always try to bypass the issue first.
- When encountering problems like permission failures that prevent you from successfully executing commands, directly organize the relevant commands and ask the user to execute them manually. Do not spend time trying various workaround methods.

## Machine-local

Machine-specific environment map. Loose file, not in version control.

@~/.claude/CLAUDE.local.md

