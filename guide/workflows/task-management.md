---
layout: default
title: "タスク管理ワークフロー"
parent: ワークフロー
grand_parent: ガイド
nav_order: 21
---


# タスク管理ワークフロー

**バージョン**: Claude Code v2.1.16+
**前提条件**: マルチセッションワークフローの理解、基本的なCLI操作スキル
**所要時間**: 習得に15〜30分、複雑なプロジェクト全般に適用可能

## 概要

Claude Codeにおけるタスク管理は、v2.1.16での**Tasks API**導入によって大きく進化しました。これは既存の**TodoWrite**ツールを補完するものです。このワークフローでは、各システムをいつ使うべきか、そして複雑なプロジェクトにおけるマルチセッションタスク調整の活用方法を学びます。

**このワークフローを使う場面:**
- 複数のコーディングセッションにまたがるプロジェクト
- マルチエージェント調整が必要なシナリオ
- 依存関係を持つ複雑なタスク階層
- コンテキストの圧縮やセッション中断後に作業を再開する必要がある場合

**このワークフローを使わない場面:**
- 単一セッションで完結するシンプルな実装
- 素早い修正や探索的なコーディング
- 10分以内に終わるタスク


## システム比較クイックリファレンス

| 機能 | TodoWrite（旧来） | Tasks API（v2.1.16+） |
|------|------------------|----------------------|
| **永続性** | セッションメモリのみ | ディスク保存（`~/.claude/tasks/`） |
| **マルチセッション** | ❌ セッション終了で消滅 | ✅ セッションをまたいで保持 |
| **依存関係** | ❌ 手動による順序管理 | ✅ タスクブロッキング（AがBをブロック） |
| **調整** | 単一エージェント | ✅ ブロードキャスト付きマルチエージェント |
| **ステータス追跡** | pending/in_progress/completed | pending/in_progress/completed |
| **推奨場面** | シンプルな単一セッションのTodo | 複雑なマルチセッションプロジェクト |

**移行フラグ**（v2.1.19+）:
```bash
# 旧システム（TodoWrite）を使用
CLAUDE_CODE_ENABLE_TASKS=false claude

# 新システム（Tasks API）を使用 — v2.1.19以降はデフォルト
claude
```


## ワークフローフェーズ1：タスク計画

**目標**: 複雑な作業を追跡・実行可能な単位に分解する

### ステップ1：スコープの分析

タスクを作成する前に、何を作るかを理解する：

```bash
# ディスカバリーパターン
claude
> "このコードベースをJWT認証実装のために分析してください:
  - 既存の認証パターンをGlobで検索
  - セキュリティ関連のコードをGrepで検索
  - 統合ポイントを特定"
```

### ステップ2：タスク階層の設計

作業を依存関係のある論理的なフェーズに分解する：

**例：認証システム**
```
認証システム（親）
├── 1. ログインエンドポイント（依存なし）
├── 2. トークンリフレッシュ（#1に依存）
├── 3. ログアウトエンドポイント（#1に依存）
└── 4. 統合テスト（#1、#2、#3に依存）
```

### ステップ3：タスク構造の作成

`TaskCreate`を使って計画を具体化する：

```bash
# セッション1：計画フェーズ
export CLAUDE_CODE_TASK_LIST_ID="auth-system-v2"
claude

# Claudeセッション内：
> "JWT認証のタスク階層を作成してください:

  親タスク: 'JWT認証システムを実装する'
  - 説明: リフレッシュトークンとセキュアストレージを用いたJWTベースの認証を追加

  子タスク:
  1. 'ログインエンドポイントの作成'（依存なし）
  2. 'トークンリフレッシュロジックの実装'（タスク1に依存）
  3. 'ログアウトエンドポイントの作成'（タスク1に依存）
  4. '統合テストの作成'（タスク1、2、3に依存）

  TaskCreateに適切なメタデータを付与してください。"
```

**Claudeの出力例:**
```json
{
  "tasks": [
    {
      "id": "task-auth-parent",
      "title": "JWT認証システムを実装する",
      "status": "pending",
      "children": ["task-login", "task-refresh", "task-logout", "task-tests"]
    },
    {
      "id": "task-login",
      "title": "ログインエンドポイントの作成",
      "status": "pending",
      "dependencies": [],
      "metadata": {"priority": "high", "estimated_duration": "2h"}
    },
    {
      "id": "task-refresh",
      "title": "トークンリフレッシュロジックの実装",
      "status": "pending",
      "dependencies": ["task-login"],
      "metadata": {"priority": "high", "estimated_duration": "1h"}
    }
    // ... その他のタスク
  ]
}
```


