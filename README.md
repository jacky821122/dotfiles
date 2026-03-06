# dotfiles

跨機器管理 shell 與開發工具設定檔，透過 symlink 部署。

## 新機器設定

```bash
git clone <repo> ~/dotfiles
bash ~/dotfiles/bootstrap.sh
```

`bootstrap.sh` 會偵測環境（WSL / macOS / Linux）並 symlink 對應的 shell config。Claude Code config 則不分環境一律套用。

> bootstrap 後 `~/.zshrc` 是 symlink。機器專屬設定（token、local path 等）放 `~/.zshrc.local`，會自動被 source 但不會進 repo。

只設定 Claude Code：

```bash
bash ~/dotfiles/claude/bootstrap.sh
```

設定完成後參考 [claude/README.md](claude/README.md) 完成手動步驟。

## 目錄結構

```
dotfiles/
├── bootstrap.sh          # 主要 setup script
├── wsl/.zshrc            # WSL 環境的 shell config
├── claude/               # Claude Code 設定與 skills
└── README.md
```

新增環境只要建立對應目錄（`mac/`、`linux/`）並放入 `.zshrc`，`bootstrap.sh` 會自動偵測。

## Dependency 管理

`.zshrc` 採用 guard pattern：所有外部 dependency 都先檢查是否存在，缺少時**不會 crash**，而是印出安裝指令。

Shell 啟動時缺少 dependency 會看到類似：

```
[zshrc] oh-my-zsh not found. Install with:
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### 目前管理的 dependency

| Dependency | 必要性 | 缺少時行為 |
|---|---|---|
| [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) | 建議安裝 | 印安裝指令，fallback 到基本 `compinit` |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | 選用 | 印 `git clone` 指令，跳過 plugin |
| [zsh-completions](https://github.com/zsh-users/zsh-completions) | 選用 | 印 `git clone` 指令，跳過 plugin |
| Conda | 選用 | 靜默跳過（自動偵測 `~/.anaconda3`、`~/anaconda3`、`~/miniconda3`） |
| Google Cloud SDK | 選用 | 靜默跳過 |
| `~/.alias` | 選用 | 靜默跳過 |

### 新增 dependency

在 `.zshrc` 中使用內建的 `_zshrc_hint` helper：

```zsh
if [ -d "$HOME/.some-tool" ]; then
    source "$HOME/.some-tool/init.zsh"
else
    _zshrc_hint "some-tool" "curl -fsSL https://example.com/install.sh | bash"
fi
```

這確保：
1. 有裝的機器正常載入
2. 沒裝的機器印出安裝建議，不 crash

純 optional 的工具（沒裝也不影響日常使用）可以用靜默跳過：

```zsh
[ -f "$HOME/.optional-tool/init.zsh" ] && source "$HOME/.optional-tool/init.zsh"
```

## Claude Code config

詳細設定說明見 [claude/README.md](claude/README.md)。

## Archived environments

舊的環境設定以 git tag 保存：

| Tag | 說明 |
|---|---|
| `archive/122-server` | Lab server config（Vivado、CPLEX、anaconda） |

```bash
git show archive/122-server:122/.zshrc
```
