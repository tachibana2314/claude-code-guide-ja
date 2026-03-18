---
layout: default
title: "Claude CodeのGitHub Actionsワークフロー"
parent: ワークフロー
grand_parent: ガイド
nav_order: 9
---


# Claude CodeのGitHub Actionsワークフロー

> **信頼度**: Tier 1 — Anthropicの公式アクション（`anthropics/claude-code-action`、スター6.2k、v1.0）。

`@claude`メンションと、スケジュール/イベント自動化（完全自律）の2つのトリガーモデルで、コードレビュー、イシューのトリアージ、品質ゲートを自動化します。


## 目次

1. [要約](#要約)
2. [2つのモデル](#2つのモデル)
3. [セットアップ](#セットアップ)
4. [パターン1: @claudeメンションによるPRコードレビュー](#パターン1-claudeメンションによるprコードレビュー)
5. [パターン2: プッシュ時の自動PRレビュー](#パターン2-プッシュ時の自動prレビュー)
6. [パターン3: イシューのトリアージとラベリング](#パターン3-イシューのトリアージとラベリング)
7. [パターン4: セキュリティ重視のレビュー](#パターン4-セキュリティ重視のレビュー)
8. [パターン5: スケジュールされたリポジトリメンテナンス](#パターン5-スケジュールされたリポジトリメンテナンス)
9. [認証の代替手段](#認証の代替手段)
10. [コスト制御](#コスト制御)
11. [セキュリティチェックリスト](#セキュリティチェックリスト)
12. [関連情報](#関連情報)


## 要約

```yaml
# 最小限の動作例 — .github/workflows/claude.ymlに貼り付け
name: Claude Code Review
on:
  issue_comment:
    types: [created]

jobs:
  claude:
    if: contains(github.event.comment.body, '@claude')
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
      issues: write
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

任意のPRで`@claude review this PR`とコメントする → ClaudeがdiffをreadしてレビューをPostする。


## 2つのモデル

| モデル | トリガー | ユースケース |
|-------|---------|----------|
| **インタラクティブ** | PR/イシューコメントでの`@claude`メンション | オンデマンドレビュー、質問、修正 |
| **自動化** | プッシュ、PRオープン、スケジュール、ラベル | 継続的な品質ゲート、トリアージ |

どちらも同じアクションを使います — 違いは`on:`ブロックと`if:`条件を含めるかどうかです。


## セットアップ

### クイックスタート（30秒）

GitHubリポジトリに接続された任意のプロジェクトのClaude Codeターミナルで:

```
/install-github-app
```

GitHub Appの作成、リポジトリシークレットへの`ANTHROPIC_API_KEY`の追加、ベースの`claude.yml`ワークフローの生成をガイドします。

### 手動セットアップ

1. GitHubリポジトリシークレットに`ANTHROPIC_API_KEY`を追加
2. `.github/workflows/claude.yml`を作成（以下のパターンを参照）
3. ワークフローに権限を付与: `contents: write`、`pull-requests: write`、`issues: write`


## パターン1: @claudeメンションによるPRコードレビュー

人間が開始するレビュー。開発者が`@claude review this PR`とコメントするとClaudeがインラインで応答します。

```yaml
# .github/workflows/claude-review.yml
name: Claude Interactive Review
on:
  issue_comment:
    types: [created, edited]
  pull_request_review_comment:
    types: [created]

jobs:
  claude:
    if: |
      contains(github.event.comment.body, '@claude') ||
      contains(github.event.review_comment.body, '@claude')
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
      issues: write
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          claude_env: |
            GITHUB_TOKEN=${{ secrets.GITHUB_TOKEN }}
```

**使用例:**
- `@claude review this PR` — 提案を含む完全なdiff分析
- `@claude is this change backwards compatible?` — ターゲットを絞った質問
- `@claude fix the failing test in src/auth.test.ts` — Claudeが修正を含むフォローアップPRを開く


## パターン2: プッシュ時の自動PRレビュー

すべてのPRがオープンまたは更新された瞬間にレビューを受けます。メンションは不要です。

```yaml
# .github/workflows/claude-auto-review.yml
name: Claude Auto PR Review
on:
  pull_request:
    types: [opened, synchronize]
    # 任意: 特定のパスのみにトリガー
    # paths:
    #   - 'src/**'
    #   - '!**/*.md'

jobs:
  claude-review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            このプルリクエストをレビューしてください。以下に焦点を当ててください:
            - ロジックエラーとエッジケース
            - セキュリティ問題（インジェクション、認証、シークレット）
            - パフォーマンスのリグレッション
            - エラーハンドリングの欠如

            レスポンスを以下のフォーマットにしてください:
            ## Summary
            変更を説明する1段落。

            ## Issues Found
            番号付きリスト、重大度（Critical/Major/Minor）、file:line参照。

            ## Suggestions
            任意の改善提案。

            400語以下に抑えてください。直接的に。
```

**ヒント**: `paths:`を追加してドキュメントのみのPRでのトリガーを回避するか、`if: github.event.pull_request.draft == false`を追加してドラフトをスキップしてください。


## パターン3: イシューのトリアージとラベリング

Claudeが新しいイシューを読み込み、ラベルを割り当て、構造化されたトリアージコメントを投稿します。

```yaml
# .github/workflows/claude-triage.yml
name: Issue Triage
on:
  issues:
    types: [opened]

jobs:
  triage:
    runs-on: ubuntu-latest
    permissions:
      issues: write
      contents: read
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            このGitHubイシューをトリアージしてください:

            1. 以下から1つのラベルを割り当てる: bug、enhancement、question、documentation、performance、security
            2. 優先度ラベルを割り当てる: priority:critical、priority:high、priority:medium、priority:low
            3. 以下を含むコメントを投稿する:
               - イシューのタイプ分類
               - 影響を受けそうなコンポーネント（イシューの説明に基づく）
               - 報告者への次のステップの推奨（再現手順が必要？バージョン情報が不足？）

            簡潔にしてください。ポイントごとに1文。
```


## パターン4: セキュリティ重視のレビュー

機密パス（認証、決済、設定）に触れるPRに対して特別に実行します。

```yaml
# .github/workflows/claude-security.yml
name: Security Review
on:
  pull_request:
    paths:
      - 'src/auth/**'
      - 'src/payments/**'
      - '**/config/**'
      - '**/.env*'
      - '**/secrets/**'

jobs:
  security-review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            このPRのセキュリティ重視のレビューを行ってください。以下を確認:

            - インジェクション脆弱性（SQL、コマンド、LDAP）
            - 認証と認可のバイパス
            - コードまたはコメントのシークレットや認証情報
            - 安全でない直接オブジェクト参照
            - 入力検証の欠如
            - 安全でないデシリアライゼーション
            - OWASP Top 10のパターン

            全体的なリスクを評価する: Low / Medium / High / Critical。
            HighまたはCriticalの場合は'security-review-required'ラベルを追加。
            各調査結果をリスト: file:line、脆弱性タイプ、推奨される修正。
```


## パターン5: スケジュールされたリポジトリメンテナンス

週次のヘルスチェック — 人間のトリガーなしで実行されます。

```yaml
# .github/workflows/claude-maintenance.yml
name: Weekly Repo Health Check
on:
  schedule:
    - cron: '0 9 * * 1'  # 毎週月曜日 UTC午前9時
  workflow_dispatch:       # 手動トリガーも許可

jobs:
  maintenance:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      issues: write
    steps:
      - uses: actions/checkout@v4

      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            週次リポジトリヘルスチェックを実行してください:

            1. package.json（または同等のもの）で古いメジャー依存関係をスキャン
            2. src/内の30日以上経ったTODO/FIXMEコメントを確認
            3. 対応する実装ファイルのないテストファイルを特定
            4. 削除または名前変更されたファイルを参照するドキュメントファイルをリストアップ

            「Weekly Health Check - [日付]」というタイトルのGitHubイシューを調査結果とともに開いてください。
            注意が必要なものがない場合は「Health check passed — no issues found.」とコメントしてください。
```


## 認証の代替手段

上記の例では直接`ANTHROPIC_API_KEY`を使用しています。クラウドプロバイダーを使用するチームは:

**Amazon Bedrock:**
```yaml
- uses: anthropics/claude-code-action@v1
  with:
    use_bedrock: 'true'
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    AWS_REGION: us-east-1
    ANTHROPIC_MODEL: 'anthropic.claude-3-5-sonnet-20241022-v2:0'
```

**Google Vertex AI:**
```yaml
- uses: anthropics/claude-code-action@v1
  with:
    use_vertex: 'true'
  env:
    ANTHROPIC_VERTEX_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
    CLOUD_ML_REGION: us-east5
    ANTHROPIC_MODEL: 'claude-3-5-sonnet-v2@20241022'
```

クラウドプロバイダーはデータレジデンシーコンプライアンスから恩恵を受け、別のAPIキーを管理する代わりに既存のIAMポリシーを活用できます。


## コスト制御

自動化されたワークフローは人間がループに入らずに実行されます — 明示的な制限を設定してください。

```yaml
- uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    # ワークフロー実行ごとの支出を上限設定
    claude_args: '--max-budget-usd 0.50'
    # トリアージにはHaiku、レビューにはSonnetを使用 — Opusをデフォルトにしない
    prompt: |
      ...
```

**パターン別の予算ガイドライン:**

| パターン | モデル | 約コスト/実行 |
|---------|-------|--------------------|
| PRレビュー（中程度のPR） | Sonnet | $0.05〜0.15 |
| イシューのトリアージ | Haiku | $0.01〜0.03 |
| セキュリティレビュー（大きなPR） | Sonnet | $0.10〜0.25 |
| スケジュールされたメンテナンス | Sonnet | $0.05〜0.20 |

`ccusage`またはAnthropicコンソールの使用量ダッシュボードで実際の支出を監視してください。

**コストの暴走を防ぐ:**
- 無関係な変更でのトリガーを避けるために`paths:`フィルターを使用
- ドラフトPRをスキップするために`if: github.event.pull_request.draft == false`を追加
- 同じPRでの並列実行を防ぐために`concurrency:`を設定

```yaml
jobs:
  claude-review:
    concurrency:
      group: claude-${{ github.event.pull_request.number }}
      cancel-in-progress: true
```


## セキュリティチェックリスト

チームリポジトリにデプロイする前に:

- [ ] `ANTHROPIC_API_KEY`はGitHubシークレットとして保存、ワークフローYAMLには含まない
- [ ] ワークフローの権限は最小限 — 書き込みが必要でない限り`contents: read`を使用
- [ ] パブリックリポジトリの場合: フォークのPRがAPIコールをトリガーするのを防ぐために`if: github.event.pull_request.head.repo.full_name == github.repository`を追加
- [ ] ワークフローが公開するものをレビュー — Claudeのコメントはすべてのコントリビューターに見える
- [ ] `pull_request_target`は注意して使用 — フォークからでも書き込み権限で実行される

**フォーク安全パターン（パブリックリポジトリ）:**
```yaml
jobs:
  claude:
    # 同じリポジトリからのPRのみ実行、フォークではない
    if: github.event.pull_request.head.repo.full_name == github.repository
```


## 関連情報

- [セクション9.3 CI/CDインテグレーション](../ultimate-guide.md#93-cicd-integration) — ヘッドレスモード、Unixパイプ、`--output-format json`
- [本番安全性](../security/production-safety.md) — 自動化エージェントのガードレール
- [セキュリティ強化](../security/security-hardening.md) — MCPとウェブフックのセキュリティ
- [公式アクションドキュメント](https://github.com/anthropics/claude-code-action) — ソリューションガイド、移行、クラウドプロバイダー
- [コミュニティワークフローブループリント](https://github.com/alirezarezvani/claude-code-github-workflow) — 高度なチーム向けの8つのワークフロー + 4つの自律エージェント