## ワークフローフェーズ2：タスク実行

**目標**: 進捗を追跡しながらタスクを体系的に実行する

### 実行パターン

```
TaskList → TaskGet（次のpendingタスク）→ 実行 → TaskUpdate → 検証 → 繰り返し
```

### ステップ1：次のタスクを探す

```bash
# セッション2：実装開始
export CLAUDE_CODE_TASK_LIST_ID="auth-system-v2"
claude

> "TaskListで全てのpendingタスクを表示してください"
```

**出力:**
```
'auth-system-v2' のタスク:
✅ task-login: ログインエンドポイントの作成 [completed]
⏳ task-refresh: トークンリフレッシュロジックの実装 [pending, blocked by: none]
⏳ task-logout: ログアウトエンドポイントの作成 [pending, blocked by: none]
⏳ task-tests: 統合テストの作成 [pending, blocked by: task-refresh, task-logout]
```

### ステップ2：タスクの詳細を取得

```bash
> "task-refreshのTaskGetで全要件を確認してください"
```

**出力:**
```json
{
  "id": "task-refresh",
  "title": "トークンリフレッシュロジックの実装",
  "description": "リフレッシュトークンを検証して新しいアクセストークンを発行するエンドポイント POST /auth/refresh を作成する",
  "status": "pending",
  "dependencies": ["task-login"],
  "metadata": {
    "priority": "high",
    "estimated_duration": "1h",
    "files": ["src/auth/refresh.ts", "src/middleware/auth.ts"]
  }
}
```

### ステップ3：実行と更新

```bash
> "task-refreshをin_progressにマークしてから、要件に従ってトークンリフレッシュエンドポイントを実装してください"

# Claudeが実行: TaskUpdate task-refresh status=in_progress
# Claudeが機能を実装...
# 完了後:

> "task-refreshをcompletedにマークしてください"
# Claudeが実行: TaskUpdate task-refresh status=completed
```

### ステップ4：検証

```bash
> "トークンリフレッシュ機能のテストを実行してください"

# テストが通過した場合:
# ✅ タスクはcompletedのまま

# テストが失敗した場合:
> "task-refreshをin_progressに更新し、エラー詳細をメタデータに追加して問題を修正してください"
```


## ワークフローフェーズ3：セッション管理

**目標**: セッションとコンテキスト境界をまたいでシームレスに作業を再開する

### 永続化メカニズム

**ストレージ場所**: `~/.claude/tasks/<task-list-id>/`

タスクは以下をまたいで保持される：
- セッション終了
- コンテキスト圧縮（`/compact`）
- システム再起動
- 数日間の中断

#### ⚠️ フィールド可視性の制限

**TaskListが返すフィールドのみ**: `id`、`subject`、`status`、`owner`、`blockedBy`

**TaskListの出力に含まれない情報**:
- `description`（各タスクごとにTaskGetが必要）
- `metadata`（優先度、見積もりなどのカスタムフィールド）
- `activeForm`（進行状況スピナーのテキスト）

**ワークフローの調整**:

```bash
# NG: 全ての説明をスキャンできると思い込む
TaskList  # 件名のみ表示

# OK: 選択的に取得する
TaskList                    # 概要の確認（タスクの存在確認とステータス）
TaskGet(task-auth-login)    # 特定タスクの詳細を取得
TaskGet(task-auth-tests)    # 次のタスクの詳細を取得
```

**この制限が重要な場面**:
- 詳細なタスク説明を持つ複雑なプロジェクト（タスクあたり50語超）
- 共有コンテキストの可視性が必要なマルチエージェント調整
- 再開ポイントを決めるために全タスクのメモを素早くスキャンしたい場合

**コスト意識**:
- TaskList = APIコール1回
- N個のタスクの説明取得 = 1 + N回のコール
- 20タスクで全説明が必要な場合、20倍のオーバーヘッドが発生

**軽減策**:
- `subject`フィールドに重要情報を入れる（TaskListで見える）
- `description`を簡潔に保つ（最大50〜100語）
- 詳細な計画はマークダウンファイルに保存する（`docs/plan-*.md`）

### 再開パターン

