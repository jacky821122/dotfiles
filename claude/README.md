# Claude Code 設定備忘錄

---

## 新機器設定清單

`bootstrap.sh` 會自動處理 symlinks，但以下項目需要手動完成：

### 1. 安裝 LSP Language Server Binaries

| 語言 | 安裝指令 | 備註 |
|---|---|---|
| Python | `pip install pyright` | |
| C/C++ | `sudo apt-get install clangd` | NAS 的 entware 沒有，跳過 |
| JavaScript | `npm install -g --prefix ~/.local typescript-language-server typescript` | |

### 2. 在 Claude Code 啟用 LSP Plugins

```
/plugin install pyright-lsp@claude-plugins-official
/plugin install clangd-lsp@claude-plugins-official
/plugin install typescript-lsp@claude-plugins-official
```

> `settings.json` 裡已有 `enabledPlugins` 紀錄（透過 symlink 同步），但仍需執行上述指令讓 Claude Code 與本機 binary 完成連結。

**機器上若沒安裝某個 binary（如 NAS 上的 clangd），必須在 bootstrap 後手動將該 plugin 設為 false，否則 Claude Code 啟動時會等待 timeout：**

```bash
python3 -c "
import json
path = '/var/services/homes/jacky821122/.claude/settings.json'
with open(path) as f: s = json.load(f)
s.setdefault('enabledPlugins', {})['clangd-lsp@claude-plugins-official'] = False
with open(path, 'w') as f: json.dump(s, f, indent=2)
"
```

這個 `false` 在下次 bootstrap 時會被保留（deep merge 設計）。

### 3. 設定機器特定的環境變數

Bootstrap 後 `~/.zshrc` 是 symlink，機器專屬的設定（token 等）放在 `~/.zshrc.local`——這個檔案不進 dotfiles，每台機器各自維護：

```bash
# ~/.zshrc.local
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_..."
```

Token 需要的 scope：`repo`、`read:org`、`read:user`

`~/.zshrc` 會自動 source `~/.zshrc.local`（若存在）。

### 4. 設定 GitHub MCP

確認 token 已 export 後執行：

```bash
python3 -c "
import json, os
path = os.path.expanduser('~/.claude.json')
with open(path) as f: config = json.load(f)
config.setdefault('mcpServers', {})['github'] = {'type': 'stdio', 'command': 'npx', 'args': ['-y', '@modelcontextprotocol/server-github'], 'env': {'GITHUB_PERSONAL_ACCESS_TOKEN': os.environ.get('GITHUB_PERSONAL_ACCESS_TOKEN', '')}}
with open(path, 'w') as f: json.dump(config, f, indent=2)
print('Done')
"
```

重啟 Claude Code 後，`/mcp` 應可看到 github server 已連線。

---

## 整體設計理念

`~/.claude/` 裡有很多 Claude Code 自動產生的 runtime 檔案（歷史紀錄、credentials、專案快取等），這些不應該進版本控制。所以這個資料夾只管理「真正需要追蹤」的幾個檔案，透過 symlink 掛進 `~/.claude/`：

```
dotfiles/claude/          ~/.claude/
├── settings.json    →    settings.json  （merge，非 symlink）
├── CLAUDE.md        →    CLAUDE.md      （symlink）
├── hooks/           →    hooks/         （symlink）
├── skills/          →    skills/        （symlink）
└── rules/           →    rules/         （symlink）
```

`settings.json` 用 merge 而非 symlink：bootstrap 每次執行時，會將 dotfiles 的 `model`、`hooks`、`enabledPlugins` 寫入本機的 `settings.json`，其餘欄位（如 `autoUpdaterStatus: disabled`）保留不動。這讓每台機器可以有自己的 Claude Code 設定，而不影響全域同步的核心設定。

---

## CLAUDE.md — 給 Claude 的全域工作原則

每次開新 session，Claude 都會讀這份文件。目前設定的原則包含：

- **非 trivial 的任務一律從 plan mode 開始**，先對齊方向再動手
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

### Hooks 詳細說明

**`session-start.sh`**：新 session 開始時輸出當前目錄、日期、git branch、最近 3 個 commit、是否有 project CLAUDE.md。

**`auto-approve-readonly.sh`**：Read、Glob、Grep、LS、TodoRead 自動批准，其他操作仍需確認。

**`post-edit-lint.sh`**：Edit 或 Write 後自動跑對應 linter：

| 檔案類型 | Linter |
|---|---|
| `.py` | `flake8` |
| `.js` / `.jsx` / `.mjs` | `eslint` |
| `.ts` / `.tsx` | `eslint` |
| `.go` | `golint` |
| `.sh` / `.bash` | `shellcheck` |

---

## Skills

### `setup-hooks`（`/setup-hooks`）

幫我設定新的 Claude Code hook，不用每次重新查文件。

使用方式：`/setup-hooks [hook類型] [你想做的事]`

例如：
- `/setup-hooks PostToolUse 每次跑完測試後顯示覆蓋率`
- `/setup-hooks SessionStart 自動讀取 .env.example 提醒我哪些環境變數需要設定`

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

---

## 已知機器限制

### NAS（146-7, Synology, AMD Ryzen Embedded R1600）

- **啟動慢（~1-2 分鐘）**：Claude Code 完整初始化需載入約 500MB JS 模組，在 NAS 的 HDD 上 cold start 慢是硬體限制，非設定問題。建議減少重啟頻率。
- **clangd 不可用**：entware 無此套件，手動編譯過於麻煩。bootstrap 後需手動將 `clangd-lsp@claude-plugins-official` 設為 `false`（見上方說明）。
- **版本鎖定在 2.1.25**：較新版本在此 kernel 版本上會 hang。`~/.claude.json` 已設 `autoUpdates: false`；另以 `chmod a-w ~/.local/share/claude/versions/` 防止自動更新覆蓋（NAS 的 filesystem 不支援 `chattr +i`）。
