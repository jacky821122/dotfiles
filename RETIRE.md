# dotfiles 退役交接（給其他機器上的 agent）

> 來源：2026-10-31 00:35–00:55（台灣時間）在原 WSL 機器上完成的脫鉤；2026-11-03 使用者確認棄用 dotfiles。

## 0. 決策

- 使用者不再用 dotfiles repo（`git@github.com:jacky821122/dotfiles.git`）追蹤本機設定。理由：本機的設定範圍已超出它原本的設計。
- 目標：讓這台機器完全不依賴 dotfiles，再刪掉本機的 clone。
- **刪本機 repo、封存 GitHub repo，都由使用者決定**。agent 只做脫鉤和驗證，最後把刪除指令交給使用者。
- 版控原則（使用者原話：「快速更動 commit 是負擔；需要歷史就 git」）：harness 程式進本機 git；skills 不進 git。

## 1. 先知道的事實（不要假設和 原機器一樣）

1. **repo 位置可能不同**。bootstrap 寫死 `$HOME/dotfiles`；原機器放在 `~/repos/dotfiles`。兩處都要找。
2. **遠端 master 只有舊內容**：`bootstrap.sh`、`wsl/.zshrc`、`wsl/.vimrc`、`claude/{CLAUDE.md,settings.json,bootstrap.sh,hooks/,skills/,rules/}`。
3. **原機器的 harness 程式（`harness-sync`、`harness/manifest.json`、systemd timer）從沒 push 過**。它們在 原機器上是未追蹤檔案。所以別台機器的 dotfiles 裡多半沒有 harness，第 3 節 harness 相關步驟可能整段不適用。先盤點再決定。
4. `bootstrap.sh`（根目錄）會 symlink：`~/.zshrc`、`~/.vimrc` → `<repo>/wsl/`。
5. 舊版 `claude/bootstrap.sh`（6/29 之後根目錄已不再呼叫，但舊機器可能跑過）會：
   - symlink `~/.claude/{CLAUDE.md,keybindings.json,hooks,skills,rules}` → `<repo>/claude/...`
   - 把 `model`、`hooks`、`permissions`、`enabledPlugins` merge 進 `~/.claude/settings.json`；hooks 指向 `~/.claude/hooks/*.sh`。若 `~/.claude/hooks` 是連到 repo 的連結，刪 repo 後 Claude Code 的 hooks 會壞。
   - `CLAUDE.md` 裡有 `@~/.claude/CLAUDE.local.md`。
6. 遠端最新兩筆 commit（`23d3f58 change rules`、`c580b1e update claude settings`）不是 原機器推的，可能就是你這台。這台可能有沒 push 的修改。

## 2. 步驟

1. **盤點依賴**（唯讀）：
   ```bash
   D=$(ls -d ~/dotfiles ~/repos/dotfiles 2>/dev/null); echo "$D"
   find ~ -xdev -maxdepth 6 -type l -lname '*dotfiles*' -printf '%p -> %l\n' 2>/dev/null | grep -v "^$D/"
   grep -rIl -e 'repos/dotfiles' -e '~/dotfiles' -e 'HOME/dotfiles' \
     ~/.zshrc* ~/.alias ~/.profile ~/.bashrc ~/.gitconfig ~/.claude ~/.codex ~/.local/share/agent-harness ~/.local/bin 2>/dev/null \
     | grep -v -e '/projects/' -e '/sessions/' -e '/file-history/' -e '\.jsonl$'
   crontab -l 2>/dev/null | grep -i dotfiles
   grep -rl dotfiles ~/.config/systemd 2>/dev/null
   readlink -f ~/.config/systemd/user/*.wants/* 2>/dev/null | grep dotfiles
   git -C "$D" status --porcelain | wc -l; git -C "$D" fetch -q; git -C "$D" log --oneline @{u}..   # 未 push 的 commit
   ```
   把結果列給使用者看，說明每個依賴怎麼處理，取得同意後再改。
2. **備份**（任何修改之前）：
   ```bash
   B=~/.claude/backups/dotfiles-decouple-$(date +%Y%m%d-%H%M%S); mkdir -p $B
   tar -C "$(dirname $D)" -czf $B/dotfiles.tgz "$(basename $D)"
   find ~ -xdev -maxdepth 6 -type l -lname '*dotfiles*' -printf '%p -> %l\n' > $B/links.txt 2>/dev/null
   ```