```bash
# 数日後、別のターミナルセッションで
export CLAUDE_CODE_TASK_LIST_ID="auth-system-v2"
claude

> "TaskListで現在の状態を確認してください"

# 出力には中断した時点の状態が正確に表示される:
# ✅ task-login [completed]
# ✅ task-refresh [completed]
# ⏳ task-logout [pending]
# ⏳ task-tests [pending, blocked by: task-logout]

> "ブロックされていない次のpendingタスクを続けてください"
```

### マルチターミナル調整

**ユースケース**: 同一プロジェクトで複数のClaudeインスタンスを実行する

```bash
# ターミナル1：フロントエンド作業
export CLAUDE_CODE_TASK_LIST_ID="auth-system-v2"
claude
> "task-logoutエンドポイントの作業をしてください"

# ターミナル2：テスト作成（同時並行）
export CLAUDE_CODE_TASK_LIST_ID="auth-system-v2"
claude
> "TaskList — 何が完了したかを確認してテストを書きます"

# 両ターミナルはリアルタイムの状態更新を共有
```

**⚠️ 警告**: クロスプロジェクト汚染を避けるため、リポジトリ固有のタスクリストIDを使用してください:
```bash
# ❌ 悪い例：複数のリポジトリで使われる汎用ID
export CLAUDE_CODE_TASK_LIST_ID="my-project"

# ✅ 良い例：コンテキスト付きのリポジトリ固有ID
export CLAUDE_CODE_TASK_LIST_ID="mycompany-api-auth-refactor"
```


## 統合：TDDとタスク管理

テスト駆動開発とタスク追跡を組み合わせて、体系的なテストカバレッジを実現する。

### パターン：テストファーストのタスク実行

```bash
export CLAUDE_CODE_TASK_LIST_ID="tdd-feature-x"
claude

# テストファーストアプローチでタスクを作成
> "機能Xのタスク階層を作成してください:

  各機能コンポーネントに対して:
  1. タスク: '[コンポーネント]の失敗テストを書く'
  2. タスク: 'テストに通る[コンポーネント]を実装する'（#1に依存）
  3. タスク: '[コンポーネント]をリファクタリングする'（#2に依存）

  タスクごとにTDDのred-green-refactorサイクルを使います。"
```

### 例：TDDによるログイン機能

```bash
# フェーズ1：Red（失敗するテスト）
TaskCreate: {
  title: "ログインエンドポイントの失敗テストを書く",
  description: "テストケース: 正常な認証情報、誤ったパスワード、ユーザーが見つからない、レート制限",
  status: "pending"
}

# テスト作成を実行
> "task-login-testsを実装し、最初は全テストが失敗することを確認してください"

# フェーズ2：Green（最小限の実装）
TaskCreate: {
  title: "ログインエンドポイントを実装する（最小限）",
  description: "最もシンプルな実装でテストに通す",
  dependencies: ["task-login-tests"],
  status: "pending"
}

# フェーズ3：Refactor
TaskCreate: {
  title: "ログインエンドポイントをリファクタリングする",
  description: "最適化、重複除去、可読性の向上",
  dependencies: ["task-login-impl"],
  status: "pending"
}
```

