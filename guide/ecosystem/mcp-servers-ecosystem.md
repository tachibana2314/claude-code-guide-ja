---
layout: default
title: "MCPサーバー"
parent: エコシステム
grand_parent: ガイド
nav_order: 2
---


# MCP サーバーエコシステム

**最終更新**: 2026年2月 • **次回レビュー**: 2026年3月

このガイドでは、Anthropic 公式サーバー以外の検証済みコミュニティ MCP サーバーを扱います。掲載されているすべてのサーバーは、本番対応、メンテナンス活動、セキュリティの観点から評価済みです。

> **MCP サーバーと CLI ツールのどちらを使うべきか迷っていますか？** トレードオフの詳細な内訳、意思決定マトリックス、状況別ガイダンスは [MCP vs CLI 意思決定ガイド](./mcp-vs-cli.md)を参照してください。

## 目次

- [公式サーバー vs コミュニティサーバー](#公式サーバー-vs-コミュニティサーバー)
- [評価フレームワーク](#評価フレームワーク)
- [エコシステムの進化](#エコシステムの進化)
- [検証済みコミュニティサーバー](#検証済みコミュニティサーバー)
  - [ブラウザ自動化](#ブラウザ自動化)
  - [DevOps & インフラ](#devops--インフラ)
  - [セキュリティ & コード分析](#セキュリティ--コード分析)
  - [コード検索 & 分析](#コード検索--分析)
  - [ドキュメント & ナレッジ](#ドキュメント--ナレッジ)
  - [プロジェクト管理](#プロジェクト管理)
  - [オーケストレーション](#オーケストレーション)
- [本番デプロイ](#本番デプロイ)
- [月次監視方法論](#月次監視方法論)
- [除外されたサーバー](#除外されたサーバー)


## 公式サーバー vs コミュニティサーバー

| タイプ | 例 | 特徴 | 使うとき |
|------|----------|-----------------|----------|
| **公式** | filesystem、memory、brave-search、github | Anthropic メンテナンス、安定性保証 | デフォルトの選択、コア機能 |
| **コミュニティ** | Playwright、Semgrep、Kubernetes | 組織/個人によるメンテナンス、本番対応になりうる | 特殊なニーズ、エコシステム統合 |

**主な違い**: 公式サーバーは Anthropic の SLA 保証があり、コミュニティサーバーは個別の評価が必要です。


## 評価フレームワーク

すべてのコミュニティサーバーはこれらの基準に対して評価されます：

| 基準 | 閾値 | 理由 |
|-----------|-----------|---------------|
| **GitHub スター** | ≥50 | 最低限のコミュニティ検証 |
| **最近のリリース** | 3ヶ月以内 | 積極的なメンテナンス |
| **ドキュメント** | README + 例 + 設定 | 採用の摩擦を軽減 |
| **テスト/CI** | ✅ 自動化 | 安定性を確保 |
| **ユースケース** | 公式サーバーでカバーされていない | 重複を避ける |
| **ライセンス** | OSS 必須 | 持続可能性と監査可能性 |

**品質スコアの構成要素**:
- メンテナンス（10点）：リリース頻度、issue 対応時間
- ドキュメント（10点）：README の完全性、例、トラブルシューティング
- テスト（10点）：テストカバレッジ、CI/CD 自動化
- パフォーマンス（10点）：応答時間、リソース効率
- 採用（10点）：コミュニティ使用、本番デプロイ

**合計スコア**: `/50` → 最終評価 `/10` に正規化。


## エコシステムの進化

**主な開発動向（2026年1月）**:

### Linux Foundation による標準化

MCP は **Agentic AI Foundation** を通じて Linux Foundation のガバナンス下で公式標準になります。

- **発表**: [YouTube - Linux Foundation](https://www.youtube.com/watch?v=btNbIY7KYwg)
- **影響**: エンタープライズ採用、長期的な安定性保証

### 高度な MCP ツール使用

Anthropic が MCP コンテキスト管理の最適化をデプロイ：

- **遅延ローディング**: ツールはアップフロントではなくオンデマンドでロード
- **検索ベースのツール**: 大規模なツールセットでの効率的なツール発見
- **発表**: [Josh Twist LinkedIn](https://www.linkedin.com/posts/joshtwist_anthropic-recently-dropped-advanced-mcp-activity-7399492619581718528-g-Ip)

### MCPB バンドル形式

ワンクリックの MCP サーバーインストールのための標準化されたバンドル形式（ランタイム依存管理を置き換え）。

- **ディスカッション**: [Reddit - r/ClaudeAI](https://www.reddit.com/r/ClaudeAI/comments/1qkzdh0/mcp_server_installs_are_nondeterministic_heres/)
- **メリット**: 決定論的なインストール、セットアップの摩擦を軽減

### MCP アプリ（インタラクティブ作業ツール）

Claude は MCP アプリ仕様経由でインタラクティブツールをサポートするようになりました：

- **例**: Slack の下書き、Figma ダイアグラム、Asana タイムライン
- **発表**: [Smol.ai ニュースレター](https://news.smol.ai/issues/26-01-26-mcp-apps)
- **詳細**: [guide/architecture.md:656](../core/architecture.md#mcp-extensions-apps-sep-1865)を参照

### IDE 統合

**Visual Studio 2026** が Azure MCP サーバー、GitHub Copilot Chat、MCP クライアントをネイティブに統合。

- **発表**: [Microsoft DevBlogs](https://devblogs.microsoft.com/visualstudio/azure-mcp-server-now-built-in-with-visual-studio-2026-a-new-era-for-agentic-workflows/)


## バージョン管理（公式サーバー）

これらの基礎的な MCP サーバーは、すべての開発ワークフローのバージョン管理自動化を提供します。安定性が保証された **Anthropic 公式サーバー**です。

### Git MCP（Anthropic）

Model Context Protocol 経由で Git リポジトリを操作する **Anthropic 公式サーバー**。構造化出力とクロスプラットフォームの安全性を持つ Git 操作へのプログラム的アクセスを提供します。

**リポジトリ**: [modelcontextprotocol/servers/git](https://github.com/modelcontextprotocol/servers/tree/main/src/git)
**ライセンス**: MIT
**ステータス**: 初期開発段階（API は変更される可能性あり）
**スター数**: 77,908+（親リポジトリ）

**ユースケース**:
- **自動コミットワークフロー**: AI がコミットメッセージを生成、変更をステージング、コミット
- **ログ分析**: 日付、作者、ブランチで構造化出力を使ってコミットをフィルタリング
- **ブランチ管理**: フィーチャーブランチの作成、チェックアウト、SHA でのフィルタリング
- **トークン効率的な差分**: フォーカスされたコードレビューのためのコンテキスト行を制御
- **マルチリポジトリ自動化**: モノリポセットアップで複数のリポジトリを管理

#### 主要機能

| ツール | 説明 | パラメータ |
|------|-------------|------------|
| `git_status` | 作業ツリーの状態（ステージ済み、未ステージ、未追跡） | - |
| `git_log` | 高度なフィルタリング付きコミット履歴 | `max_count`、`skip`、`start_timestamp`、`end_timestamp`、`author` |
| `git_diff` | コミット/ブランチ間の差分 | `target`、`source`、`context_lines` |
| `git_diff_unstaged` | 未ステージの変更 | `context_lines` |
| `git_diff_staged` | ステージ済みの変更 | `context_lines` |
| `git_commit` | コミットを作成 | `message` |
| `git_add` | ファイル/パターンをステージング | `files` |
| `git_reset` | ファイルをアンステージ | `files` |
| `git_branch` | ブランチの一覧/フィルタリング | `contains`、`not_contains` |
| `git_create_branch` | 新しいブランチを作成 | `name` |
| `git_checkout` | ブランチ/コミットを切り替え | `ref` |
| `git_show` | コミットの詳細を表示 | `revision` |

**高度なフィルタリング**（`git_log`）:
- **ISO 8601 日付**: `2024-01-15T14:30:25`
- **相対日付**: `2 weeks ago`、`yesterday`、`last month`
- **絶対日付**: `2024-01-15`、`Jan 15 2024`
- **作者フィルタリング**: `--author="John Doe"`

#### セットアップ

**インストール（3つの方法）**:

```bash
# 方法1: UV（推奨）— ワンライナー
uvx mcp-server-git --repository /path/to/repo

# 方法2: pip + Python モジュール
pip install mcp-server-git
python -m mcp_server_git

# 方法3: Docker（サンドボックス化）
docker run -v /path/to/repo:/repo ghcr.io/modelcontextprotocol/mcp-server-git
```

**Claude Code 設定**（`~/.claude.json`）:

```json
{
  "mcpServers": {
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "/Users/you/projects/myrepo"]
    }
  }
}
```

**マルチリポジトリサポート**:

```json
{
  "mcpServers": {
    "git-main": {
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "/path/to/main-repo"]
    },
    "git-docs": {
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "/path/to/docs-repo"]
    }
  }
}
```

#### IDE 統合

**ワンクリックインストールボタンが利用可能なもの**:
- **Claude Desktop**（macOS/Windows/Linux）
- **VS Code**（安定版 + Insiders）
- **Zed**
- **Zencoder**

統合リンクは [公式 README](https://github.com/modelcontextprotocol/servers/tree/main/src/git#quickstart) を参照。

#### 品質スコア

**8.5/10** ⭐⭐⭐⭐⭐

| 基準 | スコア | 備考 |
|-----------|-------|-------|
| メンテナンス | 10/10 | Anthropic サポート、積極的な開発 |
| ドキュメント | 9/10 | 包括的な README、例あり、ただし初期開発の警告あり |
| テスト | 8/10 | 自動化 CI、カバレッジを改善中 |
| パフォーマンス | 8/10 | 高速（<100ms）、構造化出力でトークンを削減 |
| 採用 | 8/10 | 公式サーバー、77K+スター、幅広い IDE サポート |

#### 制限と回避策

| 制限 | 回避策 |
|------------|-----------|
| **初期開発**（API 変更） | 本番でバージョンを固定、リリースを監視 |
| **インタラクティブリベースなし**（`-i` フラグ） | `git rebase -i` に Bash ツールを使用 |
| **reflog サポートなし** | `git reflog` に Bash ツールを使用 |
| **git bisect なし** | `git bisect` に Bash ツールを使用 |
| **インスタンスあたり単一リポジトリ** | 複数の MCP サーバーインスタンスを設定 |

#### 意思決定マトリックス: Git MCP vs GitHub MCP vs Bash ツール

**どのツールをいつ使うか**:

| 操作 | Git MCP | GitHub MCP | Bash ツール | 理由 |
|-----------|---------|------------|-----------|---------------|
| **ローカルコミット** | ✅ 最良 | ❌ | ⚠️ 可 | 構造化出力、クロスプラットフォーム安全 |
| **ブランチ管理** | ✅ 最良 | ❌ | ⚠️ 可 | `git_branch` フィルタリング、SHA contains/excludes |
| **差分/ログ分析** | ✅ 最良 | ❌ | ⚠️ 可 | `context_lines` 制御、トークン効率 |
| **ファイルのステージング** | ✅ 最良 | ❌ | ⚠️ 可 | パターンマッチング（`git_add`）、より安全 |
| **PR 作成** | ❌ | ✅ 最良 | ⚠️ gh CLI | GitHub API、ラベル、アサイニー、レビュアー |
| **issue 管理** | ❌ | ✅ 最良 | ⚠️ gh CLI | GitHub 固有の操作 |
| **CI/CD ステータスチェック** | ❌ | ✅ 最良 | ⚠️ gh CLI | GitHub Actions 統合 |
| **インタラクティブリベース** | ❌ | ❌ | ✅ 最良 | Git MCP は `-i` フラグをサポートしない |
| **Reflog 回復** | ❌ | ❌ | ✅ 最良 | 高度な Git 操作 |
| **Git bisect デバッグ** | ❌ | ❌ | ✅ 最良 | 複雑なデバッグワークフロー |
| **マルチツールパイプライン** | ✅ | ✅ | ❌ | MCP サーバーは他の MCP ツールと組み合わせ可能 |

**意思決定ツリー**:

```
GitHub 固有の操作（PR、Issues、Actions）ですか？
├─ YES → GitHub MCP を使用
└─ NO → コアな Git 操作（commit、branch、diff、log）ですか？
    ├─ YES → Git MCP を使用（構造化、安全、トークン効率）
    └─ NO → 高度な Git 機能（rebase -i、reflog、bisect）ですか？
        ├─ YES → Bash ツールを使用（柔軟性）
        └─ NO → Git MCP をデフォルトに（より安全、構造化）
```

**ワークフロー例**:

| ワークフロー | ツールチェーン | 理由 |
|----------|-----------|---------------|
| **フィーチャー開発** | Git MCP（`git_create_branch` + `git_commit`）→ GitHub MCP（PR） | アトミック、構造化、フルライフサイクル |
| **コミット履歴分析** | Git MCP（`git_log` with `start_timestamp: "2 weeks ago"`） | トークン効率のフィルタリング、相対日付 |
| **コードレビュー準備** | Git MCP（`git_diff` with `context_lines: 3`） | フォーカスされたコンテキスト、削減されたトークン |
| **コミットのクリーンアップ（リベース）** | Bash ツール（`git rebase -i HEAD~5`） | インタラクティブモードは Git MCP にない |
| **失われたコミットの回復** | Bash ツール（`git reflog`） | Reflog は Git MCP で公開されていない |
| **バグハンティング（bisect）** | Bash ツール（`git bisect start/good/bad`） | Bisect ワークフローは Git MCP にない |
| **自動リリースフロー** | Git MCP（commit + tag）→ GitHub MCP（リリース作成） | フル自動化、構造化 |

#### リソース

- **GitHub**: https://github.com/modelcontextprotocol/servers/tree/main/src/git
- **親リポジトリ**: https://github.com/modelcontextprotocol/servers（77,908+スター）
- **MCP インスペクター**: ライブテスト用のデバッグツールサポート
- **Docker Hub**: `ghcr.io/modelcontextprotocol/mcp-server-git`


## 検証済みコミュニティサーバー

### ブラウザ自動化

#### Playwright MCP（Microsoft）

LLM に最適化されたブラウザ自動化の **Microsoft 公式サーバー**。スクリーンショットの代わりにアクセシビリティツリーを使用し、トークン使用量を削減します。

**ユースケース**: AI コーディングエージェントがブラウザで作業を検証（E2E テスト、バグ検証）。

**主要機能**:

| 機能 | 詳細 |
|------------|---------|
| ブラウザ自動化 | ナビゲート、クリック、入力、ホバー（Playwright API） |
| コンテンツ抽出 | アクセシビリティツリー経由の構造化データ |
| スクリーンショット | フルページ + 要素固有 |
| JavaScript 実行 | ページコンテキストでコードを実行 |
| セッション管理 | 永続的なブラウザ状態 |
| サポートブラウザ | Chromium、Firefox、WebKit |

**セットアップ**:

```bash
# インストール
npm install @microsoft/playwright-mcp
# または
npx @microsoft/playwright-mcp
```

**Claude Code 設定**（`~/.claude.json`）:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["--yes", "@microsoft/playwright-mcp"]
    }
  }
}
```

**使用例**:

```
ユーザー: "example.com にナビゲートし、メール test@example.com でログインして、スクリーンショットを撮って"

Claude: [playwright_navigate → playwright_type → playwright_click → playwright_screenshot を使用]

結果: コンテキスト内のスクリーンショット + アクセシビリティツリー
```

**品質スコア**: **8.8/10** ⭐⭐⭐⭐⭐

| 次元 | スコア | 備考 |
|-----------|-------|-------|
| メンテナンス | 9/10 | 隔週リリース、積極的な Microsoft チーム |
| ドキュメント | 9/10 | README 完全、例あり、Playwright Live ビデオ |
| テスト | 10/10 | 広範なテストスイート、CI/CD 自動化 |
| パフォーマンス | 8/10 | 高速スナップショット（~200ms）、メモリ効率良 |
| 採用 | 8/10 | 2890+の利用（Smithery.ai 追跡） |

**制限と回避策**:

| 制限 | 回避策 |
|------------|-----------|
| 単一ブラウザセッション | セッション ID を使って状態を永続化 |
| クロスドメイン iframe アクセスなし | 同一オリジンコンテンツに制限 |
| スクリーンショットサイズ制限（最大4K） | 大きなページには要素スナップショットを使用 |

**代替手段**:

| サーバー | 利点 | 欠点 |
|--------|-----------|--------------|
| **Playwright MCP** | アクセシビリティツリー、LLM ネイティブ | ビジョンモデルサポートなし |
| Browserbase MCP | クラウドベース、ステルスモード | API コスト、レイテンシ |
| Puppeteer MCP | 軽量、JS のみ | 構造化データが少ない |

**リソース**:
- **GitHub**: https://github.com/microsoft/playwright-mcp
- **リリース**: https://github.com/microsoft/playwright-mcp/releases
- **Playwright Live デモ**: https://youtu.be/CNzg1aPwrKI


#### Browserbase MCP

クラウドブラウザ自動化の **Browserbase 公式サーバー**。自律タスク実行のための Stagehand AI エージェントを含みます。

**ユースケース**: ステルスモード、プロキシサポート、または自律実行が必要な複雑な Web インタラクション（Web スクレイピング、フォーム入力、データ抽出）。

**主要機能**:

| 機能 | 詳細 |
|------------|---------|
| ブラウザ制御 | Browserbase クラウド経由の Chromium |
| Stagehand エージェント | 自律タスク実行（例: "フライトを予約して"） |
| データ抽出 | CSS セレクター + スキーマベースの構造化抽出 |
| アンチ検出 | ステルスモード、プロキシサポート、ローテーション |
| マルチモデル | OpenAI、Claude、Gemini、カスタム LLM |

**セットアップ**:

```bash
npm install @browserbasehq/mcp-server-browserbase
```

**設定**:

```json
{
  "mcpServers": {
    "browserbase": {
      "command": "npx",
      "args": ["@browserbasehq/mcp-server-browserbase"],
      "env": {
        "BROWSERBASE_API_KEY": "YOUR_KEY",
        "BROWSERBASE_PROJECT_ID": "YOUR_PROJECT_ID",
        "GEMINI_API_KEY": "YOUR_GEMINI_KEY"
      }
    }
  }
}
```

**品質スコア**: **7.6/10** ⭐⭐⭐⭐

**コスト**: フリーミアム（有料 API 使用）、約 $0.10/セッション

**制限**:

| 制限 | 回避策 |
|------------|-----------|
| レイテンシ（クラウド約500ms） | 操作をバッチ処理、結果をキャッシュ |
| API コスト | 高価値な抽出のみに使用 |
| Stagehand の制限 | 手動 playwright_* ツールにフォールバック |

**リソース**:
- **GitHub**: https://github.com/browserbase/mcp-server-browserbase
- **公式ドキュメント**: https://www.browserbase.com


#### Chrome DevTools MCP

Chrome DevTools Protocol 統合の **Anthropic 公式サーバー**。Chrome のネイティブ DevTools API 経由でデバッグと検査機能を提供します。

**ユースケース**: Web アプリケーションのデバッグ、実行時状態の検査、ネットワークリクエストの監視、パフォーマンス分析。Playwright MCP（テスト）を開発向けデバッグ機能で補完します。

**主要機能**:

| 機能 | 詳細 |
|------------|---------|
| コンソールアクセス | ブラウザコンソールログ、エラー、警告を読み取り |
| ネットワーク監視 | HTTP リクエスト、レスポンス、ヘッダーを検査 |
| DOM 検査 | DOM 構造、要素プロパティを照会 |
| JavaScript 実行 | ページコンテキストで任意の JS を実行 |
| パフォーマンスプロファイリング | CPU プロファイル、メモリスナップショット |

**セットアップ**:

```bash
npm install @modelcontextprotocol/server-chrome-devtools
```

**設定**:

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-chrome-devtools"]
    }
  }
}
```

**使うとき**:

| シナリオ | Chrome DevTools MCP を使用 | Playwright MCP を使用 |
|----------|------------------------|-------------------|
| 実行時エラーをデバッグ | ✅ コンソールログ、スタックトレース | ❌ エラー可視性が限定的 |
| ネットワーク呼び出しを検査 | ✅ 完全なリクエスト/レスポンス詳細 | ⚠️ 基本的なナビゲーションのみ |
| ユーザーインタラクションをテスト | ❌ テスト向けに設計されていない | ✅ クリック、タイプ、ナビゲート |
| パフォーマンスをプロファイリング | ✅ CPU/メモリプロファイリング | ❌ プロファイリングツールなし |
| ワークフローを自動化 | ❌ 手動デバッグフォーカス | ✅ E2E テスト自動化 |

**制限**:
- DevTools Protocol を有効にして Chrome ブラウザが実行されている必要がある
- 手動セットアップ（`--remote-debugging-port` で Chrome を起動）
- 自動テストには適していない（それには Playwright を使用）
- プロファイリング有効時のパフォーマンスオーバーヘッド

**リソース**:
- **npm**: https://www.npmjs.com/package/@modelcontextprotocol/server-chrome-devtools
- **Chrome DevTools Protocol**: https://chromedevtools.github.io/devtools-protocol/


### DevOps & インフラ

#### Kubernetes MCP（Red Hat）

自然言語で Kubernetes/OpenShift を管理する **Containers コミュニティ公式サーバー**（Red Hat バックアップ）。

**ユースケース**: DevOps/SRE が Claude を使ってクラスターを照会/設定（「自然言語の kubectl」）。

**主要機能**:

| 機能 | 詳細 |
|------------|---------|
| リソース CRUD | 任意の K8s リソースの作成、読み取り、更新、削除 |
| Pod 操作 | ログ、イベント、exec、メトリクス（top） |
| デプロイメント管理 | スケール、ロールアウト、ステータス |
| 設定管理 | ConfigMaps、Secrets の表示/更新 |
| CRD サポート | カスタムリソース定義 |
| マルチクラスター | kubeconfig コンテキストの切り替え |
| OpenShift サポート | ネイティブ OpenShift リソース |

**セットアップ**:

```bash
# Docker
docker run -it --rm \
  --mount type=bind,src=$HOME/.kube/config,dst=/home/mcp/.kube/config \
  ghcr.io/containers/kubernetes-mcp-server

# ネイティブ（Go バイナリ）
go install github.com/containers/kubernetes-mcp-server@latest
kubernetes-mcp-server
```

**Claude Desktop 設定**:

```json
{
  "mcpServers": {
    "kubernetes": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "--mount",
        "type=bind,src=/home/user/.kube/config,dst=/home/mcp/.kube/config",
        "ghcr.io/containers/kubernetes-mcp-server"
      ]
    }
  }
}
```

**使用例**:

```
ユーザー: "メモリ使用量が500Miを超えるプロダクションネームスペースのすべての Pod を表示して"
Claude: [Pod の list_resources + メトリクスを使用]
結果: メモリ統計付きの Pod リスト

ユーザー: "バックエンドデプロイメントを5レプリカにスケールして"
Claude: [patch_resource を使用]
結果: デプロイメントがスケールされた
```

**品質スコア**: **8.4/10** ⭐⭐⭐⭐

**セキュリティ**: RBAC 強制、kubeconfig 認証、権限昇格なし

**制限**:

| 制限 | 回避策 |
|------------|-----------|
| kubeconfig アクセスが必要 | 安全のために ServiceAccount + RBAC を使用 |
| ノードシェルアクセスが限定的 | デバッグには `kubectl exec` を使用 |
| CRD 発見の遅延 | AI コンテキスト用に CRD を事前ドキュメント化 |

**リソース**:
- **GitHub**: https://github.com/containers/kubernetes-mcp-server
- **Red Hat ドキュメント**: https://developers.redhat.com/articles/2025/09/25/kubernetes-mcp-server-ai-powered-cluster-management


#### Vercel MCP

Vercel プラットフォーム（デプロイ、プロジェクト、環境変数、チーム）の**コミュニティサーバー**。

**ユースケース**: AI アシスタントが Next.js コードを生成、Vercel プロジェクトを作成、環境変数を設定、デプロイをトリガー — IDE を離れずにフル CI/CD ループ。

**主要機能**:

| 機能 | 詳細 |
|------------|---------|
| デプロイ | リスト、詳細取得、作成、ステータス監視 |
| プロジェクト | リスト、作成、設定更新 |
| 環境変数 | 取得、設定、シークレット管理 |
| チーム | リスト、作成、管理 |
| ドメイン | リスト、設定、DNS 管理 |
| 関数 | Vercel 関数のモニタリング、ログ |

**セットアップ**:

```bash
git clone https://github.com/nganiet/mcp-vercel
cd vercel-mcp
npm install
```

**設定**:

```json
{
  "mcpServers": {
    "vercel": {
      "command": "npm",
      "args": ["start"],
      "env": {
        "VERCEL_API_TOKEN": "YOUR_VERCEL_TOKEN"
      }
    }
  }
}
```

**品質スコア**: **7.6/10** ⭐⭐⭐⭐

**注記**: Vercel にも公式 MCP サーバーがあります。このコミュニティ版は包括的な API カバレッジを提供します。

**リソース**:
- **GitHub**: https://github.com/nganiet/mcp-vercel
- **Vercel ドキュメント**: https://vercel.com/docs/mcp/deploy-mcp-servers-to-vercel
- **Vercel 公式 MCP**: https://vercel.com/docs/mcp/vercel-mcp


### セキュリティ & コード分析

#### Semgrep MCP

脆弱性スキャン（SAST、シークレット、サプライチェーン）の **Semgrep 公式サーバー**。カスタムルールエンジンを含みます。

**ユースケース**: Claude Code がコードを生成し、Semgrep が自動的にセキュリティ問題をスキャンして修正を提案（「デフォルトでセキュア」）。

**主要機能**:

| 機能 | 詳細 |
|------------|---------|
| クイックスキャン | コードスニペットの高速セキュリティチェック |
| フルスキャン | p/ci ルールセットを使った包括的 SAST |
| カスタムルール | ユーザー提供の Semgrep ルールでスキャン |
| AST 生成 | 分析用の抽象構文木 |
| ルールセットサポート | 事前構築ルールセット（OWASP、CWE など） |
| 言語カバレッジ | Python、JS/TS、Java、Go、C#、Rust、PHP など |

**セットアップ**:

```bash
# uvx 経由（推奨）
uvx semgrep-mcp

# または pip
pip install semgrep-mcp
```

**Claude Code 設定**:

```bash
claude mcp add semgrep -- uvx semgrep-mcp
```

**Cursor 設定**（`~/.cursor/mcp.json`）:

```json
{
  "mcpServers": {
    "semgrep": {
      "command": "uvx",
      "args": ["semgrep-mcp"],
      "env": {
        "SEMGREP_APP_TOKEN": "your_token"
      }
    }
  }
}
```

**使用例**:

```
ユーザー: "この Python コードの SQL インジェクション脆弱性をスキャンして"

コード:
  def search(query):
      return db.execute(f"SELECT * FROM users WHERE name = '{query}'")

Claude: [security_check ツールを使用]

結果: [脆弱性] 2行目で SQL インジェクションを検出。
  修正: パラメータ化クエリを使用:
  return db.execute("SELECT * FROM users WHERE name = ?", [query])
```

**品質スコア**: **9.0/10** ⭐⭐⭐⭐⭐

| 次元 | スコア | 備考 |
|-----------|-------|-------|
| メンテナンス | 10/10 | 公式、頻繁なリリース |
| ドキュメント | 9/10 | 包括的なドキュメント、例あり |
| テスト | 10/10 | 広範なテストカバレッジ |
| パフォーマンス | 7/10 | 良好、複雑さ依存（スキャンあたり約500ms） |
| 採用 | 9/10 | エンタープライズ標準（5000+企業） |

**代替手段**:

| サーバー | 利点 | 欠点 |
|--------|-----------|--------------|
| **Semgrep** | 包括的 SAST、カスタムルール | 大規模コードベースでは遅い |
| GitGuardian | シークレット特化、高速 | SAST カバレッジが限定的 |
| SonarQube | エンタープライズ、詳細レポート | 重い、セットアップが多い |

**リソース**:
- **GitHub**: https://github.com/semgrep/mcp
- **公式ドキュメント**: https://semgrep.dev/docs/mcp
- **ルールレジストリ**: https://semgrep.dev/r
- **価格**: https://semgrep.dev/pricing（MCP は無料ティアあり）


### コード検索 & 分析

#### Grepai MCP

ローカル Ollama エンベディングによるセマンティックコード検索とコールグラフ分析の**コミュニティサーバー**。正確なパターンではなく意図（「支払いフロー」、「認証ロジック」）でコードを検索し、関数の呼び出し関係をトレースします。

**リポジトリ**: [yoanbernabeu/grepai](https://github.com/yoanbernabeu/grepai)
**ライセンス**: MIT
**ステータス**: 活発な開発中
**プライバシー**: 完全ローカル（Ollama + nomic-embed-text）、データはマシンを離れない

**ユースケース**: 開発者が未知のコードベースを理解する必要がある → grepai が自然言語の説明で関連コードを見つけ、ファイル全体を読まずに関数の依存関係をマッピング。

**主要機能**:

| 機能 | 詳細 |
|------------|---------|
| `grepai_search` | 自然言語クエリによるセマンティック検索（例: "エラー処理ミドルウェア"） |
| `grepai_trace_callers` | 指定されたシンボルを呼び出すすべての関数を検索 |
| `grepai_trace_callees` | 指定されたシンボルが呼び出すすべての関数を検索 |
| `grepai_trace_graph` | 設定可能な深度でのフルコールグラフ（callers + callees） |
| `grepai_index_status` | ヘルスチェック：インデックス済みファイル、チャンク、設定 |

**トークン効率**:

| ワークフロー | トークン | 評価 |
|----------|--------|---------|
| Grep + ファイル読み込み（総当たり） | ~15K | ノイズが多い、無関係なコンテキストが多い |
| grepai 検索 + トレース | ~4K | ターゲット絞り込み、関連結果のみ |
| grepai のみ（フォローアップなし） | ~2〜3K | 高速な発見 |

**セットアップ**:

```bash
# grepai のインストール
curl -sSL https://raw.githubusercontent.com/yoanbernabeu/grepai/main/install.sh | sh

# Ollama + エンベディングモデルのインストール
brew install ollama
ollama pull nomic-embed-text

# プロジェクトで初期化
cd /path/to/project
grepai init  # 選択: ollama、nomic-embed-text、gob

# コードベースをインデックス
grepai index

# オプション: ファイル変更を監視（自動再インデックス）
grepai watch
```

**Claude Code 設定**:

```bash
claude mcp add grepai -- grepai mcp
```

**`.mcp.json`（プロジェクトスコープ）**:

```json
{
  "mcpServers": {
    "grepai": {
      "command": "grepai",
      "args": ["mcp"]
    }
  }
}
```

**使用例**:

```
ユーザー: "このコードベースの認証フローを見つけて"

Claude: [grepai_search query="authentication flow" limit=5 を使用]

結果: 行番号と類似スコア付きの3つの関連ファイル
  - src/auth/middleware.ts:12-45 (0.89)
  - src/routes/login.ts:8-32 (0.85)
  - src/utils/jwt.ts:1-28 (0.78)

ユーザー: "validateToken 関数を呼び出しているものは何？"

Claude: [grepai_trace_callers symbol="validateToken" を使用]

結果: 3ファイルの4つの呼び出し元を示すコールグラフ
  - authMiddleware → validateToken
  - refreshHandler → validateToken
  - wsAuthGuard → validateToken
  - testHelper → validateToken
```

**品質スコア**: **7.8/10** ⭐⭐⭐⭐

| 次元 | スコア | 備考 |
|-----------|-------|-------|
| メンテナンス | 8/10 | 積極的な開発、反応の良いメンテナー |
| ドキュメント | 7/10 | 良い README、MCP 統合ドキュメント |
| テスト | 7/10 | CI あり、カバレッジ増加中 |
| パフォーマンス | 8/10 | 高速なローカルエンベディング（検索約2秒）、ネットワーク遅延なし |
| 採用 | 9/10 | 成長するコミュニティ、Claude Code セットアップで本番利用 |

**制限と回避策**:

| 制限 | 回避策 |
|------------|-----------|
| ローカルで Ollama の実行が必要 | `brew services start ollama`（自動起動） |
| インデックスが古くなる可能性 | 自動再インデックスに `grepai watch` を使用 |
| 正確なパターンマッチングには最適でない | 正規表現パターンにはネイティブ Grep ツールを使用 |
| エンベディングモデルのダウンロード（~270MB） | 一度だけの `ollama pull nomic-embed-text` |

**代替手段**:

| サーバー | 利点 | 欠点 |
|--------|-----------|--------------|
| **Grepai** | ローカル、プライベート、セマンティック + コールグラフ | Ollama セットアップが必要 |
| ネイティブ Grep | 即時、正確なパターン | セマンティック理解なし |
| GitHub Code Search | クラウドベース、クロスリポジトリ | GitHub が必要、コールグラフなし |

**相互参照**: 詳細な使用パターン、プロンプト戦略、他の MCP サーバーとの統合については [ultimate-guide.md — MCP サーバー: Grepai](./ultimate-guide.md) を参照。

**リソース**:
- **GitHub**: https://github.com/yoanbernabeu/grepai
- **Ollama**: https://ollama.com
- **エンベディングモデル**: nomic-embed-text（nomic-ai）


### ドキュメント & ナレッジ

#### Context7 MCP

リアルタイムライブラリドキュメント（LangChain、Anthropic SDK など）の **Upstash 公式サーバー**。API のハルシネーションを排除します。

**ユースケース**: Claude Code がライブラリ API を使う必要がある → Context7 が最新のドキュメント + 例を提供。

**主要機能**:

| 機能 | 詳細 |
|------------|---------|
| ライブラリ検索 | 500+のライブラリのドキュメントを検索 |
| コード例 | 言語固有の例（Python、TS など） |
| API リファレンス | 詳細な関数シグネチャ、パラメータ |
| バージョンフィルタリング | 特定のライブラリバージョンのドキュメント |
| スマートランキング | 関連性 + プロジェクト使用でAIランキング |

**セットアップ**:

```bash
# ローカル
npx -y @upstash/context7-mcp --api-key YOUR_API_KEY
```

**Claude Code 設定（ローカル）**:

```bash
claude mcp add context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY
```

**Claude Code 設定（リモート/HTTP）**:

```bash
claude mcp add --transport http --header "CONTEXT7_API_KEY: YOUR_API_KEY" \
  context7 https://mcp.context7.com/mcp
```

**使用例**:

```
ユーザー: "Python SDK で Claude のストリーミング API の使い方を教えて"

Claude: [context7 検索を使用]

結果: ストリーミング用の公式 Python SDK ドキュメント + コード例
```

**品質スコア**: **8.2/10** ⭐⭐⭐⭐

**制限**:

| 制限 | 回避策 |
|------------|-----------|
| ライブラリカバレッジが限定的 | マイナーライブラリには Web 検索にフォールバック |
| バージョン遅延（1〜2日） | 最先端には公式リポジトリを使用 |
| ハルシネーションリスク（低いが存在） | 公式ドキュメントで相互確認 |

**代替手段**:

| サーバー | 利点 | 欠点 |
|--------|-----------|--------------|
| **Context7** | リアルタイム、バージョン固有 | API キーが必要 |
| Web 検索 | 包括的、無料 | 遅い、ハルシネーションリスク |
| 静的 RAG | 高速、ローカル | 古い、バージョンなし |

**リソース**:
- **GitHub**: https://github.com/upstash/context7
- **公式サイト**: https://context7.com
- **LobeHub レジストリ**: https://lobehub.com/mcp/upstash-context7

**ctx7 CLI コンパニオン**: Context7 はターミナルからのスキル発見と MCP セットアップを処理する CLI（`npx ctx7`）も同梱しています。`ctx7 skills suggest` はプロジェクトの依存関係を自動検出して一致するスキルを推奨。`ctx7 setup --claude` は MCP または CLI+スキルモードを自動設定するウィザードを実行します。フルワークフローについては Ultimate Guide の §5.5 を参照。


### プロジェクト管理

#### Linear MCP

Linear（プロジェクト管理 SaaS）の**コミュニティサーバー**。issue 管理、プロジェクト、チーム、コメントを持つ GraphQL API。

**ユースケース**: Claude Code が自動的にチケットを作成し、ステータスを更新し、Linear で issue をリンク（開発とプロジェクト管理のループを閉じる）。

**主要機能**:

| 機能 | 詳細 |
|------------|---------|
| Issue 管理 | リスト、取得、作成、更新、削除、検索 |
| プロジェクト | リスト、作成、更新、割り当て |
| チーム & ユーザー | チーム管理、メンバー割り当て |
| コメント | 追加、リスト、位置追跡付き |
| サイクル | スプリント/サイクル管理 |
| Webhook | Linear イベントの購読（オプション） |

**セットアップ**:

```bash
# NPM または uvx
npm install mcp-linear
# または
uvx mcp-linear
```

**Claude Code 設定**:

```bash
claude mcp add linear -- npx -y mcp-linear --api-key YOUR_LINEAR_API_KEY
```

**使用例**:

```
ユーザー: "見つけた CSS レイアウトの問題の バグチケットを Linear に作成して"

Claude: [チームキー、タイトル、説明で linear.issues.create を使用]

結果: チケット作成、issue ID が返される

ユーザー: "チケット SOFT-123 のステータスを「進行中」に更新して"

Claude: [linear.issues.update を使用]

結果: ステータスが変更された
```

**品質スコア**: **7.6/10** ⭐⭐⭐⭐

**注記**: コミュニティメンテナンス（Linear Inc. ではない）ですが、積極的で十分にドキュメント化されています。

**制限**:

| 制限 | 回避策 |
|------------|-----------|
| タイムアウトの問題（1時間後に修正） | ハートビートを実装、ファイアウォールを確認 |
| 65KB フィールド制限 | コメントの自動チャンキング |
| GraphQL の複雑さ | 複雑なクエリを自動分割 |

**代替手段**:

| サーバー | 利点 | 欠点 |
|--------|-----------|--------------|
| **Linear MCP** | モダンな GraphQL、スタートアップ向け | コミュニティメンテナンス |
| Jira MCP | エンタープライズ、複雑なワークフロー | 重い、古い API |
| GitHub Issues | 組み込み、無料 | プロジェクト管理が限定的 |

**リソース**:
- **GitHub**: https://github.com/tacticlaunch/mcp-linear
- **Linear API**: https://developers.linear.app
- **ドキュメント**: https://jan.ai/docs/desktop/mcp-examples/productivity/linear


### オーケストレーション

#### MCP-Compose

Docker Compose スタイルで複数の MCP サーバーを管理する**コミュニティツール**。宣言的 YAML 設定、マルチトランスポートサポート（STDIO/HTTP/SSE）。

**ユースケース**: 開発者が5以上の MCP サーバーを必要とする。Docker Compose のような設定がライフサイクル管理を簡素化。

**主要機能**:

| 機能 | 詳細 |
|------------|---------|
| YAML 設定 | Docker Compose スタイルのサーバー定義 |
| マルチトランスポート | STDIO、HTTP、SSE、TCP サポート |
| コンテナランタイム | Docker、Podman、ネイティブプロセス |
| ネットワーク管理 | 自動 Docker ネットワーク作成 |
| ヘルス監視 | 接続プーリング、セッション管理 |
| HTTP プロキシ | 単一の統合 HTTP エンドポイント |
| ホットリロード | 再起動なしで設定を更新 |

**セットアップ**:

```bash
git clone https://github.com/phildougherty/mcp-compose
cd mcp-compose
cargo build --release
```

**設定**（`mcp-compose.yaml`）:

```yaml
version: "1.0"
mcpServers:
  filesystem:
    command: npx
    args:
      - "@modelcontextprotocol/server-filesystem"
      - "/tmp"
    transport: stdio

  memory:
    command: npx
    args:
      - "@modelcontextprotocol/server-memory"
    transport: stdio
    env:
      DEBUG: "true"

  postgres:
    image: postgres:15
    transport: tcp
    port: 5432
    env:
      POSTGRES_PASSWORD: secret

proxy:
  port: 3000
  listen: "127.0.0.1"
```

**Claude Desktop 設定を生成**:

```bash
./mcp-compose create-config --type claude --output ~/.claude.json
```

**サーバーを起動**:

```bash
./mcp-compose up
# http://localhost:3000 の単一の統合 HTTP プロキシ
```

**品質スコア**: **7.4/10** ⭐⭐⭐⭐

**制限**:

| 制限 | 回避策 |
|------------|-----------|
| Cargo ビルドが必要 | 事前構築バイナリを使用（利用可能な場合） |
| YAML の学習曲線 | 一般的なセットアップのテンプレートを提供 |
| デバッグの複雑さ | トラブルシューティングに `mcp-compose logs` を使用 |

**リソース**:
- **GitHub**: https://github.com/phildougherty/mcp-compose
- **Docker Compose ドキュメント**: https://docs.docker.com/compose/
- **MCP プロトコル仕様**: https://modelcontextprotocol.io


#### Packmind

複数のエージェントとリポジトリにわたってエンジニアリング標準を AI コンテキストとして配布する**コミュニティツール**。Claude Code（または任意の MCP 対応エージェント）から直接プレイブック標準を作成・管理するための MCP サーバーを公開します。

**ユースケース**: エンジニアリングチームが1つのプレイブックを維持。Packmind MCP サーバーにより Claude Code がエディタを離れずにセッション中に新しい標準を提案したり既存のものを更新したりできる。

**主要機能**:

| 機能 | 詳細 |
|------------|---------|
| 標準作成 | MCP ツール経由でプレイブックエントリを作成/更新 |
| マルチエージェント出力 | 1つのソースから CLAUDE.md、.cursor/rules、Copilot 指示を生成 |
| 知識取り込み | GitHub、Slack、Jira、GitLab、Confluence、Notion の MCP サーバー経由でコンテキストをプル |
| セルフホスト | Docker/Kubernetes、Apache-2.0 CLI |

**リソース**:
- **GitHub**: https://github.com/PackmindHub/packmind
- **デモユースケース**: https://github.com/PackmindHub/demo-use-case-skills

> **相互参照**: 完全なツール評価は [third-party-tools.md — エンジニアリング標準の配布](./third-party-tools.md#エンジニアリング標準の配布) を参照。


## 本番デプロイ

### セキュリティチェックリスト

- [ ] **API キー**は設定ファイルではなく `.env` に保存
- [ ] **RBAC/権限**のレビュー（特に Kubernetes、Semgrep）
- [ ] **レート制限**の理解（Linear GraphQL 複雑さ、Vercel API）
- [ ] **フォールバックメカニズム**の実装（API ダウンタイム用）
- [ ] **監視 + ロギング**のすべての MCP サーバーへの有効化

### クイックスタートスタック

**MVP（必須）**:

1. **Playwright MCP** — E2E テスト、Web 検証
2. **Semgrep MCP** — セキュリティファーストコーディング

**重要な追加**:

3. **Context7 MCP** — API リファレンスの精度
4. **Linear MCP**（オプション）— Issue 追跡統合

**DevOps/SRE スタック**:

5. **Kubernetes MCP** — クラスター管理
6. **Vercel MCP** — Next.js デプロイ自動化

**複雑なセットアップ**:

7. **MCP-Compose** — マルチサーバーオーケストレーション
8. **Browserbase MCP** — 重い Web 自動化（プレミアム）

### インストール例

```bash
# Playwright（ブラウザテスト）
npm install @microsoft/playwright-mcp

# Semgrep（セキュリティ）
uvx semgrep-mcp

# Context7（ドキュメント）
npx -y @upstash/context7-mcp --api-key YOUR_API_KEY

# Linear（プロジェクト管理）
npm install mcp-linear
```

### パフォーマンスメトリクス

| メトリクス | 中央値 | 範囲 | 備考 |
|--------|--------|-------|-------|
| **応答時間** | ~200ms | 100〜500ms | クラウド依存（Browserbase ~500ms） |
| **トークンオーバーヘッド** | ~200〜500トークン | 構造化出力に最小限 | アクセシビリティツリー vs スクリーンショット |
| **セットアップ時間** | ~5分 | 2〜10分 | Cargo ビルド（MCP-Compose）= 10分 |


## 月次監視方法論

このセクションでは、月次エコシステム更新でこのガイドを維持するプロセスを文書化します。

### 監視するソース

**公式ソース**:
- [Anthropic MCP GitHub](https://github.com/modelcontextprotocol/servers)
- [Anthropic ブログ](https://www.anthropic.com/news)
- [MCP プロトコル仕様](https://modelcontextprotocol.io)

**コミュニティソース**:
- [GitHub トピック: mcp-servers](https://github.com/topics/mcp-servers)（7260+サーバー）
- [Awesome MCP Servers](https://github.com/punkpeye/awesome-mcp-servers)（75,500スター）
- [MCP レジストリ](https://github.blog/ai-and-ml/generative-ai/how-to-find-install-and-manage-mcp-servers-with-the-github-mcp-registry/)

**ディスカッション**:
- [Reddit r/ClaudeAI](https://www.reddit.com/r/ClaudeAI/)
- [Reddit r/mcp](https://www.reddit.com/r/mcp/)
- [X/Twitter #MCPServer](https://twitter.com/search?q=%23MCPServer)

**技術記事**:
- [Blog Skyvia](https://blog.skyvia.com/best-mcp-servers/)
- [Builder.io ブログ](https://www.builder.io/blog/best-mcp-servers-2026)
- [Cyberpress](https://cyberpress.org/best-mcp-servers/)

### 月次レビューチェックリスト

- [ ] **公式サーバー**: Anthropic GitHub の新しいリリースを確認
- [ ] **コミュニティサーバー**: トレンドサーバーの GitHub トピックをレビュー（スター≥50、リリース3ヶ月以内）
- [ ] **エコシステムの変化**: プロトコル更新のために Anthropic ブログを監視
- [ ] **サーバーの健全性**: 既存サーバーの再評価（リリース、issue、メンテナンス）
- [ ] **セキュリティ**: 開示された脆弱性を確認（GitHub Security Advisories）
- [ ] **廃止**: アーカイブされたまたはメンテナンスされていないサーバーを特定
- [ ] **ガイドの更新**: 新しく検証されたサーバーを追加、廃止されたものを削除

### 評価テンプレート

候補サーバーごとに：

1. **基本検証**:
   - GitHub スター ≥50？
   - 最終リリース 3ヶ月以内？
   - ドキュメント完全（README + 例 + 設定）？
   - テスト/CI あり？

2. **品質スコアリング**（[評価フレームワーク](#評価フレームワーク)を参照）:
   - メンテナンス: `/10`
   - ドキュメント: `/10`
   - テスト: `/10`
   - パフォーマンス: `/10`
   - 採用: `/10`
   - **合計**: `/50` → `/10` に正規化

3. **ユースケース分析**:
   - どのギャップを埋めるか？
   - すでに公式サーバーでカバーされているか？
   - 代替手段は何か？

4. **判断**:
   - **統合**（スコア≥8）: ガイドにフルセクションを追加
   - **監視**（スコア6〜7）: [ウォッチリスト](../../docs/resource-evaluations/watch-list.md)に追加、翌月に再評価
   - **却下**（スコア<6）: [除外されたサーバー](#除外されたサーバー)に理由を文書化

### 統合ワークフロー

新しいサーバーを追加する際：

1. 適切なカテゴリにセクションを作成（ブラウザ自動化、DevOps など）
2. 以下を含める：
   - ユースケース説明
   - 主要機能テーブル
   - セットアップ手順
   - 設定例
   - 品質スコア
   - 制限と回避策
   - 代替手段の比較
   - リソース（GitHub、ドキュメント、チュートリアル）
3. MVP 関連の場合は [クイックスタートスタック](#クイックスタートスタック) を更新
4. セキュリティ重要な場合は [本番デプロイ](#本番デプロイ) チェックリストを更新


## 除外されたサーバー

評価済みだが検証リストに含まれなかったサーバー：

| サーバー | 理由 | ソース | 評価日 |
|--------|--------|--------|----------------|
| **X/Twitter MCP** | API の不安定性、頻繁な認証問題、一貫性のないメンテナンス | [Cursor フォーラム](https://forum.cursor.com/t/linear-mcp-commonly-errors-out-and-requires-turning-off-then-on/148816) | 2026年1月 |
| **Vector Search MCP** | スター50未満、不完全なドキュメント | [LobeHub](https://lobehub.com/mcp/hugoduncan-mcp-vector-search) | 2026年1月 |
| **GitHub MCP** | アーカイブ済み、公式 Go SDK に移行 | [GitHub Changelog](https://github.blog/changelog/2025-12-10-the-github-mcp-server-adds-support-for-tool-specific-configuration-and-more/) | 2026年1月 |
| **Jira MCP（sooperset）** | 最近のリリースなし（最終: 2025年6月）、Linear より安定性が低い | [GitHub リリース](https://github.com/sooperset/mcp-atlassian/releases) | 2026年1月 |


## 統計 & インサイト

### カテゴリ別の分布

| カテゴリ | サーバー数 | ユースケース |
|----------|---------|-----------|
| **ブラウザ自動化** | 3（Playwright、Browserbase、Chrome DevTools） | テスト、デバッグ、データ抽出 |
| **DevOps/インフラ** | 2（Vercel、Kubernetes） | デプロイ、クラスター管理 |
| **セキュリティ/コード分析** | 1（Semgrep） | 脆弱性スキャン、セキュアコーディング |
| **コード検索/分析** | 1（Grepai） | セマンティック検索、コールグラフ分析 |
| **ドキュメント/ナレッジ** | 1（Context7） | API リファレンス、コード例 |
| **プロジェクト管理** | 1（Linear） | Issue 追跡、スプリント計画 |
| **オーケストレーション** | 1（MCP-Compose） | マルチサーバー管理 |

### メンテナーの種類

- **公式サーバー**（6）: Playwright（Microsoft）、Browserbase、Semgrep、Context7、Kubernetes（Red Hat）、Chrome DevTools（Anthropic）
- **コミュニティサーバー**（4）: Linear、Vercel、MCP-Compose、Grepai（適切に設計され、積極的にメンテナンスされている）


**最終更新**: 2026年2月
**次回レビュー**: 2026年3月
**メンテナー**: Claude Code Ultimate Guide チーム


*[メインガイド](./ultimate-guide.md) | [README](./README.md)に戻る*
