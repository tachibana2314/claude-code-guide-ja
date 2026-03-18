---
layout: default
title: "サードパーティツール"
parent: エコシステム
grand_parent: ガイド
nav_order: 3
---


# Claude Code のサードパーティツール

> トークン追跡、セッション管理、設定、フックユーティリティ、代替 UI のコミュニティツール。
>
> **最終確認**: 2026年3月

## 目次

1. [このページについて](#このページについて)
2. [トークン & コスト追跡](#トークン--コスト追跡)
3. [セッション管理](#セッション管理)
4. [設定管理](#設定管理)
5. [エンジニアリング標準の配布](#エンジニアリング標準の配布)
6. [フックユーティリティ](#フックユーティリティ)
7. [代替 UI](#代替-ui)
8. [マルチエージェントオーケストレーション](#マルチエージェントオーケストレーション)
9. [プラグインエコシステム](#プラグインエコシステム)
10. [既知のギャップ](#既知のギャップ)
11. [ペルソナ別推奨事項](#ペルソナ別推奨事項)


## このページについて

このページでは **Claude Code を拡張するコミュニティ製ツール**をカタログ化しています。各ツールはその公開リポジトリまたはパッケージレジストリに対して検証済みです。公開ソース（GitHub、npm、PyPI）を持つツールのみを掲載しています。

**このページに含まれないもの**:
- Claude Code を補完する AI ツールのリスト（[AI エコシステム](./ai-ecosystem.md)を参照）
- DIY 監視スクリプト（[可観測性](../ops/observability.md)を参照）
- MCP サーバーの推奨（[MCP サーバーエコシステム](./mcp-servers-ecosystem.md)を参照）


## トークン & コスト追跡

### ccusage

Claude Code 向けの最も成熟したコスト追跡ツール。ローカルセッションデータを解析し、日次・月次・セッション・5時間課金ウィンドウごとにコストレポートを生成します。

| 属性 | 詳細 |
|-----------|---------|
| **ソース** | [npm: ccusage](https://www.npmjs.com/package/ccusage) / [ccusage.com](https://ccusage.com) |
| **インストール** | `bunx ccusage`（最速）または `npx ccusage` |
| **言語** | TypeScript（Node.js 18+） |
| **バージョン** | 18.x（積極的にメンテナンス中） |

**主要機能**:

- `ccusage daily` / `ccusage monthly` / `ccusage session` — 集計コストレポート
- `ccusage blocks --live` — 5時間課金ウィンドウに対するリアルタイム監視
- `--breakdown` フラグによるモデル別コスト分割（Opus/Sonnet/Haiku）
- `--since` / `--until` による日付フィルタリング
- プログラムアクセス用 JSON 出力（`--json`）
- キャッシュ済み価格データによるオフラインモード
- MCP サーバー統合（`@ccusage/mcp`）
- macOS ウィジェット（`ccusage-widget`）と [Raycast 拡張](https://www.raycast.com/nyatinte/ccusage)

**制限**: ローカル JSONL パースに依存。コスト見積もりは Anthropic の公式請求と異なる場合があります。手動ログマージなしではチーム集計ができません。

> **相互参照**: メインガイドでは [ultimate-guide.md セクション 2.4](./ultimate-guide.md)（コスト監視）で基本的な ccusage コマンドを扱っています。
> フックを使った DIY コスト追跡については、[可観測性](../ops/observability.md)を参照。


### ccburn

視覚的なトークンバーンレート追跡のための Python TUI。Claude の課金ウィンドウに対する消費レートを示すグラフを表示します。

| 属性 | 詳細 |
|-----------|---------|
| **ソース** | [GitHub: JuanjoFuchs/ccburn](https://github.com/JuanjoFuchs/ccburn) / [ブログ記事](https://juanjofuchs.github.io/ai-development/2026/01/13/introducing-ccburn-visual-token-tracking.html) |
| **インストール** | `pip install ccburn` |
| **言語** | Python 3.10+（Rich + Plotext） |

**主要機能**:

- 時系列でのトークン消費を示すターミナルグラフ
- バーンレート指標（順調 / 減速警告）
- コンパクト表示モード
- 上限に対する視覚的な予算追跡

**制限**: Python 専用エコシステム。ccusage よりコミュニティが小さい。MCP 統合なし。

**ccusage より ccburn を選ぶとき**: 表形式レポートより視覚的なバーンレートグラフを好む場合、またはツールチェーンが Python ベースの場合。


### Straude

Claude Code（と OpenAI Codex）の使用統計を追跡・共有するソーシャルダッシュボード。日次トークン消費とコストを公開リーダーボードにプッシュして、ストリーク、週間支出、グローバルランキングを追跡します。

| 属性 | 詳細 |
|-----------|---------|
| **ソース** | [npm: straude](https://www.npmjs.com/package/straude) |
| **ウェブサイト** | [straude.com](https://straude.com) |
| **インストール** | `npx straude@latest` |
| **言語** | TypeScript（Node.js 18+） |
| **バージョン** | 0.1.9（2026年2月作成、活発に開発中） |
| **メンテナー** | コミュニティ（oscar.hong2015@gmail.com） |

**主要機能**:

- `straude` — スマート同期：1コマンドで認証 + 使用状況をプッシュ
- `straude push --dry-run` — 送信前に送信内容をプレビュー
- `straude push --days N` — 直近 N 日間をバックフィル（最大7日）
- `straude status` — ストリーク、週間支出、トークン合計、グローバルランキング
- Claude Code（`ccusage`）と OpenAI Codex（`@ccusage/codex`）の両方を追跡

**Straude サーバーに送信されるもの**:

日次：USD コスト、トークン数（入力/出力/キャッシュ作成/キャッシュ読み取り）、使用モデル名（例: `claude-sonnet-4-6`）、モデル別コスト内訳。さらに：生データの SHA256 ハッシュ、ランダムなデバイス UUID、マシンホスト名。

ソースコード、API キー、会話内容は**アクセスも送信もされません**。

**セキュリティ注意事項**:

- 認証トークンは `~/.straude/config.json` に `0600` 権限（所有者のみ）で保存
- プロジェクトは非常に新しい（2026-02-18 作成、急速なイテレーション）— 公開セキュリティ監査なし
- マシンホスト名が `device_name` として送信される
- 2026年3月時点でプライバシーポリシーなし
- 初回プッシュ前に `--dry-run` を使って送信内容を確認

**ccusage/ccburn より Straude を選ぶとき**:

Straude はこのリストの中で唯一**ソーシャル**なツールです — 統計を共有プラットフォームにアップロードします。リーダーボード、ストリーク追跡、または他の開発者との使用量のベンチマークを望む場合、Straude はユニークです。ローカルのみのコスト可視性が欲しい場合、ccusage または ccburn の方が適していて、データ共有の意味合いもありません。

> **セキュリティリマインダー**: `npx` でコミュニティ CLI ツールを実行する前に、その npm ページとソースのレッドフラグを確認してください。Straude については、コンパイル済みソースが読み取り可能で、述べられた目的と一致しています。完全な分析は [リソース評価](../docs/resource-evaluations/straude-evaluation.md) を参照してください。


### RTK（Rust Token Killer）

コマンド出力が Claude のコンテキストに届く**前に**フィルタリングする CLI プロキシ。GitHub 446スター、38フォーク、r/ClaudeAI で 700+ アップボート。

| 属性 | 詳細 |
|-----------|---------|
| **ソース** | [GitHub: rtk-ai/rtk](https://github.com/rtk-ai/rtk) |
| **ウェブサイト** | [rtk-ai.app](https://www.rtk-ai.app/) |
| **インストール** | `brew install rtk-ai/tap/rtk` または `cargo install rtk` |
| **言語** | Rust（スタンドアロンバイナリ） |
| **バージョン** | v0.28.0 |

**主要機能**:

- `rtk git log`（92%削減）、`rtk git status`（76%削減）、`rtk git diff`（56%削減）
- `rtk vitest run`、`rtk prisma`、`rtk pnpm`（70〜90%削減）
- `rtk python pytest`、`rtk mypy`、`rtk go test`（マルチ言語サポート）
- `rtk cargo test/build/clippy/nextest`（Rust ツールチェーン）
- `rtk aws`、`rtk psql`、`rtk docker compose`、`rtk gt`（Graphite CLI）
- `rtk wc` — コンパクトな単語/行/バイト数
- `rtk init --global` — フックファースト インストールと settings.json 自動パッチ
- `rtk gain` / `rtk gain -p` — トークン節約分析（グローバル + プロジェクト別）
- **TOML フィルタ DSL**：Rust を書かずに任意のコマンドのカスタム出力フィルタを追加 — `.rtk/filters.toml`（プロジェクト）または `~/.config/rtk/filters.toml`（グローバル）、33+ 組み込みフィルタ
- `rtk rewrite` — フックコマンドマッピングの唯一の真実の情報源（v0.25.0+、アップグレード後に `rtk init --global` が必要）
- 特定のコマンドを自動書き換えから除外する `exclude_commands` 設定

**RTK vs ccusage/ccburn を選ぶとき**:

- RTK はトークン消費を**削減**する（前処理）
- ccusage/ccburn はそれを**監視**する（後処理）
- 最大効率のために両方を組み合わせて使う

**制限**: インタラクティブコマンドや非常に小さい出力（100文字未満）には適していません。

> **相互参照**: 完全なドキュメントは [ultimate-guide.md セクション9](./ultimate-guide.md#command-output-optimization-with-rtk)


## セッション管理

### claude-code-viewer

Claude Code の会話履歴（JSONL ファイル）をブラウズ・閲覧するウェブベース UI。

| 属性 | 詳細 |
|-----------|---------|
| **ソース** | [GitHub: d-kimuson/claude-code-viewer](https://github.com/d-kimuson/claude-code-viewer) / [npm: @kimuson/claude-code-viewer](https://www.npmjs.com/package/@kimuson/claude-code-viewer) |
| **インストール** | `npx @kimuson/claude-code-viewer` または `npm install -g @kimuson/claude-code-viewer` |
| **言語** | TypeScript（Node.js 18+） |
| **バージョン** | 0.5.x |

**主要機能**:

- セッション数とメタデータを持つプロジェクトブラウザ
- シンタックスハイライト付きの完全な会話表示
- インラインのツール使用結果
- Server-Sent Events によるリアルタイム更新（ファイル変更時に自動更新）
- レスポンシブデザイン（デスクトップ + モバイル）

**制限**: 読み取り専用（セッションの編集や再開不可）。コストデータなし。既存の `~/.claude/projects/` 履歴が必要。

> **相互参照**: CLI からのセッション検索については、[可観測性](../ops/observability.md)の [session-search.sh](../examples/scripts/session-search.sh) を参照。


### Entire CLI

Git 統合セッションキャプチャと巻き戻し可能なチェックポイント、ガバナンスレイヤーを持つエージェントネイティブプラットフォーム。

| 属性 | 詳細 |
|-----------|---------|
| **ソース** | [GitHub: entireio/cli](https://github.com/entireio/cli) / [entire.io](https://entire.io) |
| **インストール** | GitHub を参照（2026年2月ローンチ、アーリーアクセス） |
| **言語** | TypeScript |
| **設立** | Thomas Dohmke（元 GitHub CEO）による 2026年2月、6000万ドル資金調達 |

**主要機能:**

- **セッションキャプチャ**: AI エージェントセッション（Claude Code、Gemini CLI）の完全コンテキスト付き自動記録
- **巻き戻し可能なチェックポイント**: プロンプト + 推論 + ファイル変更を含む任意のセッション状態に復元
- **ガバナンスレイヤー**: コンプライアンス用の権限システム、人間承認ゲート、監査証跡
- **エージェントハンドオフ**: エージェント切り替え時のコンテキスト保持（Claude → Gemini）
- **Git 統合**: 別の `entire/checkpoints/v1` ブランチにチェックポイントを保存（履歴汚染なし）
- **マルチエージェントサポート**: コンテキスト共有で複数の AI エージェントを同時に使用

**ユースケース:**

| シナリオ | Entire CLI の理由 |
|----------|---------------|
| **コンプライアンス（SOC2、HIPAA）** | 完全な監査証跡：プロンプト → 推論 → 出力 |
| **マルチエージェントワークフロー** | エージェント切り替え時のコンテキスト保持 |
| **AI 意思決定のデバッグ** | チェックポイントに巻き戻して推論を検査 |
| **ガバナンス** | 本番変更前の承認ゲート |
| **チームハンドオフ** | 完全コンテキスト付きでセッションを再開 |

**claude-code-viewer との比較:**

| 機能 | claude-code-viewer | Entire CLI |
|---------|-------------------|-----------|
| **目的** | 読み取り専用の履歴表示 | アクティブなセッション管理 + リプレイ |
| **リプレイ** | なし | あり（チェックポイントへの巻き戻し） |
| **コンテキスト** | 会話のみ | プロンプト + 推論 + ファイル状態 |
| **ガバナンス** | なし | あり（承認ゲート、権限） |
| **マルチエージェント** | なし | あり（エージェントハンドオフ） |
| **オーバーヘッド** | なし | ストレージ約5〜10% |

**claude-code-viewer より Entire を選ぶとき:**

- ✅ セッションリプレイ/巻き戻し機能が必要
- ✅ エンタープライズコンプライアンス要件（監査証跡）
- ✅ マルチエージェントワークフロー（Claude + Gemini）
- ✅ ガバナンスゲート（デプロイ前の承認）
- ❌ 履歴をブラウズするだけ → claude-code-viewer を使用（より軽量）

**制限:**

- 非常に新しい（2026年2月10〜12日ローンチ）— 本番フィードバック限定
- エンタープライズ向け（ソロ開発者には複雑かも）
- ストレージオーバーヘッド（セッションデータでプロジェクトサイズの約5〜10%）
- macOS/Linux のみ（Windows は WSL 経由）
- 初期ステージ（v1.x）— API 変更を想定

**既存のセットアップとの差:**

| ニーズ | 典型的な既存セットアップ | Entire が追加するもの |
|------|----------------------|-----------------|
| ツール呼び出しロギング | ローカル JSONL（7日ローテーション） | 推論 + 帰属%、Git 永続 |
| 人間/AI 帰属 | なし | ファイルごとの%、行ごとの注釈、モデル別 |
| エージェントハンドオフ | 手動コンテキストコピー | 次のエージェントに自動渡されるコンテキストチェックポイント |
| 開発者間ハンドオフ | Git コミット/PR | `entire/checkpoints/v1` 上の共有読み取り可能チェックポイント |
| セッション永続性 | ローカルのみ、一時的 | Git ネイティブ、永続、共有可能 |
| ガバナンス | カスタム pre-commit フック | ポリシーベースの承認ゲート + 設定可能な監査エクスポート |

**評価（チームロールアウト前に2時間のスパイク推奨）:**

```bash
entire enable  # 使い捨てブランチにインストール

# 2〜3回の通常セッション後:
du -sh .git/refs/heads/entire/   # セッションあたりのストレージ → 10MB超でフラグ
time git push                     # プッシュオーバーヘッド → 5秒超でフラグ
ls .git/hooks/                    # 既存フックとの競合がないか確認
```

停止基準：チェックポイント > セッションあたり10MB、プッシュオーバーヘッド > 5秒、またはフック競合。

> **相互参照**: 例を含む完全な Entire ワークフローは [AI トレーサビリティガイド](../ops/ai-traceability.md#51-entire-cli)。コンプライアンスユースケースは [セキュリティ強化](../security/security-hardening.md)を参照。


## 設定管理

### claude-code-config

`~/.claude.json` 設定管理、特に MCP サーバー管理に特化した TUI。

| 属性 | 詳細 |
|-----------|---------|
| **ソース** | [GitHub: joeyism/claude-code-config](https://github.com/joeyism/claude-code-config) |
| **インストール** | `pip install claude-code-config` |
| **言語** | Python（Textual TUI） |

**主要機能**:

- 視覚的な MCP サーバー管理（追加、編集、削除）
- バリデーション付きの設定ファイル編集
- `~/.claude.json` 構造のための TUI ナビゲーション

**制限**: `~/.claude.json` スコープに限定。`.claude/settings.json`、フック、スラッシュコマンドは管理できません。


### AIBlueprint

フック、コマンド、ステータスライン、ワークフロー自動化を含む事前設定済み Claude Code セットアップをスキャフォールドする CLI。

| 属性 | 詳細 |
|-----------|---------|
| **ソース** | [GitHub: Melvynx/aiblueprint](https://github.com/Melvynx/aiblueprint) |
| **インストール** | `npx aiblueprint-cli` |
| **言語** | TypeScript |

**主要機能**:

- 事前構築されたセキュリティフック
- カスタムコマンドテンプレート
- ステータスライン設定
- ワークフロー自動化プリセット

**制限**: 独断的な設定選択。一部の機能はプレミアムティアが必要。既存設定は読み込まない（最初からスキャフォールド）。

> **相互参照**: Claude Code の手動設定については、[ultimate-guide.md セクション4](./ultimate-guide.md)（CLAUDE.md、設定、フック、コマンド）を参照。


## エンジニアリング標準の配布

エンジニアリング標準を数十のリポジトリと複数の AI コーディングエージェント間で同期させるという組織規模の問題を解決するツール。

> **コンテキスト**: このガイドではプロジェクトレベルでの CLAUDE.md の作成を扱っています（Ultimate Guide のセクション3）。以下のツールは次のレベル — エンジニアリング組織全体でのこれらの標準の配布とメンテナンス — に対応しています。

### Packmind

エンジニアリングコンテキストをライフサイクルを持つ管理されたアーティファクトとして扱うオープンソースの「ContextOps」プラットフォーム（Packmind の用語）。標準を一度キャプチャし、チームが使用するすべての AI コーディングエージェントに AI 読み取り可能なコンテキストとして配布します。

| 属性 | 詳細 |
|-----------|---------|
| **ソース** | [GitHub: PackmindHub/packmind](https://github.com/PackmindHub/packmind) |
| **インストール** | `npx @packmind/cli init` |
| **ライセンス** | Apache-2.0（CLI）— packmind.com の SaaS レイヤー（価格未定） |
| **セルフホスト** | Docker / Kubernetes |
| **言語** | TypeScript |

**主要機能**:

- 1つのプレイブック → Claude Code 用の `CLAUDE.md` + スラッシュコマンド + スキル、Cursor 用の `.cursor/rules/*.mdc`、Copilot 用の `.github/copilot-instructions.md`、汎用エージェント用の `AGENTS.md` を生成
- MCP サーバー：Claude Code セッション内から直接標準を作成・管理
- 継続学習ループ（主張）：バグ修正 → Skill+MCP 経由で根本原因をキャプチャ → プレイブック更新を提案 → 人間が検証 → リポジトリ全体に配布
- MCP サーバー経由でチームツールからの知識取り込み：GitHub PR コメント、Slack、Jira、GitLab MR、Confluence、Notion（[デモユースケース](https://github.com/PackmindHub/demo-use-case-skills)）

**メンタルモデル**: Packmind は `.claude/rules/` モジュールパターンの組織レベル版として考えてください。`.claude/rules/*.md` が単一プロジェクトを一貫させるように、Packmind は40のリポジトリを一貫させます — そして Claude Code だけでなく、チームが使用するすべての AI ツールに同期します。

**セキュリティ注記**: CLAUDE.md の配布を集中管理することは、Packmind リポジトリが侵害されると、すべての開発者の AI セッションに悪意のある指示を同時に伝播できることを意味します。Packmind 設定を機密アーティファクトとして扱い、シークレットマネージャーと同様のアクセス制御を適用し、マージ前にプレイブックの更新提案を慎重にレビューしてください。

> **相互参照**: プロジェクト規模での CLAUDE.md 作成については、[セクション 3.5 — チーム設定のスケール](../ultimate-guide.md#35-team-configuration-at-scale)を参照。Packmind MCP サーバーについては、[mcp-servers-ecosystem.md — オーケストレーション](./mcp-servers-ecosystem.md#orchestration)を参照。


## フックユーティリティ

追加ロジック、条件実行、自動化パターンで Claude Code のフックシステムを拡張するツール。DIY フックの例については、[Ultimate Guide のフックセクション](../ultimate-guide.md)を参照してください。

### gitdiff-watcher

Claude が制御を返す前に品質ゲートを強制する Stop フックユーティリティ。関連ファイルが変更された場合にのみシェルコマンド（ビルド、テスト、リンティング）を実行し、CLAUDE.md の品質ルールを決定論的にします。

| 属性 | 詳細 |
|-----------|---------|
| **ソース** | [GitHub: fcamblor/gitdiff-watcher](https://github.com/fcamblor/gitdiff-watcher) |
| **インストール** | `npx @fcamblor/gitdiff-watcher@0.1.0`（グローバルインストール不要） |
| **言語** | Node.js |
| **バージョン** | 0.1.0 — 開発中、API が変更される可能性あり |
| **作者** | Florian Camblor |

**解決する問題**: 「ハンドオフ前にテストを通す」などの CLAUDE.md ルールは非決定論的です。コンテキストが増えるにつれ、これらのルールは最近のツール出力とモデルの注意を競い合い、後回しにされる場合があります — そのため Claude はルールが明示されていても壊れたコードで制御を返すことがあります。Stop フックは LLM コンテキストの外で実行されるため、構造的にスキップが不可能になります。

**動作原理**:

1. グロブパターン（`--on`）と1つ以上のシェルコマンド（`--exec`）を受け取る
2. 各 Stop イベントで、`git diff`（ステージ済み + 未ステージ）に現れるグロブに一致するすべてのファイルの SHA-256 ハッシュを計算
3. `.claude/gitdiff-watcher.state.local.json` に保存された前のスナップショットと比較
4. 関連する変更がない場合：サイレントに exit 0（コマンドを実行しない）
5. 変更が検出された場合：すべての `--exec` コマンドを実行
6. いずれかのコマンドが失敗した場合（exit code 2）：Claude が stderr を受け取り再試行 — スナップショットは**更新されない**ため、次のターンでも確認が実行される
7. 完全な成功時：スナップショットを更新

**設定例**（`.claude/settings.json`）:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "npx @fcamblor/gitdiff-watcher@0.1.0 --on 'src/**/*.{ts,tsx}' --exec 'npm run build'",
            "timeout": 300,
            "statusMessage": "TypeScript ビルドを確認中..."
          },
          {
            "type": "command",
            "command": "npx @fcamblor/gitdiff-watcher@0.1.0 --on 'src/**/*.{ts,tsx}' --exec 'npm test -- --passWithNoTests'",
            "timeout": 300,
            "statusMessage": "テストを確認中..."
          }
        ]
      }
    ]
  }
}
```

複数のフックは並列実行されます（Claude Code はフックエントリごとに1つのサブエージェントを生成）。

**主な動作**:

- **条件付き**: 一致するファイルが変更された場合にのみ起動 — 無関係な編集での無駄な CI 時間なし
- **リトライセーフ**: 失敗した実行はスナップショットを保持するため、同じチェックが次の試行で実行される
- **並列**: 1つのフックエントリ内の複数の `--exec` コマンドは順次実行。並列実行には別々のフックエントリを使用
- **ノーオペ時はサイレント**: 関連する変更が検出されない場合、出力なしで exit 0

**制限**:

- v0.1.0 — 明示的に「開発中」、CLI オプションと状態ファイル形式が変わる可能性あり
- ファイル検出には `git diff（ステージ済み + 未ステージ）` を使用 — git で追跡されていないファイルはウォッチャーから見えない
- リトライループ：常に失敗する誤って設定されたチェックは Claude が無限にリトライ。`--exec-timeout` を追加し、コマンドが正しい終了コードを持つことを確認
- 各 Stop フックの失敗は新しい Claude ターンを開始し、コンテキストを消費 — 200K 制限付近では繰り返しの失敗がコンテキスト消費を加速

**gitdiff-watcher vs ネイティブ Stop フックを選ぶとき**:

同じ品質ゲートは gitdiff-watcher なしで約20行の bash で書けます。gitdiff-watcher を使うのは、ファイル変更の条件ロジックと状態永続性を自分で書かずに済みたい場合、またはポリグロットコードベースで並列チェックが必要な場合（例：TypeScript ビルド + Kotlin テストを同時に）。

> **相互参照**: Stop フックのメカニクスは [ultimate-guide.md フックセクション](../ultimate-guide.md)を参照。PostToolUse ビルドチェック（ハンドオフ時ではなくファイル編集のたびに起動）については、フックセクションの例（約8262行目）を参照。


## 代替 UI

### Claude Chic

Anthropic の claude-agent-sdk 上に構築された Claude Code のスタイリングされたターミナル UI。デフォルトの Claude Code TUI を視覚的に強化されたものに置き換えます。

| 属性 | 詳細 |
|-----------|---------|
| **ソース** | [ブログ: matthewrocklin.com](https://matthewrocklin.com/introducing-claude-chic/) / [PyPI: claudechic](https://pypi.org/project/claudechic/) |
| **インストール** | `uvx claudechic` |
| **言語** | Python（Textual + claude-agent-sdk） |
| **ステータス** | アルファ |

**主要機能**:

- カラーコードされたメッセージ（オレンジ：ユーザー、青：Claude、グレー：ツール）
- 折りたたみ可能なツール使用ブロック
- UI 内からの Git ワークツリー管理
- 1つのウィンドウで複数エージェント
- `/diff` ビューア、vim キーバインド（`/vim`）、シェルコマンド（`!ls`）
- ストリーミング付きの適切な Markdown レンダリング

**制限**: アルファステータス — 破壊的変更を想定。Python 依存チェーン。claude-agent-sdk が必要。macOS/Linux のみ。


### Toad

AI コーディングエージェント向けのユニバーサルターミナルフロントエンド。Agent Client Protocol（ACP）経由で Claude Code に加えて Gemini CLI、OpenHands、Codex、その他12以上のエージェントをサポート。

| 属性 | 詳細 |
|-----------|---------|
| **ソース** | [GitHub: batrachianai/toad](https://github.com/batrachianai/toad) / [willmcgugan.github.io/toad-released](https://willmcgugan.github.io/toad-released/) |
| **インストール** | `curl -fsSL batrachian.ai/install \| sh` または `uv tool install -U batrachian-toad --python 3.14` |
| **作者** | Will McGugan（Rich & Textual の作者） |
| **言語** | Python（Textual） |

**主要機能**:

- 12以上のエージェント CLI にわたる統合インターフェース
- タブ補完付きのフルシェル統合
- ファジー検索付きの `@` ファイルコンテキスト注入
- シンタックスハイライト付きのサイドバイサイド差分
- Jupyter インスパイアのブロックナビゲーション
- フリッカーのない文字レベルレンダリング

**制限**: macOS/Linux のみ（Windows は WSL 経由）。エージェントサポートは ACP 互換性によって異なる。組み込みのセッション永続性はまだない（ロードマップに追加済み）。


### Conductor

git ワークツリーを使って複数の Claude Code（および Codex）インスタンスを並列でオーケストレートする macOS デスクトップアプリ。統合された差分表示、PR ワークフロー、GitHub 自動化を備えています。

| 属性 | 詳細 |
|-----------|---------|
| **ソース** | [conductor.build](https://conductor.build) |
| **ドキュメント** | [docs.conductor.build](https://docs.conductor.build) |
| **インストール** | [conductor.build](https://conductor.build) からダウンロード |
| **プラットフォーム** | macOS のみ（Windows/Linux 計画中） |
| **作者** | Melty Labs |

**ワークスペース管理**:

- 機能/バグフィックスごとに1つのワークスペースを `⌘⇧N` または GitHub issue や Linear issue から直接作成
- ステータス別に整理されたワークスペース：バックログ → 進行中 → レビュー中 → 完了（v0.35.0）
- 1つのビューで複数リポジトリをまたいでワークスペースをグループ化（v0.35.2）
- **次のワークスペース** ボタン（v0.36.4）：入力待ちの次のワークスペースにジャンプ、ブロックされたエージェントを手動でスキャンする必要なし
- 完全なチャット履歴を保持しながら完了したワークスペースをアーカイブ

**差分ビューア & コード編集**:

- チャットパネルの統合差分ビューア、エージェントメッセージごとのターン別差分（v0.22.0）
- `⌘D` で差分を開く。Conductor を離れずにファイルごとにナビゲート
- **手動モード**（v0.37.0）：シンタックスハイライトと `⌘F` 検索を持つ組み込みファイルエディタ — 別の IDE を開かずに素早い編集をカバー
- 差分に直接コメントして Claude にフィードバックを送信（v0.10.0）

**GitHub & CI 統合**:

- Checks タブで GitHub Actions ログを表示（v0.33.2）
- 失敗した CI チェックを修正のために自動的に Claude に転送（v0.12.0）
- Checks タブで PR タイトルと説明を直接編集（v0.34.1）
- GitHub から Conductor に PR コメントを同期（v0.25.4）
- マージ前にチェックオフされるまでワークスペースをブロックする TODO（v0.28.4）
- `⌘⇧P` で PR を作成

**Linear & その他の統合**:

- メッセージに Linear issues を添付、または Linear issue から直接 Conductor ワークスペースを開く（v0.15.0、v0.36.5）
- AI 生成レスポンス内の Linear、Slack、VS Code へのディープリンク
- パン/ズームとフルスクリーン付きの Mermaid ダイアグラムサポート

**エージェントサポート**:

- Claude Code（デフォルト）+ Codex を並列（v0.18.0）。キーボードナビゲート可能なモデルピッカー
- スラッシュコマンドオートコンプリート（例: Claude Code プロセスを再起動する `/restart`）

**報告されているワークフローパターン（コミュニティ）**:

複数リポジトリで5以上の並列機能に取り組むユーザーが次のフローを報告しています：機能ごとに1つのワークスペースを作成（GitHub issue または Linear issue をコンテキストとして）、エージェントを実行させ、**次のワークスペース**ボタンを使って入力待ちのワークスペースだけを処理し、アプリ内で差分をレビューして Checks タブからマージ。BMAD との組み合わせも報告あり：エピックごとに1つのワークスペース、実装用の Claude エージェントと次のストーリー用の2番目のエージェント — 仕様駆動開発の大幅な生産性向上として説明されています。

**制限**: 2026年3月時点で macOS のみ。独自仕様（オープンソースではない）。下記のマルチエージェントオーケストレーションツールと重複。


### Claude Code GUI（VS Code 拡張機能）

Claude Code の上にグラフィカルレイヤーを追加するサードパーティ VS Code 拡張機能（Anthropic の公式拡張機能ではありません）。

| 属性 | 詳細 |
|-----------|---------|
| **ソース** | [VS Code Marketplace: MaheshKok.claude-code-gui](https://marketplace.visualstudio.com/items?itemName=MaheshKok.claude-code-gui) |
| **インストール** | VS Code Marketplace → "Claude Code GUI" を検索 |

**注記**: これは Anthropic による公式の [Claude Code for VS Code](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code) 拡張機能では**ありません**。公式拡張機能はエディタ内に直接インライン差分、@メンション、プランレビューを提供します。

**制限**: サードパーティ、Anthropic のメンテナンスなし。機能セットは公式拡張機能と重複または遅れがある可能性。


## マルチエージェントオーケストレーション

このセクションでは**複数の Claude Code インスタンスを並列で実行**するツールを扱います。詳細なドキュメントは：

- **[AI エコシステム](./ai-ecosystem.md)** — Gas Town、multiclaude、agent-chat、claude-squad
- **[Ultimate Guide セクション9](./ultimate-guide.md)** — マルチインスタンスワークフロー、git ワークツリー、オーケストレーションフレームワーク

**クイックリファレンス**:

| ツール | タイプ | 主な機能 |
|------|------|-------------|
| [Gas Town](https://github.com/steveyegge/gastown) | マルチエージェントワークスペース | Steve Yegge のエージェントファーストワークスペースマネージャー |
| [multiclaude](https://github.com/dlorenc/multiclaude) | マルチエージェントスポーナー | tmux + git ワークツリー（383+スター） |
| [agent-chat](https://github.com/justinabrahms/agent-chat) | 監視 UI | Gas Town/multiclaude のリアルタイム SSE 監視 |
| [Conductor](#conductor) | デスクトップアプリ | macOS 並列エージェント（上記にも掲載） |


## 外部オーケストレーションフレームワーク

> **アーキテクチャ上の区別**: 上記のツール（Gas Town、multiclaude）は複数の Claude Code インスタンスを並列で実行します。外部オーケストレーションフレームワークはさらに踏み込んで — Claude Code の内部オーケストレーションレイヤーを独自のランタイムで置き換えまたは拡張し、その上にスウォームコーディネーション、永続メモリ、特化したエージェントプールを追加します。ネイティブ Claude Code 機能（Task ツール、サブエージェント）を最初に使い、それを使い尽くした後でこれらのフレームワークに手を伸ばしてください。

### Ruflo（旧 claude-flow）

**GitHub**: [github.com/ruvnet/ruflo](https://github.com/ruvnet/ruflo) — 18,900スター（2026年3月時点）
**npm**: `claude-flow` | **ライセンス**: MIT

Claude Code で最も普及している外部オーケストレーションフレームワーク。Claude Code を、階層的スウォーム（クイーン + ワーカー）、特化エージェントプール（60+エージェント：コーダー、テスター、レビュアー、アーキテクトなど）、SQLite による永続メモリを持つマルチエージェントプラットフォームに変換します。

**コア機能**:
- 過去のパターンに基づいて適切なエージェントにタスクをルーティングする Q ラーニングルーター
- 42+ 組み込みスキル、Claude Code とネイティブに統合する 17 フック
- ツール拡張のための MCP サーバーサポート
- クロスエージェントメモリ共有付きの SQLite バックドセッション永続性
- 非インタラクティブ CI/CD モード

**インストール**（実行前にソースを検査）:
```bash
npx ruflo@latest init --wizard
# curl|bash バリアントは使用しないこと — 古いリポジトリ名（claude-flow）からプルし、パッケージマネージャーのセキュリティを迂回する
```

> **主張についての注記**: プロジェクトはパフォーマンス指標（SWE-Bench スコア、速度倍率）を公開されていない方法論で公表しています。独立したベンチマークが出るまでは未検証として扱ってください。

> **成熟度についての注記**: 2026年初頭に claude-flow からリブランド。移行が進行中 — 本番採用前に npm パッケージ名とリポジトリの継続性を確認してください。

**使うとき**: Claude Code のネイティブ Task ツールとサブエージェントがユースケースに不十分な場合 — 通常は多くのセッションにわたる永続状態が必要な複雑なマルチステップパイプライン、または `--dangerously-skip-permissions` + tmux で達成できる以上の真の並列エージェントコーディネーションが必要なワークフロー。


### Athena Flow

**GitHub**: [github.com/lespaceman/athena-flow](https://github.com/lespaceman/athena-flow) | **ライセンス**: MIT（主張）
**ステータス**: 監視中 — 2026年3月公開、まだ監査なし

異なるアーキテクチャアプローチ：Claude Code のエージェントレイヤーを拡張する代わりに、Athena Flow は**フックレイヤー**に位置します。Unix Domain Socket（NDJSON）経由でフックイベントを傍受し、永続的な Node.js ランタイムを通じてルーティングして、リアルタイムの可観測性とワークフロー制御のための TUI を提供します。

```
Claude Code → hook-forwarder → Unix Domain Socket → Athena Flow ランタイム → TUI
```

最初に出荷されたワークフロー：自律型 E2E テストビルダー（Playwright CI 対応出力）。ロードマップ：ビジュアルリグレッション、API テスト、Codex サポート。

**まだ推奨しません** — ソース監査が保留中、プロジェクトが新しすぎて安定性を評価できません。4〜6週後に再確認。


### Pipelex + MTHDS

**GitHub**: [github.com/Pipelex/pipelex](https://github.com/Pipelex/pipelex) — 623スター（2026年3月）
**ライセンス**: MIT | **言語**: Python | **標準**: [mthds.ai](https://mthds.ai)

> **アーキテクチャ上の区別**: Pipelex は Claude Code エージェントをオーケストレートするのではなく — 再利用可能な AI メソッドを定義するための**宣言的 DSL**（`.mthds` ファイル）を提供します。Ruflo がエージェントのスウォームを管理するのに対し、Pipelex は型付きで git バージョン管理可能なマルチ LLM パイプラインを管理します。

MTHDS オープン標準の Python ランタイム。「AI メソッド」は LLM、OCR、画像生成を連鎖させるマルチステップワークフロー — 各ステップは実行前に型付きで検証されます。メソッドはgit バージョン管理可能で、コミュニティハブ [mthds.sh](https://mthds.sh) で共有でき、Claude Code で自動生成できます。

**Claude Code 統合**（推奨パス A）：
```bash
pip install pipelex
npm install -g mthds
```
```
# Claude Code 内で：
/plugin marketplace add mthds-ai/skills
/plugin install mthds@mthds-ai-skills
/exit  # Claude Code を再起動

# メソッドを生成：
/mthds-build CV 分析 → スコアカード + 面接質問

# 実行：
/mthds-run
```

**ユースケース**：大量の繰り返し可能なワークフロー — ドキュメント処理、候補者スコアリング、メール分類、契約分析。クリエイティブなオープンエンドな探索には適していません（そこでは Claude Code のネイティブエージェントの方が適切）。

**ステータス**：監視中 — 8ヶ月の存在、MTHDS 標準はまだ大規模に検証されていません。2026年 Q3 までのトラクションを監視。


## プラグインエコシステム

Claude Code のプラグインシステムはコミュニティ製拡張機能をサポートしています。詳細なドキュメントは：

- **[Ultimate Guide セクション8](./ultimate-guide.md)** — プラグインシステム、コマンド、インストール
- **[claude-plugins.dev](https://claude-plugins.dev)** — 11,989プラグイン、63,065スキルのインデックス
- **[claudemarketplaces.com](https://claudemarketplaces.com)** — GitHub を自動スキャンしてマーケットプレイスプラグインを探す
- **[agentskills.io](https://agentskills.io)** — エージェントスキルのオープン標準（26+プラットフォーム）

**注目のスキルパック**:
- **[gstack](https://github.com/garrytan/gstack)** — フルシップサイクルをカバーする6スキルワークフロースイート：戦略的製品ゲート（`/plan-ceo-review`）、アーキテクチャレビュー（`/plan-eng-review`）、徹底的なコードレビュー（`/review`）、自動リリース（`/ship`）、ネイティブブラウザ QA（`/browse`）、振り返り（`/retro`）。Garry Tan（Y Combinator CEO）作。ワークフローパターンと採用ガイドについては [認知モード切り替え](../workflows/gstack-workflow.md)を参照。


## 既知のギャップ

2026年2月時点で、コミュニティツールエコシステムには顕著なギャップがあります：

| ギャップ | 説明 |
|-----|-------------|
| **ビジュアルスキルエディタ** | `.claude/skills/` を作成/編集する GUI なし — YAML/Markdown を手動で編集する必要あり |
| **ビジュアルフックエディタ** | `settings.json` のフックを管理する GUI なし — JSON 編集が必要 |
| **統合管理パネル** | 設定、セッション、コスト、MCP 管理を組み合わせた単一ダッシュボードなし |
| **セッションリプレイ** | ✅ **解決済み**: Entire CLI（2026年2月ローンチ）が完全なコンテキストリプレイ付きの巻き戻し可能なチェックポイントを提供 |
| **エージェントネイティブな issue 追跡** | Claude Code に対応した Markdown ベースの git コミット可能な issue 追跡の確立されたツールなし。[fp.dev](https://fp.dev/) は初期段階のソリューション（ローカルファースト、`/fp-plan` + `/fp-implement` スキル、差分ビューア）ですが、採用シグナルがなく、デスクトップアプリには Apple Silicon が必要。Tasks API は状態永続性をカバーしますが、issues は git コミット可能ではありません。 |
| **MCP サーバーごとのプロファイラー** | 各 MCP サーバーに帰属するトークンコストを個別に測定する方法なし |
| **クロスプラットフォーム設定同期** | マシン間で Claude Code 設定を同期するツールなし（`~/.claude/` を手動でコピーする必要あり） |


## ペルソナ別推奨事項

| ペルソナ | 推奨ツール | 理由 |
|---------|-------------------|-----------|
| **ソロ開発者** | ccusage + claude-code-viewer | コスト意識 + セッション履歴レビュー |
| **小規模チーム（2〜5名）** | ccusage + Conductor または multiclaude | コスト追跡 + 並列開発 |
| **エンタープライズ** | ccusage（MCP）+ カスタムダッシュボード | プログラムコストデータ + 監査証跡 |
| **Python 中心** | ccburn + Claude Chic | ネイティブ Python エコシステムツール |
| **マルチエージェントユーザー** | Toad または Conductor | 統合エージェント管理 |
| **設定が多いセットアップ** | claude-code-config + AIBlueprint | TUI 設定管理 + スキャフォールディング |


## 関連リソース

- [可観測性](../ops/observability.md) — DIY セッション監視、ロギングフック、コスト追跡スクリプト
- [AI エコシステム](./ai-ecosystem.md) — 補完的な AI ツール（Perplexity、Gemini、NotebookLM）
- [MCP サーバーエコシステム](./mcp-servers-ecosystem.md) — 検証済みコミュニティ MCP サーバー
- [アーキテクチャ](../core/architecture.md) — Claude Code の内部動作
- [Ultimate Guide セクション8](./ultimate-guide.md) — プラグインシステムとマーケットプレイス