**全ワークフローのリファレンス**: [TDD with Claude](tdd-with-claude.md#task-management-integration) を参照


## 統合：プラン駆動開発とタスク管理

戦略的な計画を実行可能なタスク階層に変換する。

### パターン：計画からタスクへの変換

```bash
# ステップ1：プランモードに入る
claude
> [Shift+Tabを押してPlan Modeに入る]

# ステップ2：アーキテクチャ計画を作成
> "マイクロサービス移行のアーキテクチャを設計してください:
  - サービス境界を特定
  - データ移行戦略を計画
  - API契約を設計"

# ステップ3：プランモードを終了してタスクを作成
> "この計画をTaskCreateを使ってタスク階層に変換してください"
```

### 例：マイクロサービス移行

**計画の出力:**
```
フェーズ1：分析（第1週）
- モノリスの依存関係をマッピング
- 境界コンテキストを特定
- サービス境界を設計

フェーズ2：インフラ（第2週）
- サービステンプレートのセットアップ
- APIゲートウェイの設定
- モニタリングの確立

フェーズ3：移行（第3〜6週）
- ユーザーサービスの抽出
- 注文サービスの抽出
- データベーススキーマの移行
```

**タスクへの変換:**
```bash
TaskCreate: {
  title: "マイクロサービス移行",
  children: [
    {
      title: "フェーズ1：分析",
      children: [
        {title: "モノリスの依存関係をマッピング", priority: "critical"},
        {title: "境界コンテキストを特定", dependencies: ["map-deps"]},
        {title: "サービス境界を設計", dependencies: ["bounded-contexts"]}
      ]
    },
    {
      title: "フェーズ2：インフラ",
      dependencies: ["phase-1"],
      children: [
        {title: "サービステンプレートのセットアップ"},
        {title: "APIゲートウェイの設定", dependencies: ["templates"]},
        {title: "モニタリングの確立"}
      ]
    }
    // ... フェーズ3
  ]
}
```

**全ワークフローのリファレンス**: [プラン駆動開発](plan-driven.md#task-hierarchy-design) を参照


## TodoWrite移行ガイド

### 移行すべきタイミング

**TodoWriteのままにする場合:**
- ✅ 全ての作業が1セッションで完了する
- ✅ マルチエージェント調整が不要
- ✅ シンプルな線形タスクリスト（依存関係なし）
- ✅ Claude Code v2.1.16未満を使用

**Tasks APIに移行する場合:**
- ✅ 複数セッションにまたがる作業
- ✅ 数日・数週間にわたるタスクの永続化が必要
- ✅ 複雑な依存関係グラフ
- ✅ マルチターミナルでのコラボレーション
- ✅ コンテキスト圧縮後に再開したい

### 移行手順

#### ステップ1：TodoWriteの使用箇所を特定

```bash
# CLAUDE.mdやワークフロー内のTodoWrite使用箇所を検索
grep -r "TodoWrite" .claude/
```

#### ステップ2：TodoWriteリストをタスクに変換

**変換前（TodoWrite）:**
```markdown
- [ ] ユーザー認証を実装する
- [ ] パスワードハッシュを追加
- [ ] セッション管理を作成
- [ ] テストを書く
```

**変換後（Tasks API）:**
```bash
export CLAUDE_CODE_TASK_LIST_ID="user-auth-2026"
claude

> "タスクを作成してください:
  1. 'ユーザー認証を実装する'（親）
     - 子: 'パスワードハッシュを追加'
     - 子: 'セッション管理を作成'（ハッシュに依存）
     - 子: 'テストを書く'（認証、ハッシュ、セッションに依存）"
```

#### ステップ3：CLAUDE.mdの指示を更新

**変換前:**
```markdown
複雑なタスクの場合:
- TodoWriteでタスクリストを作成
- タスクを順番に実行
```

**変換後:**
```markdown
複雑なタスクの場合:
- CLAUDE_CODE_TASK_LIST_ID=<プロジェクト名>を設定
- TaskCreateで階層的な計画を作成
- TaskUpdateでステータスを追跡しながら実行
- 新しいセッションではTaskListで再開
```

#### ステップ4：移行のテスト

```bash
# テスト用タスクリストを作成
export CLAUDE_CODE_TASK_LIST_ID="migration-test"
claude

> "依存関係のある3つのテストタスクを作成し、1つをcompletedにマークしてから終了してください"

# 新しいセッションで再起動
export CLAUDE_CODE_TASK_LIST_ID="migration-test"
claude

> "TaskList — タスクが正しく永続化されたか確認してください"

# 期待する結果: 正しいステータスで全3タスクが表示される
```


## パターンとアンチパターン

### ✅ 良いパターン

#### 1. 階層的なタスク分解

```bash
プロジェクト（親）
└── 機能A（プロジェクトの子）
    ├── コンポーネントA1（機能Aの子）
    │   ├── 実装（リーフタスク）
    │   └── テスト（リーフタスク、実装に依存）
    └── コンポーネントA2
        └── ...
```

**効果的な理由**: 自然なプロジェクト構造を反映し、依存関係を明示的にする

#### 2. 依存関係優先の順序付け

```bash
# タスク作成時は常に依存関係を定義する
TaskCreate: {
  title: "本番環境にデプロイ",
  dependencies: ["run-tests", "code-review", "backup-database"],
  metadata: {blocking_reason: "安全確認が必要"}
}
```

**効果的な理由**: 早まった実行を防ぎ、品質ゲートを強制する

#### 3. 細かいステータス更新

```bash
# 悪い例: 大きなタスクを中間更新なしにcompletedにする
TaskCreate: {title: "認証システム全体を構築"}
# ... 数時間後 ...
TaskUpdate: {id: "auth-system", status: "completed"}

# 良い例: 作業の進行に合わせて頻繁にステータスを更新する
TaskUpdate: {id: "auth-system", status: "in_progress", progress: "25%"}
TaskUpdate: {id: "auth-system", status: "in_progress", progress: "50%"}
TaskUpdate: {id: "auth-system", status: "in_progress", progress: "75%"}
TaskUpdate: {id: "auth-system", status: "completed"}
```

**効果的な理由**: 可視性を高め、コンテキストを考慮した再開を可能にする

#### 4. メタデータが豊富なタスク

```bash
TaskCreate: {
  title: "データベースクエリを最適化する",
  description: "ユーザーダッシュボードのクエリ時間を2秒から200ms未満に削減",
  metadata: {
    priority: "high",
    estimated_duration: "3h",
    related_files: ["src/db/queries.ts", "src/db/indexes.sql"],
    performance_baseline: "2000ms",
    performance_target: "200ms",
    related_issue: "https://github.com/org/repo/issues/123"
  }
}
```

**効果的な理由**: 再開時にコンテキストが豊富で、委譲が容易で、ドキュメントとして優れている

### ❌ アンチパターン

#### 1. モノリシックなタスク（10ステップ超）

```bash
# ❌ 悪い例: タスクが大きすぎて進捗を追跡しにくい
TaskCreate: {
  title: "決済システム全体を実装する",
  description: "Stripe統合、Webhook、返金、異議申し立て、レポート、管理UI、..."
}

# ✅ 良い例: フェーズに分割する
TaskCreate: {
  title: "決済システム — フェーズ1: コア統合",
  children: [
    {title: "Stripe SDKセットアップ"},
    {title: "支払いインテントの作成"},
    {title: "Webhookハンドリング"}
  ]
}
```

#### 2. 依存関係の欠如

```bash
# ❌ 悪い例: タスクが誤った順序で実行される可能性がある
TaskCreate: {title: "本番環境にデプロイ"} # 依存関係なし
TaskCreate: {title: "テストを書く"} # 依存関係なし

# ✅ 良い例: 明示的な順序付け
TaskCreate: {
  title: "本番環境にデプロイ",
  dependencies: ["write-tests", "run-tests", "code-review"]
}
```

#### 3. コンテキストのない孤立したタスク

```bash
# ❌ 悪い例: 将来の自分には意味が分からない
TaskCreate: {
  title: "バグを修正する",
  description: "昨日のやつ"
}

# ✅ 良い例: 自己完結したコンテキスト
TaskCreate: {
  title: "Safariのログインタイムアウトを修正する",
  description: "Safari 17.2+のユーザーが5分後にセッションタイムアウトする。期待値: 30分タイムアウト。根本原因: SameSite=StrictのCookieがサポートされていない。",
  metadata: {
    browser: "Safari 17.2+",
    error_message: "セッションが切れました",
    related_commit: "a1b2c3d",
    slack_thread: "https://slack.com/archives/C123/p456"
  }
}
```

#### 4. ステータスの不整合

```bash
# ❌ 悪い例: テストが失敗しているのにタスクをcompletedにする
TaskUpdate: {id: "login-feature", status: "completed"}
# 後でテスト実行: 3件の失敗

# ✅ 良い例: 完了前に検証する
> "ログイン機能のテストを実行してください"
# テストが通過した場合:
TaskUpdate: {id: "login-feature", status: "completed", metadata: {test_results: "pass"}}
# テストが失敗した場合:
TaskUpdate: {id: "login-feature", status: "in_progress", metadata: {test_results: "3件の失敗", error_log: "..."}}
```


## トラブルシューティング

### Q: セッションをまたいでタスクが保持されない

**症状**: Claudeを再起動後、`TaskList`が空を返す

**解決策**:
```bash
# 起動前にCLAUDE_CODE_TASK_LIST_IDが設定されていることを確認
export CLAUDE_CODE_TASK_LIST_ID="your-project-name"
claude

# ストレージディレクトリの存在を確認
ls ~/.claude/tasks/your-project-name/
```

### Q: 複数のプロジェクトがタスクリストを共有している

**症状**: プロジェクトBの作業中にプロジェクトAのタスクが表示される

**原因**: 異なるリポジトリで同じタスクリストIDを使用している

**解決策**:
```bash
# リポジトリ固有のIDとコンテキストを使用する
cd ~/projects/api
export CLAUDE_CODE_TASK_LIST_ID="api-v2-migration"
claude

cd ~/projects/frontend
export CLAUDE_CODE_TASK_LIST_ID="frontend-redesign"
claude
```

### Q: Tasks APIの代わりにTodoWriteが使われる

**症状**: タスクリストIDを設定してもタスクが永続化されない

**原因**: 環境に`CLAUDE_CODE_ENABLE_TASKS=false`が設定されている

**解決策**:
```bash
# 環境変数を確認
env | grep CLAUDE_CODE_ENABLE_TASKS

# 存在する場合は解除
unset CLAUDE_CODE_ENABLE_TASKS

# または明示的に有効化（v2.1.19+ではデフォルトで有効）
export CLAUDE_CODE_ENABLE_TASKS=true
```

### Q: タスクの依存関係が強制されない

**症状**: 依存関係が完了する前にClaudeがブロックされたタスクを実行する

**原因**: TaskCreateで依存関係が適切に定義されていない

**解決策**:
```bash
# 依存関係に正しいタスクIDを使用する
TaskCreate: {
  title: "タスクB",
  dependencies: ["task-a-id"], # ✅ 実際のタスクIDを使用
  # NOT dependencies: ["タスクA"] # ❌ タスクタイトルは機能しない
}

# 依存関係を確認:
TaskGet task-b-id
# 表示されるべき: "blockedBy": ["task-a-id"]
```


## 上級：カスタムタスクメタデータ

ワークフローを強化するためにドメイン固有のメタデータでタスクを拡張する。

### メタデータの規則

**パフォーマンス最適化タスク:**
```json
{
  "metadata": {
    "type": "performance",
    "baseline_metric": "2000ms",
    "target_metric": "200ms",
    "profiling_tool": "Chrome DevTools",
    "measurement_location": "ダッシュボード読み込み時間"
  }
}
```

**セキュリティタスク:**
```json
{
  "metadata": {
    "type": "security",
    "severity": "critical",
    "cve_id": "CVE-2024-1234",
    "affected_versions": "< 2.1.0",
    "mitigation": "パッケージXをv3.0+に更新"
  }
}
```

**バグ修正タスク:**
```json
{
  "metadata": {
    "type": "bugfix",
    "issue_url": "https://github.com/org/repo/issues/456",
    "reported_by": "user@example.com",
    "reproduction_steps": "1. ログイン 2. ダッシュボードに移動 3. エクスポートをクリック",
    "error_message": "TypeError: Cannot read property 'map' of undefined"
  }
}
```

### メタデータによるクエリ

```bash
# タイプ別にタスクをフィルタリング（スクリプトが必要、組み込みではない）
TaskList | jq '.tasks[] | select(.metadata.type == "security")'

# 優先度が高いpendingタスクを検索
TaskList | jq '.tasks[] | select(.metadata.priority == "high" and .status == "pending")'
```


## 関連ワークフロー

- **[TDD with Claude](tdd-with-claude.md)** — タスク追跡によるテストファースト開発
- **[プラン駆動開発](plan-driven.md)** — 戦略的計画からタスク階層へ
- **[反復的改善](iterative-refinement.md)** — タスクによるインクリメンタルな改善
- **[探索ワークフロー](exploration-workflow.md)** — タスク作成前のディスカバリーフェーズ


## リファレンス

**ツールドキュメント**: [Ultimate Guide セクション5.X](../ultimate-guide.md#5x-task-management-system) を参照

**出典:**
- 公式: [Claude Code CHANGELOG v2.1.16](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)
- 公式: [System Prompts - TaskCreate](https://github.com/Piebald-AI/claude-code-system-prompts)
- コミュニティ: [paddo.dev - From Beads to Tasks](https://paddo.dev/blog/from-beads-to-tasks/)
- コミュニティ: [llbbl.blog - Two Changes in Claude Code](https://llbbl.blog/2026/01/25/two-changes-in-claude-code.html)

**バージョン追跡**: このワークフローはClaude Code v2.1.16+（2026-01-22リリース）を対象としています。最新の変更は [claude-code-releases.yaml](../../machine-readable/claude-code-releases.yaml) で確認してください。
