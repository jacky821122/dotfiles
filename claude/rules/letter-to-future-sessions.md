# 給未來 session 的信

寫於 2026-07-03，Fable 5。這是這個環境唯一一次由這個等級的模型建制度，之後的 session
由 Sonnet／Opus／Haiku 執行。這封信講三件使用者沒問、但我認為最重要的事，以及這套制度
最可能的退化方式。規則本體在同目錄其他檔案；這裡只講「為什麼」與「會怎麼壞」。

## 三件沒被問、但最重要的事

### 1. 設定的真相來源在 repo，不在 live 檔案

`bootstrap.sh` 每次執行都會用 repo 的 `claude/settings.json` 覆寫本機 `settings.json`
的 `model`、`hooks`、`permissions` 三個 key。直接改 live 檔案的這三項，下次 bootstrap
就會默默還原——2026-07 我就拆過一顆這種雷：live model 被 /model 設成了短期活動的
`claude-fable-5[1m]`，而 repo 是 `opusplan`；兩邊不一致的期間，repo 想要的模型分層
根本沒在跑。規則：動這三個 key 一律改 repo copy（或兩邊一起改），其他 key 才是機器自由。
另外 NAS 那台 Claude Code 鎖在 2.1.25（新版會 hang）——任何依賴新 harness 功能的規則
到了那台機器都可能不存在，先驗證再依賴（maintenance.md §6、§7）。

### 2. 省額度的第一名行為是「結束 session」，不是任何聰明技巧

實測數據（diagnosis-2026-07.md）：一個 437 回合的 session 累積 82M cache-read tokens，
平均每回合背著 18 萬 token 的舊 context。同樣的工作拆成三個乾淨的 session，成本可能不到
一半。所以：任務告一段落、下個任務用不到目前大部分 context 時，主動提議 `/handoff` 開新
session——使用者已經建好 handoff/pickup skill，缺的只是有人開口。這比模型分層、比委派
都省得多。但注意反方向的失敗一樣糟：為一個已知的小檔案開 subagent 是純浪費（冷啟動
10-20k tokens）。判準永遠是 token 質量，不是儀式感（delegation.md §1）。

### 3. 資訊有三層，別寫錯層；memory 至今是空的

全域行為規則 → `rules/*.md`；專案事實 → 該專案的 CLAUDE.md 或 memory（`MEMORY.md`
索引 + 單檔單事實）；機器事實 → `CLAUDE.local.md`（永不進 git，可放內網位址）。
判斷法：「這句話換一台機器／換一個 repo 還成立嗎？」（maintenance.md §4）。
到 2026-07 為止 memory 機制完全沒被用起來——每個專案值得記的事（測試怎麼跑、部署的
坑、使用者對該專案的目標）都隨 session 蒸發了。從今天開始用。
順帶一件實測到的事：這位使用者回答問題又快又準（平均每 session 回 4-5 個
AskUserQuestion）。弱模型的天性是不敢問、悶頭猜——在這個環境是反最佳解。按
judgment.md §3 的判準，該問就問，附具體選項與你的建議。

## 這套制度最可能的退化方式（按可能性排序）與預防

1. **規則根本沒被讀。** 指望弱模型自發去讀檔案是不現實的，所以觸發句已內嵌在
   CLAUDE.md Operating Core（每個 session 必載）：第一次 Agent call 前讀 delegation.md、
   宣告完成前讀 judgment.md。使用者端的矯正也便宜：發現 session 亂做，一句
   「照 delegation.md 做」就能拉回。客觀偵測法：跑 diagnosis 的 re-audit——如果
   cache-read/session 沒降、sidechain 還是 0，就是沒人在守規則。
2. **Lessons 區膨脹成垃圾場**，訊號被雜訊淹沒。預防：每檔 250 行、Lessons 15 條上限，
   超了就觸發整併提案（maintenance.md §5）。整併是「向使用者提案」，不是默默刪。
3. **貨物崇拜式委派**——為了遵守規則而什麼都開 agent，或嫌麻煩什麼都不開。預防：
   delegation.md §1 的門檻是量化的（>300 行閱讀、>5 檔批改、>3 檔搜索），§9 列了
   反模式。委派的目的是把 token 花在便宜的地方，不是表演流程。
4. **驗證劇場**——verifier 蓋章但沒真的查。預防已內建：Verify 模板要求逐項引用證據，
   「PASS 但沒證據」必須改判 UNVERIFIABLE；verifier 只拿驗收清單與檔案路徑，
   永遠不拿實作過程的對話（anchoring 會殺死驗證）。如果發現 verifier 全部秒過，
   就該起疑——抽一項自己查。
5. **制度凍結、環境前進。** 模型名、agent 型號、harness 功能都會變；使用者的偏好
   也會變。這些檔案是工具不是憲法：事實錯了按 maintenance.md §1 自助修（附證據），
   方向錯了使用者一句話就能改。最糟的結局不是規則被改壞，是規則過時後被整批無視。

## 誠實條款（最後一次由我親自說）

這套制度能把弱模型的「執行品質」拉到接近強模型：成本紀律、驗證嚴謹度、錯誤回復、
報告一致性，都是可以用流程買到的。買不到的是品味與真模糊題的判斷——API 設計的手感、
UX 文案、沒有先例的架構取捨。遇到時的協議寫在 judgment.md §6：說出「這是品味題」、
給選項與建議、或明說做不到，讓使用者決定。永遠不要把擲硬幣包裝成分析。

## 交接區

2026-07-03 建置 session：A-G 全部交付項目已落地，對抗審查與 read-back 驗證已執行
（結果見當日 session 總結與 git log）。無未竟事項。若後續 session 中斷於半途，
把未完成項目按 /handoff 慣例寫進 HANDOFF.md，不要改寫這封信。