3. **逐項脫鉤**：
   - 單一設定檔（`~/.zshrc`、`~/.vimrc`、`~/.claude/CLAUDE.md`、`keybindings.json`）：把連結換成內容相同的一般檔案。
     `cp --remove-destination "$(readlink -f ~/.zshrc)" ~/.zshrc`
   - 目錄連結（`~/.claude/hooks`、`skills`、`rules`）：`rm` 連結（不加 `-r`、不加尾斜線），再 `cp -a <repo>/claude/<dir> ~/.claude/<dir>`。仍在用的 skill 可改放 `~/.local/share/agent-harness/skills/<name>/`，再跑 `harness-sync apply`（若這台有 harness）。
   - harness 程式（只有這台真的有時）：整包搬到 `~/.local/share/agent-harness/`，**保持** `claude/bin/` 和 `harness/` 的相對位置；改 `~/.claude/bin/*` 和 `~/.config/systemd/user/agent-harness-sync.*` 的連結；`systemctl --user daemon-reload`；再 `systemctl --user enable --now ~/.local/share/agent-harness/harness/systemd/agent-harness-sync.timer`（用絕對路徑，見坑 3）。
   - 本機 git（只有搬了 harness 時）：在 `~/.local/share/agent-harness` `git init -b main`，`.gitignore` 放 `skills/` 和 `__pycache__/`，不設 remote。
   - 文件裡寫死的路徑：`grep -rn dotfiles ~/.local/share/agent-harness ~/.claude/skills ~/.codex/skills`，逐一改掉。
4. **驗證**：把 repo 改名藏起來，確認全部正常，再改回原名：
   ```bash
   mv "$D" "$D.off"
   zsh -ic 'echo zsh ok'
   ~/.claude/bin/harness-sync check >/dev/null && echo harness ok                 # 有 harness 才跑
   systemctl --user start agent-harness-sync.service && systemctl --user show agent-harness-sync.service -p Result --value
   find ~ -xdev -maxdepth 6 -type l -lname '*dotfiles*' 2>/dev/null               # 應該沒有輸出
   mv "$D.off" "$D"
   ```
   另外開一個新的 Claude Code session，確認 hooks 和 skills 正常載入。
5. **交還使用者**：回報備份位置、沒搬的檔案、刪除指令（`rm -rf "$D"`）。由使用者自己刪。

## 3. 坑（原機器實際踩到或差點踩到的）

1. **不能先刪 repo**。`~/.zshrc` 是連結時，刪 repo 後新開的 shell 會直接壞掉。一定是先搬、再改連結、再驗證、最後才刪。
2. **用 `cp` 覆蓋連結時會寫進連結的目標**。`cp src ~/.zshrc` 在 `~/.zshrc` 是連結時，會寫進 repo 裡那份，或報 `same file`。要用 `cp --remove-destination`。
3. **`systemctl --user reenable` 會刪掉 linked unit**。unit 檔本身是指向 unit 路徑外面的連結時，`reenable` 先 disable，把 `~/.config/systemd/user/<unit>` 的連結刪掉，接著 enable 找不到 unit，報 `does not exist`。原機器的 timer 因此停了約 1 分鐘。修法是 `systemctl --user enable --now <unit 檔的絕對路徑>`，它會重建兩個連結。
4. **`is-enabled` 顯示 `enabled` 不代表連結正確**。改完連結後，`timers.target.wants/` 底下那個連結仍指向舊的 repo 路徑。要用 `readlink -f ~/.config/systemd/user/timers.target.wants/*` 確認。
5. **`harness-sync` 用 `Path(__file__).resolve().parents[2] / "harness/manifest.json"` 找 manifest**。只搬 `harness-sync` 而不搬 `harness/`，它就找不到 manifest。整包搬，保持目錄結構，程式就不用改。
6. **repo 裡的 `claude/instructions-shared.md` 和 live 檔不同**。live 來源是 `~/.claude/instructions-shared.md`（獨立檔案）。repo 那份只是安裝範本，要從 live 檔複製過去更新，不要反過來覆蓋 live 檔。
7. **文件寫死路徑**。`harness-drift` skill 的 `SKILL.md` 和 `references/sharing-map.md`，以及 harness 的 `README.md`、`install.py` 訊息，都寫了 `~/repos/dotfiles`。不改的話，skill 會指錯地方。
8. **本機有未提交或未 push 的改動**。原機器有 38 項未提交、落後遠端 2 個 commit，而且有 3 個檔案兩邊都改過。處理方式是整包 tar 備份，不 pull、不 commit、不 push。刪除前問使用者這些改動要不要保留。
9. **全域規則：不要編輯 `.zshrc` 的內容**。把連結換成內容相同的實體檔可以；要改設定請改 `.zshrc.local` 或 `.alias`。
10. **`grep` 掃描會有大量雜訊**。`~/.claude/file-history/`、`projects/`、`plans/`、Codex `sessions/` 裡的舊對話都會提到 dotfiles。這些是歷史紀錄，不是依賴，排除即可。
11. **記憶裡的舊路徑**。原機器的 quests 專案記憶 `project_cc_codex_link_map.md` 曾引用 `~/repos/dotfiles`，後來改成「已棄用（2026-11-03 確認）」。這台也要搜尋原生記憶，把仍描述 dotfiles 為現行做法的條目更新掉。

