# Claude Code 設定備忘錄

這份文件記錄我對 Claude Code 做了哪些設定與優化，方便自己日後回顧或修改。

---

## 整體設計理念

`~/.claude/` 裡有很多 Claude Code 自動產生的 runtime 檔案（歷史紀錄、credentials、專案快取等），這些不應該進版本控制。所以這個資料夾只管理「真正需要追蹤」的幾個檔案，透過 symlink 掛進 `~/.claude/`：

```
dotfiles/claude/          ~/.claude/（symlink）
├── settings.json    →    settings.json
├── CLAUDE.md        →    CLAUDE.md
├── hooks/           →    hooks/
├── skills/          →    skills/
└── rules/           →    rules/
```

---

## CLAUDE.md — 給 Claude 的全域工作原則

每次開新 session，Claude 都會讀這份文件。目前設定的原則包含：

- **非trivial 的任務一律從 plan mode 開始**，先對齊方向再動手
- **保持 session 乾淨**：這個對話只負責討論和 review，實際改 code 交給 subagent 或 worktree
- **最小變更原則**：不要做超出需求的 refactor、不要加多餘的註解
- **新專案開始時**先讀 CLAUDE.md，再快速掃描專案結構，不要急著動 code
- **CLAUDE.md 是階層式的**：專案層級的 CLAUDE.md 優先於這份全域設定，可以用 `@path` import 共用規則

---

## settings.json — 模型與 hooks 設定

### 模型

```json
"model": "opusplan"
```

預設使用 Opus + Plan mode，讓 Claude 在回應前先規劃。

### Hooks 概覽

| Hook 事件 | 觸發時機 | 做什麼 |
|---|---|---|
| `SessionStart` | 每次開新 session | 印出當前目錄、git branch、最近 3 個 commit |
| `PermissionRequest` | Claude 要使用某工具時 | 自動批准唯讀操作（Read/Glob/Grep/LS） |
| `PostToolUse` | 每次 Edit 或 Write 完成後 | 自動跑 linter，有問題就輸出給 Claude |

---

## Hooks 詳細說明

### `session-start.sh`（SessionStart）

新 session 開始時自動執行，輸出：
- 當前目錄路徑與日期
- 如果在 git repo 內：目前 branch + 最近 3 個 commit
- 是否有 project CLAUDE.md

這讓 Claude 一開場就有基本的專案 context，不用每次手動說明。

### `auto-approve-readonly.sh`（PermissionRequest）

當 Claude 要使用 Read、Glob、Grep、LS、TodoRead 時自動批准，不需要我手動按確認。
其他需要 permission 的操作（例如 Bash 執行、寫入檔案）還是走正常流程。

### `post-edit-lint.sh`（PostToolUse）

每次 Claude 編輯或建立檔案後，自動根據副檔名跑對應的 linter：

| 檔案類型 | Linter |
|---|---|
| `.py` | `flake8` |
| `.js` / `.jsx` / `.mjs` | `eslint` |
| `.ts` / `.tsx` | `eslint` |
| `.go` | `golint` |
| `.sh` / `.bash` | `shellcheck` |

有問題才輸出，沒問題靜默。Linter 沒裝的話自動跳過，不影響正常使用。
效果是讓 Claude 在改完 code 的當下就看到 linting 問題，形成自動修正的閉環。

---

## Skills

### `setup-hooks`（`/setup-hooks`）

用途：幫我設定新的 Claude Code hook，不用每次重新查文件。

使用方式：在 Claude Code 輸入框輸入 `/setup-hooks [hook類型] [你想做的事]`

例如：
- `/setup-hooks PostToolUse 每次跑完測試後顯示覆蓋率`
- `/setup-hooks SessionStart 自動讀取 .env.example 提醒我哪些環境變數需要設定`

---

## LSP Plugins

讓 Claude 即時看到 language server 的靜態分析結果（型別錯誤、import 找不到等），比 post-edit linter 更即時、更語義化。

### 已安裝的 Language Server Binaries

| 語言 | Binary | 安裝方式 |
|---|---|---|
| Python | `pyright-langserver` | `pip install pyright` |
| C/C++ | `clangd` | `sudo apt-get install clangd` |
| JavaScript | `typescript-language-server` | `npm install -g --prefix ~/.local typescript-language-server typescript` |

### 在 Claude Code 啟用 Plugin

Language server binary 裝好後，在 Claude Code 輸入框執行：

```
/plugin install pyright-lsp@claude-plugins-official
/plugin install clangd-lsp@claude-plugins-official
/plugin install typescript-lsp@claude-plugins-official
```

裝好後自動生效，不需要額外設定。

---

## MCP Servers

MCP 讓 Claude 直接連接外部工具與資料來源。設定寫入 `~/.claude.json`，**不進 dotfiles**（因為該檔含有 runtime state），新機器需重新執行以下指令。

### GitHub MCP

讓 Claude 直接讀寫 GitHub 的 PR、issues、comments，不用手動複製貼上。

**設定指令（新機器執行一次）：**
```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
```

**認證（設定後執行一次）：**
在 Claude Code 輸入 `/mcp`，選 github 做 OAuth 認證。

---

## 常用參考

**支援的 Hook 事件完整列表：**
`SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`,
`PostToolUse`, `PostToolUseFailure`, `Notification`, `SubagentStart`,
`SubagentStop`, `Stop`, `TeammateIdle`, `TaskCompleted`, `ConfigChange`,
`WorktreeCreate`, `WorktreeRemove`, `PreCompact`, `SessionEnd`

**新增 hook 的流程：**
1. 在 `hooks/` 建立 `.sh` script，記得 `chmod +x`
2. 在 `settings.json` 的對應事件下新增 `command` 指向該 script
3. commit + push

**新增 skill 的流程：**
1. 在 `skills/<skill-name>/` 建立 `SKILL.md`，開頭寫 frontmatter（name、description、user-invocable: true）
2. commit + push
3. 之後在 Claude Code 輸入 `/<skill-name>` 即可使用
