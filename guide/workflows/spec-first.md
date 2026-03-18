---
title: "Claudeとの仕様ファースト開発"
description: "構造化された開発のために、実装の前にCLAUDE.mdで仕様を定義する"
tags: [workflow, architecture, config]
---

# Claudeとの仕様ファースト開発

> **信頼度**: Tier 2 — 複数の本番チームによって検証され、公式SDDガイダンスと一致。

Claudeに構築を依頼する**前に**CLAUDE.mdに何を望むかを定義します。一度の構造化されたイテレーションは8回の非構造化イテレーションに相当します。

---

## 目次

1. [要約](#要約)
2. [パターン](#パターン)
3. [タスクの粒度: エージェントに合わせた作業のサイジング](#タスクの粒度-エージェントに合わせた作業のサイジング)
4. [CLAUDE.md仕様テンプレート](#claudemd仕様テンプレート)
5. [ステップバイステップのワークフロー](#ステップバイステップのワークフロー)
6. [ツールとの統合](#ツールとの統合)
7. [使う場面](#使う場面)
8. [アンチパターン](#アンチパターン)
9. [関連情報](#関連情報)

---

## 要約

```
1. CLAUDE.mdに仕様を書く
2. ClaudeがCLAUDE.mdを自動的に読む
3. 実装が仕様に従う
4. 仕様に照らして検証する
```

CLAUDE.mdはあなたの仕様ファイルです。コントラクトとして扱います。

---

## パターン

仕様ファースト開発は典型的なAIコーディングフローを逆転させます:

```
従来:                仕様ファースト:
───────────          ──────────
プロンプト → コード   仕様 → プロンプト → コード → 検証
  │                    │                │       │
  └─ 望むものを        └── コントラクト  └── 仕様に従う
     期待する              定義               └── 仕様に照らして確認
```

仕様は次の信頼できる唯一のソースになります:
- Claudeが構築するものを制約する
- チームの決定を文書化する
- 完全性の検証を可能にする

---

## タスクの粒度: エージェントに合わせた作業のサイジング

仕様を書く前に、タスクが適切なサイズであることを確認します。エージェントは**バーティカルスライス** — すべてのレイヤーを横断するが、正確に1つの完全なユーザー動作を実装する薄いエンドツーエンドの単位（例: 「メールによるパスワードリセット」、「認証システム」ではない）で最もよく機能します。

**経験則**: 1つのエージェントセッション = 1つのバーティカルスライス。タスクの説明が2つのユーザー動作の間に「and」が必要な場合は分割します。

### PRD品質チェックリスト

エージェントにタスクを渡す前にこれを実行します。確認する6つの次元:

| 次元 | 確認すべき質問 | 赤信号 |
|-----------|----------------|----------|
| **問題の明確さ** | 問題の説明は曖昧でないか？ | 「パフォーマンスを改善する」 |
| **テスト可能な基準** | 完了を自動的に検証できるか？ | 「うまく動く」 |
| **スコープの境界** | 明示的にスコープ外になっているものは？ | 除外としてリストされているものがない |
| **観察可能な完了** | ユーザーにとって「完了」はどのように見えるか？ | 内部のみの説明 |
| **要件の明確さ** | 仕様に実装の詳細が含まれていないか？ | 「キャッシュにRedisを使う」 |
| **用語** | 同じ用語が全体で使われているか？ | 「user」と「account」が混在 |

2つ以上の次元で失敗するタスクはエージェントが触れる前に修正が必要です。仕様のレビューは、セッションの途中で誤った実装として表面化する曖昧さを捉えます。

```
❌ 大きすぎる、曖昧:
「アプリにユーザー認証を追加する」

✅ 1つのバーティカルスライス:
「ユーザーはメール+パスワードでログインできる。
- POST /auth/loginは成功時にJWTを返し、失敗時に401を返す
- 無効な認証情報は「メールまたはパスワードが正しくありません」を表示（どちらが違うか教えない）
- セッションは24時間後に期限切れ
- スコープ外: OAuth、パスワードリセット、記憶する機能」
```

---

## CLAUDE.md仕様テンプレート

### 機能仕様（最も一般的）

```markdown
## Feature: [Name]

### Description
[機能の目的を説明する2-3文]

### Capabilities
- MUST: [必須機能]
- MUST: [別の要件]
- SHOULD: [あれば良い]
- MUST NOT: [明示的な除外]

### Tech Stack
- Required: [lib1, lib2, lib3]
- Forbidden: [lib4, lib5]

### Acceptance Criteria
- [ ] 基準1: [具体的なテスト可能な条件]
- [ ] 基準2: [別の条件]
- [ ] 基準3: [エッジケースの処理]

### API Contract（該当する場合）
- Endpoint: POST /api/[resource]
- Request: { field1: string, field2: number }
- Response: { id: string, created: timestamp }
- Errors: 400（バリデーション）、404（見つからない）、500（サーバー）
```

### アーキテクチャ仕様

```markdown
## Architecture: [Component Name]

### Purpose
[このコンポーネントが存在する理由]

### Boundaries
- Owns: [このコンポーネントが責任を持つもの]
- Delegates to: [他のコンポーネントが処理するもの]
- Does NOT: [明示的な非責任]

### Dependencies
- Upstream: [これを呼ぶコンポーネント]
- Downstream: [これが呼ぶコンポーネント]

### Data Flow
```
Input → Validation → Processing → Output
         │              │
         └─ Errors ─────┘
```

### Constraints
- Performance: [レスポンスタイム、スループット]
- Security: [認証要件、データ処理]
- Scalability: [想定負荷、制限]
```

### API仕様

```markdown
## API: [Endpoint Name]

### Endpoint
`POST /api/v1/[resource]`

### Authentication
Bearerトークン必須。スコープ: `read:resource`、`write:resource`

### Request
```json
{
  "field1": "string（必須、最大255文字）",
  "field2": "number（任意、デフォルト: 0）",
  "nested": {
    "subfield": "boolean"
  }
}
```

### Response
```json
{
  "id": "uuid",
  "created_at": "ISO 8601タイムスタンプ",
  "data": { ... }
}
```

### Error Codes
| コード | 意味 | レスポンスボディ |
|------|---------|---------------|
| 400 | バリデーション失敗 | `{ "errors": [...] }` |
| 401 | 未認証 | `{ "message": "..." }` |
| 403 | 権限なし | `{ "message": "..." }` |
| 404 | リソースが見つからない | `{ "message": "..." }` |
```

---

## ステップバイステップのワークフロー

### ステップ1: 仕様を書く

実装リクエストの前に、仕様をCLAUDE.mdに追加します:

```markdown
## Feature: User Authentication

### Capabilities
- MUST: メール/パスワードでのログイン
- MUST: JWTトークンの生成
- MUST: bcryptによるパスワードハッシュ
- SHOULD: 記憶する機能
- MUST NOT: 平文のパスワードを保存する

### Tech Stack
- Required: bcrypt、jsonwebtoken
- Forbidden: passport.js（このユースケースには重すぎる）

### Acceptance Criteria
- [ ] ユーザーが有効な認証情報でログインできる
- [ ] 無効な認証情報が401を返す
- [ ] トークンが24時間後（記憶する場合は7日後）に期限切れ
- [ ] パスワードがコストファクター12でハッシュされる
```

### ステップ2: プロンプトで仕様を参照する

```
Implement the User Authentication feature as specified in CLAUDE.md.
Follow the acceptance criteria exactly.
```

ClaudeはCLAUDE.mdを自動的に読み、仕様に従います。

### ステップ3: 仕様に照らして検証する

実装後に検証します:

```
Review the implementation against the User Authentication spec.
Check off each acceptance criterion that's satisfied.
List any gaps.
```

### ステップ4: 必要に応じて仕様を更新する

実装中に要件が変わった場合:

```
Update the User Authentication spec to include:
- MUST: レート制限（1分あたり5回の試み）
Then implement the rate limiting.
```

---

## ツールとの統合

### Spec Kitとの連携（グリーンフィールド）

```bash
# Spec Kitをインストール
npx @anthropic/spec-kit init

# スラッシュコマンドを使用
/speckit.constitution  # プロジェクトのガードレールを定義
/speckit.specify       # 機能仕様を書く
/speckit.plan          # 実装プランを作成
/speckit.implement     # 仕様から構築
```

### OpenSpecとの連携（ブラウンフィールド）

```bash
# OpenSpecをインストール
npm install -g @fission-ai/openspec@latest
openspec init

# スラッシュコマンドを使用
/openspec:proposal "Add dark mode"  # 変更提案を作成
/openspec:apply add-dark-mode       # 変更を実装
/openspec:archive add-dark-mode     # 仕様にマージ
```

### プランモードとの連携

```
[Shift+Tabを押してプランモードに入る]

I need to implement the Payment Processing feature.
Review the spec in CLAUDE.md and create an implementation plan.
```

---

## 使う場面

### 仕様ファーストを使う場合

| シナリオ | 理由 |
|----------|-----|
| 新機能 | 構築前に定義する |
| APIデザイン | コントラクトは明示的である必要がある |
| アーキテクチャの決定 | 制約を文書化する |
| チームコラボレーション | 共通理解 |
| 複雑な要件 | 曖昧さを減らす |

### 仕様ファーストをスキップする場合

| シナリオ | 理由 |
|----------|-----|
| クイックフィックス | オーバーヘッドが割に合わない |
| 探索 | まだ何が欲しいかわからない |
| プロトタイピング | 要件が変わる |
| 1行の変更 | 意図が明白 |

---

## アンチパターン

### 曖昧な仕様

```markdown
# 間違い
## Feature: User Management
- ユーザーを処理する

# 正しい
## Feature: User Management
### Capabilities
- MUST: メール、パスワード、名前でユーザーを作成する
- MUST: ユーザープロファイルを更新する（名前、アバター）
- MUST: ソフト削除（非アクティブとしてマーク、データは削除しない）
- MUST NOT: メールの重複を許可しない
```

### コードの後に仕様

```
# 間違ったワークフロー
1. Claudeに機能を実装するよう頼む
2. 構築されたものを文書化する仕様を書く

# 正しいワークフロー
1. 構築されるべきものを定義する仕様を書く
2. 仕様からClaudeに実装するよう頼む
```

### 禁止事項を無視する

```markdown
# 除外事項を忘れない
### Tech Stack
- Required: React、TypeScript
- Forbidden: jQuery、バニラJS、クラスコンポーネント
             ↑ これらの制約はドリフトを防ぐ
```

---

## モジュラー仕様デザイン

**パターン**: 大きな仕様を単一のCLAUDE.mdに詰め込む代わりに、複数のフォーカスしたファイルに分割します。

### 問題: モノリシックなCLAUDE.md

仕様が約200行を超えると、いくつかの問題が発生します:

- **コンテキスト汚染**: Claudeは肥大化したコンテキストから関連情報を抽出するのが困難になる
- **認知過負荷**: 開発者が必要なものをすばやくスキャンできない
- **保守の負担**: 1つのエリアを更新するのに無関係なセクションをナビゲートする必要がある
- **パフォーマンス低下**: 大きなCLAUDE.mdファイルはコンテキストの読み込みと処理を遅くする

### 分割するタイミング

| 閾値 | アクション |
|-----------|--------|
| **100行未満** | 単一のCLAUDE.mdで問題なし |
| **100-200行** | 異なるドメインが存在する場合は分割を検討 |
| **200行以上** | **すぐに分割** — 認知負荷の閾値を超えている |
| **マルチチームプロジェクト** | サイズに関係なくドメイン/オーナーシップで分割 |

### 分割戦略

**1. 機能ベースの分割**

```
CLAUDE.md              # コアのプロジェクトコンテキスト
CLAUDE-auth.md         # 認証仕様
CLAUDE-api.md          # APIエンドポイント仕様
CLAUDE-billing.md      # 決済処理仕様
```

**2. ロールベースの分割**

```
CLAUDE.md              # 共有の規約
CLAUDE-frontend.md     # UI/UX仕様
CLAUDE-backend.md      # API/データベース仕様
CLAUDE-infra.md        # DevOps/デプロイ仕様
```

**3. ワークフローベースの分割**

```
CLAUDE.md              # 日常の開発ルール
CLAUDE-testing.md      # テスト仕様
CLAUDE-release.md      # リリースプロセス仕様
CLAUDE-security.md     # セキュリティ要件
```

### 実装パターン

**メインのCLAUDE.md**（簡潔に保つ）:
```markdown
# Project: [NAME]

## Tech Stack
[コアテクノロジー]

## Commands
[日常のコマンド]

## Rules
[ユニバーサルルール]

## Detailed Specs
- Authentication: See @CLAUDE-auth.md
- API Design: See @CLAUDE-api.md
- Testing: See @CLAUDE-testing.md
```

**CLAUDE-auth.md**（フォーカスした仕様）:
```markdown
# Authentication Specification

## Capabilities
- MUST: JWTベースの認証
- MUST: リフレッシュトークンのローテーション
- MUST NOT: localStorageにトークンを保存しない

## API Contract
[詳細な認証エンドポイント...]

## Security Requirements
[具体的な認証セキュリティルール...]
```

**メリット**:
- Claudeは `@CLAUDE-auth.md` で特定のファイルを参照できる
- より速いコンテキスト読み込み（関連する仕様のみ）
- 簡単な保守（他のドメインに影響せずに1つのドメインを編集）
- より良いチームコラボレーション（仕様ファイルごとのオーナーシップ）

**出典**: Addy Osmani、["How to write a good spec for AI agents"](https://addyosmani.com/blog/good-spec/)（2026年1月）

---

## オペレーショナル境界

**パターン**: AIエージェントが自動的に行うべきこと、確認すべきこと、触れてはならないことの明示的な境界を定義します。

### 3層システム

従来の仕様はバイナリ制約（MUST/MUST NOT）を使いますが、オペレーショナルな作業には3つのレベルが必要です:

| 層 | 意味 | Claude Codeのマッピング |
|------|---------|---------------------|
| **Always** | 確認なしに自動的に実行 | 自動承認モード |
| **Ask First** | 進む前にユーザーの確認を得る | デフォルトモード |
| **Never** | ブロックまたはプランモードが必要 | プランモード / フックのブロッキング |

### オペレーショナル境界テンプレート

```markdown
## Boundaries

### Always（自動承認）
- コード変更後にテストを実行
- Prettierでコードをフォーマット
- ファイルを移動する際にインポートを更新
- Lintエラーを修正
- 型のないコードに型アノテーションを追加

### Ask First（確認）
- データベーススキーマを変更する
- 新しい依存関係を追加する
- APIコントラクトを変更する
- 50行以上のコードをリファクタリングする
- 設定ファイルを更新する

### Never（ブロック）
- 本番ブランチにプッシュする
- シークレットやAPIキーをコミットする
- バックアップなしにデータを削除する
- レビューなしにCI/CDワークフローを変更する
- セキュリティチェックをバイパスする
```

### Claude Codeのパーミッションへのマッピング

**Always → パーミッション許可リスト**:
```json
// .claude/settings.json
{
  "permissions": {
    "allow": [
      "Bash(npm test*)",
      "Bash(npx prettier*)",
      "Bash(npx tsc*)"
    ]
  }
}
```

**Ask First → デフォルトモード**:
- 標準的な動作、すべてのアクションでプロンプトを出す
- 中程度のリスク/影響のアクションに使用

**Never → プランモード + フック**:
```bash
# settings.json経由で設定されたフック（PreToolUseイベント）
#!/bin/bash
if [[ "$TOOL_NAME" == "Bash" ]] && [[ "$INPUT" =~ "git push origin main" ]]; then
  echo "BLOCKED: mainへの直接プッシュはブロックされています。フィーチャーブランチを使用してください。"
  exit 2  # Claudeにフィードバックを送る（非ゼロの終了でアクションをブロック）
fi
```

### 判断フレームワーク

各アクションについて自問します:
1. **データ損失を引き起こす可能性があるか？** → Ask FirstまたはNever
2. **gitで元に戻せるか？** → おそらくAlways
3. **他の開発者に影響するか？** → Ask First
4. **セキュリティリスクか？** → Never
5. **標準的なワークフローの一部か？** → Always

### 例: API開発

```markdown
### Always
- ユニットテストを実行する（npm test）
- リクエストスキーマを検証する
- APIドキュメントを生成する
- レスポンス形式を確認する

### Ask First
- 新しいAPIエンドポイントを追加する
- 既存のエンドポイントのシグネチャを変更する
- 認証要件を変更する
- レート制限ルールを更新する

### Never
- 内部エンドポイントを公開する
- 機密ユーザーデータをログに記録する
- 認証チェックを無効にする
- レート制限を削除する
```

### メンテナンス

四半期ごとに境界をレビューします:
- **昇格**: 問題を引き起こさなかったアクション（Ask First → Always）
- **降格**: 問題を引き起こしたアクション（Always → Ask First）
- **ブロック**: 繰り返しのミス（Ask First → Never）

**出典**: Addy Osmani、["How to write a good spec for AI agents"](https://addyosmani.com/blog/good-spec/)（2026年1月）

---

## コマンド仕様テンプレート

**パターン**: 期待される出力とエラー処理を含む実行可能なコマンドを文書化します。

### なぜコマンド仕様が重要か

ほとんどの仕様は**機能**（「認証を構築する」）に焦点を当てていますが、**コマンド**（「認証をテストする方法」）はAIエージェントにとって同様に重要です。

### テンプレート構造

```markdown
## Commands

### [Command Category]

**Purpose**: [このコマンドが何を達成するか]

#### Command: `[実際のコマンド]`
**When**: [トリガー条件]
**Expected Output**: [成功の見た目]
**Error Handling**: [失敗時の対処]
**Flags**: [重要なオプション]

---
```

### 例: テストコマンド

```markdown
## Commands

### Testing

#### Command: `pnpm test`
**When**: すべてのコミットの前、コード変更後
**Expected Output**:
- すべてのテストが通る（終了コード0）
- カバレッジ≥80%（行、ブランチ、関数）
- コンソール警告なし
**Error Handling**:
- テストが失敗する場合 → テストを修正する、スキップしない
- カバレッジが下がる場合 → カバーされていないコードにテストを追加する
- 警告が表示される場合 → コミット前に調査する
**Flags**:
- `--coverage`: カバレッジレポートを生成
- `--watch`: 開発用のウォッチモードで実行
- `--silent`: コンソール出力を抑制

#### Command: `pnpm test:e2e`
**When**: mainへのマージ前、CIパイプライン
**Expected Output**:
- すべてのE2Eシナリオが通る
- 失敗時のスクリーンショットをキャプチャ
- テスト所要時間<5分
**Error Handling**:
- Flakyな場合 → レース条件を調査する、盲目的にリトライしない
- タイムアウトの場合 → ネットワークモック、非同期処理を確認する
- スクリーンショットが異なる場合 → UIの変更を意図的にレビューする
**Flags**:
- `--headed`: 可視ブラウザで実行（デバッグ）
- `--project chromium`: 特定のブラウザをテスト
```

### 例: ビルド&デプロイ

```markdown
## Commands

### Build

#### Command: `pnpm build`
**When**: デプロイ前、CIパイプライン
**Expected Output**:
- ビルド成功（終了コード0）
- `dist/`ディレクトリに出力
- TypeScriptエラーなし
- バンドルサイズ<500KB（メインチャンク）
**Error Handling**:
- TypeScriptエラーの場合 → 型を修正する、`@ts-ignore`は使わない
- バンドルが大きすぎる場合 → `pnpm analyze`で分析し、コード分割する
- アセットが見つからない場合 → public/ディレクトリを確認し、パスを更新する
**Flags**:
- `--mode production`: 本番の最適化
- `--analyze`: バンドルサイズレポートを生成

### Deployment

#### Command: `pnpm deploy:staging`
**When**: PRの承認後、本番前
**Expected Output**:
- デプロイ成功
- ヘルスチェックが200 OKを返す
- ステージングURL: https://staging.example.com
**Error Handling**:
- ヘルスチェックが失敗する場合 → 自動ロールバック
- データベースマイグレーションが失敗する場合 → 続行しない、調査する
- 環境変数が見つからない場合 → .env.stagingを確認し、シークレットを更新する
**Never**: `pnpm deploy:production`は手動で実行しない — CI/CDのみ
```

### CLAUDE.mdとの統合

メインのCLAUDE.mdでコマンド仕様を参照します:

```markdown
## Commands
- Build: `pnpm build`（エラー処理については仕様を参照）
- Test: `pnpm test`（コミット前に通る必要がある）
- Deploy: 完全な手順はCLAUDE-deployment.mdを参照
```

**出典**: Addy Osmani、["How to write a good spec for AI agents"](https://addyosmani.com/blog/good-spec/)（2026年1月）

---

## アンチパターン: モノリシックなCLAUDE.md

### 問題

**症状**: CLAUDE.mdが300行以上に成長し、機能仕様、APIコントラクト、テスト要件、デプロイ手順、チームの規約が混在している。

**影響**:
- **コンテキストの非効率**: Claudeはシンプルなタスクでも300行全部を読み込む
- **応答時間の低下**: 大きなコンテキスト = 処理が遅くなる
- **精度の低下**: 重要な詳細がノイズに埋もれる
- **保守オーバーヘッド**: 1つのセクションを更新するのに無関係なコンテンツをナビゲートする必要がある
- **チームの摩擦**: 複数の開発者が同じファイルを編集する = マージコンフリクト

### 実際の例

**前**（モノリシック）:
```markdown
# CLAUDE.md（387行）

## Tech Stack
[20行]

## Authentication
[45行の認証仕様]

## API Endpoints
[67行のAPIコントラクト]

## Database Schema
[52行のスキーマルール]

## Testing
[38行のテスト要件]

## Deployment
[41行のデプロイ手順]

## Security Rules
[55行のセキュリティ要件]

## Team Conventions
[33行のコーディング標準]

## Git Workflow
[28行のブランチルール]

## Troubleshooting
[8行のよくある問題]
```

**問題**: ユーザーが「ユーザープロファイル用の新しいAPIエンドポイントを追加する」と尋ねても、Claudeは387行全部を読み込む

**後**（モジュラー）:
```
CLAUDE.md（82行）          # コアコンテキスト: テックスタック、コマンド、ルール
CLAUDE-auth.md（45行）     # 認証仕様のみ
CLAUDE-api.md（67行）      # APIコントラクトのみ
CLAUDE-database.md（52行） # データベーススキーマのみ
CLAUDE-testing.md（38行）  # テスト要件のみ
CLAUDE-deploy.md（41行）   # デプロイ手順のみ
CLAUDE-security.md（55行） # セキュリティ要件のみ
```

**メリット**: ClaudeがCLAUDE.md（82行）+ CLAUDE-api.md（67行）= 149行を読み込む（61%削減）

### 分割戦略

**ステップ1: ドメインを特定する**

仕様の自然な境界を探します:
- これらのセクションは異なる目的を果たしているか？
- 異なるチームメンバーが異なるセクションを所有するか？
- 他のセクションよりも頻繁に参照されるセクションはあるか？

**ステップ2: フォーカスしたファイルに抽出する**

ドメイン固有のコンテンツを専用ファイルに移動します:

```bash
# CLAUDE.mdに保持する（常に読み込まれる）
- テックスタック（変わらないベースライン）
- 日常のコマンド（頻繁な参照）
- ユニバーサルルール（すべての作業に適用される）

# ドメインファイルに抽出する（オンデマンドで読み込まれる）
- 機能仕様 → CLAUDE-[feature].md
- APIコントラクト → CLAUDE-api.md
- テスト → CLAUDE-testing.md
- デプロイ → CLAUDE-deploy.md
```

**ステップ3: メインのCLAUDE.mdにインデックスを作成する**

```markdown
# Project: [NAME]

## Tech Stack
[コアテクノロジー]

## Commands
[日常のコマンド]

## Rules
[ユニバーサルルール]

## Detailed Specifications
ドメイン固有の要件については以下のファイルを参照:
- @CLAUDE-auth.md — 認証と認可
- @CLAUDE-api.md — APIエンドポイントコントラクト
- @CLAUDE-database.md — スキーマとマイグレーション
- @CLAUDE-testing.md — テスト要件
- @CLAUDE-deploy.md — デプロイ手順
- @CLAUDE-security.md — セキュリティ要件
```

**ステップ4: 必要なときに参照する**

Claudeは特定のファイルを参照できます:
```
ユーザー: 「ユーザー設定用の新しいAPIエンドポイントを追加する」
Claude: CLAUDE.md + @CLAUDE-api.md を読む（関連するコンテキストのみ）
```

### メンテナンスルール

1. **CLAUDE.mdを100行以下に保つ**（コアコンテキストのみ）
2. **ドメインファイルは各150行以下**（大きすぎる場合はさらに分割）
3. **四半期ごとにレビュー**: あまり使われないファイルをマージ、頻繁に更新されるセクションを分割
4. **@fileリファレンスを使用**: 必要なものを明示的に読み込む

### 移行チェックリスト

- [ ] 現在のCLAUDE.mdのドメインを特定する（200行以上？）
- [ ] ドメイン固有のファイルを作成する（CLAUDE-[domain].md）
- [ ] コンテンツをフォーカスしたファイルに移動する
- [ ] インデックス/リファレンスでメインのCLAUDE.mdを更新する
- [ ] テスト: Claudeにドメイン固有のタスクを実行するよう頼む
- [ ] 確認: `/status` でコンテキストの使用状況を確認する
- [ ] 文書化: チームに新しい構造を伝える

**出典**: Addy Osmani、["How to write a good spec for AI agents"](https://addyosmani.com/blog/good-spec/)（2026年1月）

---

## 関連情報

- [../core/methodologies.md](../core/methodologies.md) — SDDと他の方法論
- [Spec Kitドキュメント](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- [OpenSpecドキュメント](https://github.com/Fission-AI/OpenSpec)
- [tdd-with-claude.md](./tdd-with-claude.md) — TDDとの組み合わせ
- [Spec-to-Code Factory](https://github.com/SylvainChabaud/spec-to-code-factory) — ツール化されたEnforcementを持つ完全なリファレンス実装（Node.js経由の6ゲート、「No Spec No Code」+「No Task No Commit」不変条件、~90万トークン/プロジェクト）