## 4. 原機器的最終狀態（參考）

- `~/.zshrc`：一般檔案。
- `~/.claude/bin/{harness-sync,check-instruction-drift}` → `~/.local/share/agent-harness/claude/bin/`
- `~/.config/systemd/user/agent-harness-sync.{service,timer}` → `~/.local/share/agent-harness/harness/systemd/`
- `~/.local/share/agent-harness`：本機 git，第一筆 commit `a30a8c4`，沒有 remote；`skills/` 不進 git。
- 18 個 harness 測試通過：`uv run --no-project python -m unittest discover -s ~/.local/share/agent-harness/harness -p 'test_*.py'`
- 沒搬、只留在備份 tar 裡：`codex/` 範本、舊 skill 副本、`claude/tests/test_models_context.py`。
- `~/repos/dotfiles` 已由使用者刪除。GitHub repo 是否封存，對話裡沒有紀錄；建議所有機器都脫鉤後再封存。

## 5. 第二台（JARVIS）的脫鉤紀錄（2026-11-14）— 給後面機器的補充

這台走法跟第 4 節不同，也多踩到幾件事：

1. **沒有 harness**：第 3 節 harness / systemd 步驟整段不適用。連結只有 `~/.zshrc`、`~/.vimrc`、`~/.claude/{CLAUDE.md,hooks,skills,rules}`。
2. **本機 git 改放 `~/.claude` 本身**（使用者選的）：`git init -b main`，`.gitignore` 用白名單（`/*` 再 `!/CLAUDE.md`、`!/CLAUDE.local.md`、`!/settings.json`、`!/rules/`、`!/hooks/`），無 remote；skills 不進 git。`CLAUDE.local.md` 可以進這種本機 repo，規則改為「never in a repo with a remote」。
3. **未提交／未 push 的修改其實就是 live 版本**（連結直接指進 working tree），`cp -a` 脫鉤後內容自然保留，tar 備份即可，不必先 commit。
4. **被 gitignore 的檔案不在別台的 clone 裡**：JARVIS 的 `claude/hooks/{notify-discord,poke}.sh`、`skills/{notify-when-done,jarvis-ops/notes,…}` 是 ignored，只存在本機 working tree。`cp -a` 會帶走；別台若需要要自己搬。
5. **skills 裡可能有指向其他 repo 的絕對連結**（如 `visual-answer`、`ai-conversation`）。`cp -a` 保留連結本身，不算 dotfiles 依賴，但那些 repo 不能刪。先 `find <repo>/claude -type l` 看一下。
6. **第 2 節的 grep 盤點會漏**：它不掃 `~/.claude/skills/*/SKILL.md`（脫鉤前是連結）與 `~/.claude/projects/*/memory/`。脫鉤後再 `grep -rn dotfiles ~/.claude/{CLAUDE.md,rules,hooks,skills} ~/.claude/projects/*/memory` 一次。`~/.claude/projects/-home-*-dotfiles/memory/` 在 repo 刪掉後會成孤兒，內容要搬到別的專案 memory。
7. **rules 文件要跟著改**：`maintenance.md`（scope、§2 step 4、§7）、`letter-to-future-sessions.md` 第 1 段、`CLAUDE.md` 的「public + shared across machines」都還把 dotfiles/bootstrap 當現行做法。依 maintenance.md 屬 ask-first，先給使用者 diff。
8. **用腳本改 markdown 時，錨點要唯一**：`## Lessons` 也出現在 maintenance.md §1 內文裡，用 `index('## Lessons')` 切會切錯、整份重複。用 `'\n## Lessons\n'` 之類的精確錨點，並在改完後檢查行數與 `grep -n '^## '`。
9. 收尾：repo 改名藏起來驗證後，開新 session 確認 hooks（看 `~/.local/state/claude-hooks/` 時間戳）與 skills 載入，再處理 repo。`~/.codex/config.toml` 的 `[projects."…/dotfiles"]` trust 段可順手刪。
