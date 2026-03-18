---
title: "Claude Code チートシート"
description: "最大限の生産性を発揮するための毎日使える必須事項 — 印刷可能な1枚"
tags: [cheatsheet, reference]
---

# Claude Code チートシート

**印刷可能な1枚** — 最大限の生産性を発揮するための毎日使える必須事項

**著者**: Florian BRUNIAUX | Founding Engineer [@Méthode Aristote](https://methode-aristote.fr)

**制作協力**: Claude (Anthropic)

**バージョン**: 3.37.0 | **最終更新**: 2026年3月

---

## 基本コマンド

| コマンド | 説明 |
|---------|--------|
| `/help` | コンテキストに応じたヘルプ |
| `/clear` | 会話をリセット |
| `/compact` | コンテキストを解放 |
| `/status` | セッション状態 + コンテキスト使用量 |
| `/context` | トークンの詳細な内訳 |
| `/plan` | Plan Modeに入る（変更なし） |
| `/execute` | Plan Modeを終了する（変更を適用） |
| `/model` | モデルを切り替える（sonnet/opus/opusplan） |
| `/insights` | 使用状況の分析 + 最適化レポート |
| `/simplify` | 変更されたコードの過剰設計を検出 + 自動修正 |
| `/batch` | 5〜30個の並列 worktree エージェントによる大規模リファクタリング |
| `/teleport` | ウェブからセッションをテレポート |
| `/tasks` | バックグラウンドタスクの監視 |
| `/remote-env` | クラウド環境の設定 |
| `/remote-control` | リモートコントロールセッションを開始（Research Preview、Pro/Max） |
| `/rc` | /remote-control のエイリアス |
| `/mobile` | Claude モバイルアプリのダウンロードリンクを表示 |
| `/fast` | 高速モードを切り替える（2.5倍の速度、6倍のコスト） |
| `/voice` | 音声入力を切り替える（Space を押しながら話し、離して送信） |
| `/btw [質問]` | サイドクエスチョン オーバーレイ — 読み取り専用の一時エージェント、履歴汚染なし、ツールなし |
| `/loop [間隔] [プロンプト]` | プロンプトを繰り返し実行（例: `/loop 5m check the deploy`、デフォルト10分） |
| `/stats` | 使用グラフ、お気に入りモデル、連続使用日数 |
| `/rename [名前]` | 現在のセッションに名前をつける、または変更する |
| `/copy` | コードブロックまたはレスポンス全体をコピーするインタラクティブピッカー |
| `/debug` | 体系的なトラブルシューティング |
| `/exit` | 終了（または Ctrl+D） |

---

## キーボードショートカット

| ショートカット | 説明 |
|----------|--------|
| `Shift+Tab` | パーミッションモードを切り替える |
| `Esc` × 2 | 巻き戻し（元に戻す） |
| `Ctrl+C` | 中断 |
| `Ctrl+R` | コマンド履歴を検索 |
| `Ctrl+L` | 画面をクリア（コンテキストは維持） |
| `Tab` | オートコンプリート |
| `Shift+Enter` | 改行 |
| `Ctrl+B` | バックグラウンドタスク |
| `Ctrl+F` | 全バックグラウンドエージェントを終了（ダブルプレス） |
| `Alt+T` | Thinking を切り替える |
| `Space` （長押し） | 音声入力（`/voice` 有効時） |
| `Ctrl+D` | 終了 |

---

## ファイル参照

```
@path/to/file.ts    → ファイルを参照
@agent-name         → エージェントを呼び出す
!shell-command      → シェルコマンドを実行
```

| IDE | ショートカット |
|-----|----------|
| VS Code | `Alt+K` |
| JetBrains | `Cmd+Option+K` |

---

## あまり知られていない機能（でも公式！）

| 機能 | 追加バージョン | 内容 |
|---------|-------|--------------|
| **Tasks API** | v2.1.16 | 依存関係を持つ永続タスクリスト |
| **Background Agents** | v2.0.60 | コーディング中もサブエージェントが動作 |
| **Agent Teams** | v2.1.32 | マルチエージェント連携（TeamCreate/SendMessage） |
| **Auto-Memories** | v2.1.32 | セッション横断の自動コンテキストキャプチャ |
| **Session Forking** | v2.1.19 | 巻き戻し + 並行タイムラインの作成 |
| **LSP Tool** | v2.0.74 | IDE的なナビゲーション：シンボル、型、参照。grep比で約50ms vs 45s。11言語対応 |
| **Voice Mode** | v2.1.x | ネイティブ音声入力、無料書き起こし、レート制限への影響なし |
| **Remote Control** | v2.1.51 | スマートフォン/ブラウザからローカルセッションを操作（Research Preview、Pro/Max） |
| **`/loop`** | v2.1.71 | 定期スケジューラ: `/loop 5m check the deploy` — 作業中にバックグラウンドで実行 |
| **Skill Evals** | 2026年3月 | 2種類のスキル: Capability Uplift（モデルのギャップを補完、フェードアウト） / Encoded Preference（ワークフローをエンコード、永続）。ベンチマークモード、A/Bテスト、トリガーチューニング。 |

**LSP を有効にする**: `~/.claude/settings.json` に追加 → `{ "env": { "ENABLE_LSP_TOOL": "1" } }` （使用言語の LSP サーバーが必要: `tsserver`、`pylsp`、`gopls`、`rust-analyzer`、`sourcekit-lsp`など）

**Pro tip**: これらは「秘密」ではありません — すべて [CHANGELOG](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md) に記載されています。読んでみてください！

---

## パーミッションモード

| モード | 編集 | 実行 |
|------|---------|-----------|
| Default | 確認あり | 確認あり |
| acceptEdits | 自動 | 確認あり |
| Plan Mode | ❌ | ❌ |
| dontAsk | 許可ルールにある場合のみ | 許可ルールにある場合のみ |
| bypassPermissions | 自動 | 自動（CI/CDのみ） |

モード切替は **Shift+Tab**

---

## メモリと設定（2つのレベル）

| レベル | macOS/Linux | Windows | スコープ | Git |
|-------|-------------|---------|-------|-----|
| **プロジェクト** | `.claude/` | `.claude\` | チーム | ✅ |
| **個人** | `~/.claude/` | `%USERPROFILE%\.claude\` | 自分（全プロジェクト） | ❌ |

**優先順位**: プロジェクト設定が個人設定より優先される

| ファイル | 場所 | 用途 |
|------|-------|-------|
| `CLAUDE.md` | プロジェクトルート | チームメモリ（指示） |
| `settings.json` | `.claude/` | チーム設定（フック） |
| `settings.local.json` | `.claude/` | 個人設定の上書き |
| `CLAUDE.md` | `~/.claude/` (Win: `%USERPROFILE%\.claude\`) | 個人メモリ |

---

## .claude/ フォルダ構造

```
.claude/
├── CLAUDE.md           # ローカルメモリ（gitignored）
├── settings.json       # フック（コミット済み）
├── settings.local.json # パーミッション（コミットしない）
├── agents/             # カスタムエージェント
├── commands/           # スラッシュコマンド
├── hooks/              # イベントスクリプト
├── rules/              # 自動ロードルール
└── skills/             # ナレッジモジュール
```

---

## 典型的なワークフロー

```
1. セッション開始       → claude
2. コンテキスト確認     → /status
3. Plan Mode          → Shift+Tab × 2（複雑なタスクの場合）
4. タスクを説明         → 明確で具体的なプロンプト
5. 変更をレビュー       → 必ず差分を読む！
6. 承認/却下           → y/n
7. 検証               → テストを実行
8. コミット            → タスク完了時
9. /compact           → コンテキストが >70% になったら
```

---

## コンテキスト管理（重要）

### ステータスライン

```
Model: Sonnet | Ctx: 89.5k | Cost: $2.11 | Ctx(u): 56.0%
```
**`Ctx(u):` に注目:** → >70% = `/compact`、>85% = `/clear`

**拡張ステータスライン ([ccstatusline](https://github.com/sirmalloc/ccstatusline)):** `~/.claude/settings.json` に追加:
```json
{ "statusLine": { "type": "command", "command": "npx -y ccstatusline@latest", "padding": 0 } }
```

### コンテキストしきい値

| コンテキスト % | 状態 | 対応 |
|-----------|--------|--------|
| 0-50% | 緑 | 自由に作業 |
| 50-70% | 黄 | 慎重に選択 |
| 70-90% | オレンジ | 今すぐ `/compact` |
| 90%+ | 赤 | `/clear` が必要 |

### 症状別対応

| 兆候 | 対応 |
|------|--------|
| 短いレスポンス | `/compact` |
| 頻繁な忘却 | `/clear` |
| コンテキスト >70% | `/compact` |
| タスク完了 | `/clear` |

### コンテキスト回復コマンド

| コマンド | 用途 |
|---------|-------|
| `/compact` | 要約してコンテキストを解放 |
| `/clear` | 新鮮なスタート |
| `/rewind` | 最近の変更を元に戻す |
| `claude -c` | 最後のセッションを再開（CLIフラグ） |
| `claude -r <id>` | 特定のセッションを再開（CLIフラグ） |

---

## 内部の仕組み（クイックファクト）

| コンセプト | ポイント |
|---------|-----------|
| **Master Loop** | シンプルな `while(tool_call)` — DAGなし、分類器なし |
| **Tools** | 8つのコア: Bash、Read、Edit、Write、Grep、Glob、Task、TodoWrite |
| **Context** | 約200Kトークン、75-92%で自動圧縮 |
| **Sub-agents** | 独立したコンテキスト、最大深度=1 |
| **Philosophy** | 「Less scaffolding, more model」— Claudeの推論を信頼する |

**詳細**: [アーキテクチャと内部構造](./core/architecture.md)

---

## Plan Mode と Thinking

| 機能 | 起動方法 | 用途 |
|---------|------------|-------|
| **Plan Mode** | `Shift+Tab × 2` または `/plan` | 変更せずに探索 |
| **OpusPlan** | `/model opusplan` | 計画にOpus、実行にSonnet |

> **Opus 4.6** (v2.1.68+): Max/Team のデフォルト effort = **medium**。次のターンで高い effort を強制するには `ultrathink` を使用。"think hard" は見た目のみの変化。

| 制御 | 動作 | 永続性 |
|---------|--------|-------------|
| **Alt+T** | Thinking のオン/オフ切り替え | セッション |
| **/config** | グローバルで有効/無効 | 永続 |
| **`/model` スライダー** | 左/右矢印: `low\|medium\|high` | セッション |
| **`CLAUDE_CODE_EFFORT_LEVEL`** | 環境変数: `low\|medium\|high` | シェルセッション |
| **`effortLevel` 設定** | settings.json内: `low\|medium\|high` | 永続 |

**コストのヒント**: シンプルなタスクは Alt+T で Thinking を無効化 → 速くて安い。

**OpusPlanワークフロー**: `/model opusplan` → `Shift+Tab × 2`（Opusで計画） → `Shift+Tab`（Sonnetで実行）

**必要な場面**: 3ファイル以上の機能、アーキテクチャ、複雑なデバッグ

### クイックモデル選択

| タスク | モデル | Effort |
|------|-------|--------|
| リネーム、ボイラープレート、テスト生成 | Haiku | low |
| 機能開発、デバッグ、リファクタリング | Sonnet | medium–high |
| アーキテクチャ、セキュリティ監査 | Opus | high–max |

> コスト見積もり付きの完全な決定テーブル: [セクション2.5 モデル選択とThinkingガイド](ultimate-guide.md#25-model-selection--thinking-guide)

### 動的モデル切り替え（セッション中）

**パターン**: Sonnetで開始（速度重視） → Opusに切り替え（複雑な問題） → Sonnetに戻る

**ワークフロー**:
```bash
# セッション開始（デフォルトSonnet）
claude

# 複雑な機能に遭遇
> "Implement OAuth2 flow with PKCE"
/model opus                    # 深い推論に切り替え

# 機能完成、ルーティン作業に戻る
/model sonnet                  # 速度とコスト最適化
```

**ベストプラクティス**:
- ✅ **タスクの境界で**切り替える（タスクの途中ではなく）
- ✅ Opusを使う場面: アーキテクチャの決定、複雑なデバッグ、セキュリティクリティカルなコード
- ✅ Sonnetを使う場面: ルーティンな編集、リファクタリング、テスト作成
- ✅ Haikuを使う場面: 簡単な修正、タイポ、バリデーションチェック
- ❌ 実装の途中で切り替えない（コンテキストロス）

**コスト影響**:
| モデル | 入力 | 出力 | ユースケース |
|-------|--------|--------|----------|
| Opus  | $15/MTok | $75/MTok | 複雑な推論（タスクの10-20%） |
| Sonnet | $3/MTok | $15/MTok | ほとんどの開発（タスクの70-80%） |
| Haiku | $0.25/MTok | $1.25/MTok | シンプルなバリデーション（タスクの5-10%） |

**動的切り替え**は、複雑なタスクの品質を維持しながらコストを最適化します。

**参照**: [Gur Sannikov組み込みエンジニアリングワークフロー](https://www.linkedin.com/posts/gursannikov_claudecode-embeddedengineering-aiagents-activity-7423851983331328001-DrFb)

---

## MCPサーバー

| サーバー | 目的 |
|--------|---------|
| **Serena** | インデクシング + セッションメモリ + シンボル検索 |
| **grepai** | セマンティック検索 + コールグラフ分析 |
| **Context7** | ライブラリドキュメント |
| **Sequential** | 構造化された推論 |
| **Playwright** | ブラウザ自動化 |
| **Postgres** | データベースクエリ |
| **doobidoo** | セマンティックメモリ + マルチクライアント + ナレッジグラフ |

**Serena メモリ**: `write_memory()` / `read_memory()` / `list_memories()`

**Serena インデクシング**:
```bash
# 初回インデックス
uvx --from git+https://github.com/oraios/serena serena project index

# 強制再構築
serena project index --force-full

# 差分更新（高速）
serena project index --incremental --parallel 4
```

状態確認: `/mcp`

---

## カスタムコンポーネントの作成

### エージェント (`.claude/agents/my-agent.md`)
```yaml
---
name: my-agent
description: Use when [trigger]
model: sonnet
tools: Read, Write, Edit, Bash
---
# Instructions here
```

### コマンド (`.claude/commands/my-command.md`)
```markdown
# Command Name
Instructions for what to do...
$ARGUMENTS[0] $ARGUMENTS[1] (or $0 $1) - user args
```

### フック (macOS/Linux: `.sh` | Windows: `.ps1`)

**Bash** (macOS/Linux):
```bash
#!/bin/bash
INPUT=$(cat)
# Process JSON input
exit 0  # 0=continue, 2=block
```

**PowerShell** (Windows):
```powershell
$input = [Console]::In.ReadToEnd() | ConvertFrom-Json
# Process JSON input
exit 0  # 0=continue, 2=block
```

---

## アンチパターン

| ❌ やってはいけないこと | ✅ やるべきこと |
|----------|-------|
| 曖昧なプロンプト | @参照でファイル + 行を指定する |
| 読まずに承認する | 全ての差分を読む |
| 警告を無視する | 70%で `/compact` を使う |
| パーミッションをスキップする | 本番環境では絶対にしない |
| 否定的な制約のみ | 代替案を提示する |

---

## クイックプロンプトの公式

```
WHAT: [具体的な成果物]
WHERE: [ファイルパス]
HOW: [制約、アプローチ]
VERIFY: [成功基準]
```

**例:**
```
Add input validation to the login form.
WHERE: src/components/LoginForm.tsx
HOW: Use Zod schema, show inline errors
VERIFY: Empty email shows error, invalid format shows error
```

---

## CLIフラグ クイックリファレンス

| フラグ | 用途 |
|------|-------|
| `-p "query"` | 非インタラクティブモード（CI/CD） |
| `-c` / `--continue` | 最後のセッションを継続 |
| `-r` / `--resume <id>` | 特定のセッションを再開 |
| `--teleport` | ウェブからセッションをテレポート |
| `remote-control` | サブコマンド: リモートコントロールセッションを開始 |
| `--model sonnet` | モデルを変更 |
| `--add-dir ../lib` | CWD外へのアクセスを許可 |
| `--permission-mode plan` | Plan mode |
| `--tools "Tool1,Tool2"` | セッション向けに特定ツールを有効化 |
| `--max-budget-usd 5.00` | API支出の上限（printモード） |
| `--system-prompt "..."` | カスタムシステムプロンプトを追加 |
| `--worktree` / `-w` | 独立した git worktree で実行 |
| `--dangerously-skip-permissions` | 自動承認（慎重に使用） |
| `--debug` | デバッグ出力 |
| `--allowedTools "Edit,Read"` | ツールのホワイトリスト |

> 完全なCLIリファレンス（約45フラグ）: [code.claude.comのcli-reference](https://docs.anthropic.com/en/docs/claude-code/cli-reference) を参照

---

## デバッグコマンド

```bash
claude --version     # バージョン確認
claude update        # アップデートの確認/インストール
claude doctor        # 診断
claude --debug       # 詳細モード
claude --mcp-debug   # MCPのデバッグ
/mcp                 # MCPの状態（Claude内から）
```

---

## CI/CDモード（ヘッドレス）

```bash
# 非インタラクティブ実行
claude -p "analyze this file" src/api.ts

# JSON出力
claude -p "review" --output-format json

# 経済的なモデル
claude -p "lint" --model haiku

# 自動承認あり
claude -p "fix typos" --dangerously-skip-permissions
```

---

## リモートコントロール — モバイルアクセス（v2.1.51+、Research Preview）

> **Pro/Max のみ** — Team、Enterprise、APIキーでは利用不可

```bash
# ターミナルから起動（新しいセッション）
claude remote-control

# またはアクティブなセッション内から:
/rc        # (or /remote-control)
```

**スマートフォン/タブレット/ブラウザから接続:**
1. **QRコード**をスキャン（起動後にスペースバーを押す）
2. または**セッションURL**をブラウザ / Claude モバイルアプリで開く
3. または: `/mobile` → App Store + Play Store のリンクを表示

| ⚠️ 既知の制限 | 詳細 |
|--------------------|--------|
| 同時に1セッションのみ | アクティブなリモートセッションは1つだけ |
| スラッシュコマンドが壊れる | `/new`、`/compact` = リモートではプレーンテキスト → ローカルターミナルから使用 |
| ターミナルを開いたままにする | ローカルターミナルを閉じるとセッション終了 |
| ネットワークタイムアウト | 約10分で切断 → セッション期限切れ |

**上級者向け: tmux マルチセッション**（1セッション制限を回避）
```bash
tmux new-session -s dev
# 各ペイン = 独自のclaudeセッション
# リモートコントロールしたいペインで /rc を実行
```

**自動有効化:** `/config` → "Remote Control: auto-enable" を切り替える

**完全なドキュメント**: [§9.22 リモートコントロール](ultimate-guide.md#922-remote-control-mobile-access) | [セキュリティノート](security-hardening.md#remote-control-security)

---

## タスク管理（v2.1.16+）

**2つのシステムが利用可能:**

| システム | 使用場面 | 永続性 |
|--------|-------------|-------------|
| **Tasks API** (v2.1.16+) | マルチセッションプロジェクト、依存関係 | ✅ ディスク (`~/.claude/tasks/`) |
| **TodoWrite** (レガシー) | シンプルな単一セッション | ❌ セッションのみ |

### Tasks API コマンド

```bash
# セッション間の永続性を有効にする
export CLAUDE_CODE_TASK_LIST_ID="project-name"
claude

# Claude内: タスク階層の作成
> "Create tasks for auth system with dependencies"

# 後で再開（新しいセッション）
export CLAUDE_CODE_TASK_LIST_ID="project-name"
claude
> "TaskList to see current state"
```

**主な機能:**
- 📁 **永続**: セッション終了、コンテキスト圧縮後も保持
- 🔗 **依存関係**: タスクAがタスクBをブロック
- 🔄 **マルチセッション**: 複数のターミナルに状態をブロードキャスト
- 📊 **ステータス**: pending → in_progress → completed/failed

**⚠️ 制限**: TaskList は `id`、`subject`、`status`、`blockedBy` のみを表示。
`description`/`metadata` を取得するには → タスクごとに `TaskGet(taskId)` を使用。

**ヒント**: クイックスキャンのために重要な情報を `subject` フィールドに格納する。

**移行フラグ** (v2.1.19+):
```bash
# 旧 TodoWrite システムに戻す
CLAUDE_CODE_ENABLE_TASKS=false claude
```

**→ 完全なワークフロー**: [guide/workflows/task-management.md](../workflows/task-management.md)

---

## ゴールデンルール

1. **常に差分をレビューする** — 承認する前に
2. **`/compact` を使う** — コンテキストが危機的になる前に（>70%）
3. **具体的に伝える** — リクエストで（WHAT、WHERE、HOW、VERIFY）
4. **まずPlan Mode** — 複雑なタスクや危険なタスクには
5. **CLAUDE.md を作成する** — 全てのプロジェクトに
6. **頻繁にコミットする** — 各タスク完了後
7. **何が送信されるかを知る** — プロンプト、ファイル、MCPの結果 → Anthropic（[学習のオプトアウト](https://claude.ai/settings/data-privacy-controls)）

---

## クイック決定ツリー

```
シンプルなタスク       → そのままClaudeに聞く
複雑なタスク           → まずTasks APIで計画
危険な変更             → まずPlan Mode
繰り返しタスク         → エージェントまたはコマンドを作成
コンテキストが満杯     → /compact または /clear
ドキュメントが必要     → Context7 MCPを使う
深い分析               → Opus（デフォルトでthinkingオン）
```

---

## よくある問題のクイック修正

| 問題 | 解決策 |
|---------|----------|
| "Command not found" | PATHを確認、再インストール: `curl -fsSL https://claude.ai/install.sh \| sh` |
| コンテキストが高い（>70%） | 今すぐ `/compact` |
| 遅いレスポンス | `/compact` または `/clear` |
| MCPが動かない | `claude mcp list` で確認、設定を見直す |
| Permission denied | `settings.local.json` を確認 |
| フックがブロック | フックの終了コードを確認、ロジックをレビュー |

**ヘルスチェックスクリプト** （保存して実行）:
```bash
# macOS/Linux
which claude && claude doctor && claude mcp list

# Windows PowerShell
where.exe claude; claude doctor; claude mcp list
```

---

## コスト最適化

| モデル | 用途 | コスト |
|-------|---------|------|
| Haiku | 簡単な修正、レビュー | $ |
| Sonnet | ほとんどの開発 | $$ |
| Opus | アーキテクチャ、複雑なバグ | $$$ |
| OpusPlan | 計画（Opus）+ 実行（Sonnet） | $$ |

**ヒント**: `--add-dir` を使って現在の作業ディレクトリ外のディレクトリへのツールアクセスを許可する

---

## コミュニティツール

| ツール | 目的 | インストール |
|------|---------|---------|
| **ccusage** | コスト追跡とレポート | `bunx ccusage daily` |
| **RTK** | トークン削減（60-90%） | `brew install rtk-ai/tap/rtk` または `cargo install rtk` · [サイト](https://www.rtk-ai.app/) |
| **claude-code-viewer** | セッション履歴UI | `npx @kimuson/claude-code-viewer` |
| **Entire CLI** | セッションチェックポイント + ガバナンス | [entire.io](https://entire.io)（2026年2月） |

> **Entire CLI**: 元GitHub CEOによるエージェントネイティブプラットフォーム。巻き戻し可能なチェックポイント、承認ゲート、監査証跡を備える。コンプライアンス（SOC2、HIPAA）やマルチエージェントワークフロー向け。

---

## 検索ツール クイックリファレンス

クイック決断（5秒）: 正確なテキスト → `rg` | 正確な名前 → `rg`/Serena | コンセプト → grepai | 構造 → ast-grep

| タスク | ツール | コマンド |
|------|------|---------|
| "TODOコメントを探す" | `rg` | `rg "TODO"` |
| "認証コードを探す" | `grepai` | `grepai search "authentication"` |
| "loginを呼び出しているのは誰？" | `grepai` | `grepai trace callers "login"` |
| "ファイル構造を取得" | `Serena` | `serena get_symbols_overview` |
| "try/catchなしのasync" | `ast-grep` | `ast-grep "async function $F"` |

速度: `rg` (~20ms) → Serena (~100ms) → ast-grep (~200ms) → grepai (~500ms)

> 完全なワークフロー: [workflows/search-tools-mastery.md](./workflows/search-tools-mastery.md)

---

## リソース

- **公式ドキュメント**: [docs.anthropic.com/claude-code](https://docs.anthropic.com/en/docs/claude-code)
- **上級者向けガイド**: [Claudelog.com](https://claudelog.com/) — ヒントとパターン
- **完全ガイド**: `ultimate-guide.md`（このリポジトリ）
- **ホワイトペーパー（FR + EN）**: [florian.bruniaux.com/guides](https://www.florian.bruniaux.com/guides) — 9つのフォーカスPDF
- **プロジェクトメモリ**: プロジェクトルートに `CLAUDE.md` を作成
- **DeepSeek（コスト効果的）**: `ANTHROPIC_BASE_URL` 経由で設定

---

**著者**: Florian BRUNIAUX | [@Méthode Aristote](https://methode-aristote.fr) | Written with Claude

*最終更新: 2026年3月 | バージョン 3.37.0*
