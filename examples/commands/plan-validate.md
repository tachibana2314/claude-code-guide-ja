---
layout: default
title: "Plan Validate — 2層の検証"
parent: コマンド
grand_parent: テンプレート
nav_order: 17
---


# Plan Validate — 2層の検証

`/plan-start` で生成されたプランを独立して検証します。コードは書きません。このコマンドの後に `/plan-execute` を実行する前に `/clear` を実行してください。

検証は計画から分離されています: プランを書いていない検証者はその前提に縛られていません。


## 前提条件

コミット済みのプランファイルが `docs/plans/plan-{name}.md` に存在している必要があります。複数のプランが存在する場合、どれを検証するかユーザーに確認します。


## 第1層: 構造的検証

即座に実行、エージェント不要。プランドキュメントを確認します:

**フォーマット & 完全性**
- [ ] 必要なセクションがすべて存在する（Summary、Decisions、Architecture、Tasks、Test Plan、Out of Scope）
- [ ] 各タスクに: 説明、影響を受けるファイル、受け入れ基準、レイヤー割り当てがある

**依存関係チェーン**
- [ ] タスク間に循環依存がない
- [ ] 上位レイヤーのタスクが下位レイヤーのタスクにのみ依存している
- [ ] 記述されたすべての依存関係がプランに存在する

**ファイルの存在**
- [ ] 変更するとして記載されたすべてのファイルがコードベースに実際に存在する（Glob を使用）
- [ ] 新しいファイルがプロジェクト規約に従った適切なディレクトリにある

**ADR の整合性**
- [ ] プランの決定が `/plan-start` 中に作成された ADR と一致している
- [ ] `docs/adr/` 内の既存 ADR と矛盾していない

**CLAUDE.md コンプライアンス**
- [ ] プランが CLAUDE.md のすべての厳格なルールを守っている
- [ ] ファーストプリンシプルの違反がない（回避策なし、後方互換性のシムなし）

**テストカバレッジ**
- [ ] すべての新しい関数/コンポーネントに対応するテストタスクがある
- [ ] TDD マークされたタスクに実装タスクの前に書かれた失敗テストがある

第2層に進む前に、すべての第1層の問題を重大度（BLOCKER / WARNING / INFO）と共に記録します。


## 第2層: 専門家レビュー

プランの内容にトリガールールを適用してエージェントを選択します。ユーザーの入力は不要 — トリガーは客観的です。

**検証エージェントプール:**

| エージェント | トリガー | モデル |
|-------|---------|-------|
| `security-reviewer` | 認証、決済、PII、RBAC、新しいパブリック API | Opus |
| `db-migration-reviewer` | 新しいテーブル、カラム、インデックス、マイグレーションファイル | Opus |
| `performance-reviewer` | 新しいクエリ、リゾルバー、ルート、または追加の依存関係 | Sonnet |
| `design-system-reviewer` | 新しい UI コンポーネントまたはビジュアルスタイリングの変更 | Sonnet |
| `ux-reviewer` | 新しいページ、フォーム、モーダル、またはインタラクションパターン | Sonnet |
| `cross-platform-reviewer` | web とモバイルの両方、または共有パッケージに触れる変更 | Sonnet |
| `native-app-reviewer` | モバイル画面、ネイティブ UI パッケージの変更 | Sonnet |
| `integration-reviewer` | 新しい外部サービス、ライブラリ、OTEL 設定 | Opus |

トリガーされたエージェントを並列にスポーン（Task ツール、run_in_background: true）。各エージェントが受け取るもの: プランファイル、関連 ADR、ドメインに基づいた的を絞った質問。

TaskOutput ポーリングループで監視します。ユーザーに進捗を報告します。

各エージェントは構造化された所見を返す必要があります:
```
FINDING: [BLOCKER|WARNING|INFO]
Location: [plan section or file reference]
Issue: [concrete description]
Risk: [what breaks if this isn't addressed]
Suggestion: [specific fix or alternative]
```


## 自動修正フェーズ

第1層の構造的問題 + 第2層の専門家所見を単一の問題リストにまとめます。すべての問題を解決する必要があります。スキップ不可。

**各問題をトリアージ:**

**バケット A — 自動解決:**
- 問題が既存の ADR 決定と一致する → ADR を引用、解決済みとしてマーク
- 問題が PATTERNS.md の確認済みパターンと一致する → パターンを引用、解決済みとしてマーク
- 問題が CLAUDE.md のファーストプリンシプルから解決可能 → ルールを適用、解決済みとしてマーク

**バケット B — 人間の入力が必要:**
- 既存の決定でカバーされていない新しいアーキテクチャの質問
- 明確な先例がない矛盾する ADR
- 明白な解決策のないブロッカー

バケット B の項目について: 問題を提示し、自動解決できない理由を説明し、オプションを提案し、決定を待ちます。決定をプランの `## Decisions` セクションに記録し、アーキテクチャ的に重要な場合は新しい ADR を作成します。

**すべての問題がトリアージされたら一括で修正を適用**します。プランファイルを更新します。更新されたプランをコミット。


## 問題の永続化

`docs/plans/metrics/{name}.json` の `validation.issues` にすべての問題を記録します:

```json
{
  "id": "S-001",
  "layer": 1,
  "severity": "WARNING",
  "category": "test-coverage",
  "description": "新しい Webhook ハンドラーのテストタスクがない",
  "reporting_agent": "structural",
  "triage": "A",
  "resolution_source": "first-principles",
  "resolution": "プランのレイヤー 2 にテストタスクを追加"
}
```

このデータは `/plan-metrics` が時間の経過によるパターン分析に使用します。


## 自動遷移

すべての問題が自動解決された場合（バケット A のみ）: 確認なしで `/plan-execute` を自動開始。

人間の入力が必要だった場合（バケット B）: 先に進む前に「すべての問題が解決されました。実行しますか？」と確認。


## 使用法

```
/plan-validate
```

最新のコミットされていないプランを自動的に取得します。または指定:

```
/plan-validate plan-user-authentication
```

## 出力

```
Layer 1: Structural validation...
  ✓ Format complete
  ✓ Dependencies valid
  ⚠ WARNING S-001: Missing test task for webhook handler
  ✓ CLAUDE.md compliant

Layer 2: Triggering specialist agents...
  → security-reviewer (auth changes detected) [Opus]
  → db-migration-reviewer (new users table) [Opus]
  → performance-reviewer (new query in /api/users) [Sonnet]
  Monitoring... 1/3 complete... 2/3 complete... done.

  BLOCKER B-001 [security-reviewer]: JWT expiry not validated on refresh endpoint
  WARNING B-002 [db-migration-reviewer]: Migration lacks rollback strategy

Auto-fix phase:
  S-001 → auto-resolved (first principles: test coverage rule)
  B-001 → NEEDS INPUT (no existing ADR for JWT refresh strategy)
  B-002 → auto-resolved (ADR-0003: migration rollback pattern)

[User input requested for B-001]
Decision recorded. ADR-0011 created.

All 3 issues resolved. Plan updated.
→ Auto-starting /plan-execute
```

## 使用するタイミング

常に — 任意の `/plan-execute` 呼び出しの前に。検証のコスト（$0.20-3.00）は、実行中に問題を発見するコストに比べれば無視できます。

## 参照

- [Plan-Validate-Execute パイプライン](../../guide/workflows/plan-pipeline.md)
- [Integration Reviewer エージェント](../agents/integration-reviewer.md)
- [Plan Challenger エージェント](../agents/plan-challenger.md)
