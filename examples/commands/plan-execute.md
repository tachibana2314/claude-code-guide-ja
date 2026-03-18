---
layout: default
title: "Plan Execute — マージされた PR までの実行"
parent: コマンド
grand_parent: テンプレート
nav_order: 15
---


# Plan Execute — マージされた PR までの実行

分離された worktree で検証済みプランを実行します。タスクごとにエージェントをスポーン、品質を確認、PR を作成してマージします。クリーンアップまですべてを処理します。

このコマンドの前に `/clear` を実行してください。


## 前提条件

検証済みのプランが `docs/plans/plan-{name}.md` にすべての問題を解決済みの状態（`/plan-validate` の出力）で存在している必要があります。


## ステップ 1: Worktree のセットアップ

分離された git worktree を作成します:

```bash
git worktree add .worktrees/{plan-name} -b feature/{plan-name}
```

すべての実行は worktree 内で行います。メインブランチは常にクリーンな状態を維持します。


## ステップ 2: TDD スキャフォールディング

*プランで TDD とマークされたタスクのみ。*

各 TDD タスクについて、実装前に:
1. 受け入れ基準を定義する失敗テストを書く
2. テストを実行して失敗を確認（赤）
3. 失敗テストをコミット
4. 実装エージェントが見つけられるようにタスクのテストファイルをマークする

このステップでは実装コードを書かない。


## ステップ 3: レベルベースの並列実行

プランからタスクリストを解析します。レイヤーでタスクをグループ化します（レイヤー1 = 基盤、レイヤー2 = レイヤー1に依存、など）。

**各レイヤーについて:**
1. レイヤー内のすべてのタスクを特定
2. タスクごとに1つのエージェントを並列でスポーン（Task ツール、run_in_background: true）
3. 各エージェントが受け取るもの: タスクの説明、変更するファイル、受け入れ基準、関連 ADR
4. TaskOutput ポーリングループですべてのエージェントを監視
5. 各エージェントはタスク完了時にコミット: `git commit -m "feat: {task-description}"`
6. 次のレイヤーを開始する前にレイヤー内のすべてのタスクの完了を待つ

**ドリフト検出**: 各レイヤーの後、実際の変更とプランの仕様を差分比較します。実装がプランから大きく逸脱している場合（プランにないファイル、触れていないプランのファイル）、フラグを立てて続行方法を確認します。サイレントに続行しない。

**各タスクのエージェント指示:**
```
あなたは検証済みプランから1つのタスクを実装しています。
タスク: {説明}
変更するファイル: {ファイルリスト}
受け入れ基準: {基準}
関連 ADR: {ADR リスト}

原則:
- 最先端を構築する。回避策なし、レガシーパターンなし。
- 正しいアーキテクチャレベルで修正する、コンポーネントレベルのハックは使わない。
- プランが間違っているかコンテキストが不足していると判断した場合、停止して報告する — アーキテクチャを即興しない。

完了したら次のメッセージでコミット: "feat: {task-description}"
```


## ステップ 4: 品質ゲート

並列で実行します:
- リンター
- 型チェッカー（該当する場合）
- フルテストスイート

すべて合格した場合: スモークテストに進む。

いずれかが失敗した場合: 失敗出力と共に `quality-fixer` デバッグエージェントをスポーン。最大**3回の自動修正試行**を行います。試行ごとに品質ゲートを再実行します。3回の試行後もまだ失敗している場合: 停止し、完全なエラー出力と共に失敗を報告し、人間の介入を待ちます。

**統合スモークテスト** *(純粋なフロントエンドまたはドキュメントのみのプランはスキップ)*:

プランの `## Integration Verification` セクションで定義されたスモークコマンドを実行します。さらに:
- GraphQL の場合: スキーマにアクセス可能かをイントロスペクションプローブで確認
- Docker サービスの場合: ERROR レベルのエントリのコンテナログをスキャン
- 新しい API ルートの場合: 各ルートが期待されるステータスコードを返すか確認

スモークテストの失敗は同じ3回制限の `quality-fixer-smoke` エージェントによってデバッグされます。


## ステップ 5: PR 前のドキュメント

*PR を作成する前に worktree 内で。*

**PRD 照合**: 実装された動作を元の PRD と比較します。実装中に発見された逸脱や追加事項をメモします。実際の状態で PRD を更新します。これらの更新は機能と同じ PR に含まれます。

**プランのアーカイブ**: `docs/plans/plan-{name}.md` を `docs/plans/completed/plan-{name}.md` に移動します。ステータスヘッダーを更新します。

ドキュメント更新をコミット: `docs: reconcile PRD and archive plan for {feature-name}`。


## ステップ 6: プッシュと PR

worktree ブランチをプッシュして PR を作成します:

```bash
git push origin feature/{plan-name}
gh pr create \
  --title "{feature-name}: {one-line summary from plan}" \
  --body "$(cat .pr-body.md)"
```

PR 本文テンプレート:
```markdown
## Summary
{プランのサマリー段落}

## Changes
{タスクリストから自動生成: 影響を受けるファイル付きのタスクごとの箇条書き}

## ADRs
{このプランで作成された ADR のリスト}

## Test Plan
{プランのテストプランセクションから}

## Smoke Test Results
{統合検証からの出力}
```

スカッシュでマージ:
```bash
gh pr merge --squash --delete-branch
```


## ステップ 7: マージ後のメトリクス

develop/main に戻ります。実行データで `docs/plans/metrics/{name}.json` を更新します:
- タスク数とレイヤーごとの内訳
- TDD タスク数
- diff 統計（変更ファイル数、追加/削除行数）
- 品質ゲート結果（合格/不合格、修正試行回数）
- スモークテスト結果
- ドリフトスコア（0-1、実装がプランにどれだけ一致したか）
- PR データ（番号、マージコミット、タイムスタンプ）

メトリクス更新をコミット。


## ステップ 8: Worktree のクリーンアップ

```bash
git worktree remove .worktrees/{plan-name}
```


## 使用法

```
/plan-execute
```

最新の検証済みプランを自動的に取得します。または指定:

```
/plan-execute plan-user-authentication
```

## 出力

```
Setting up worktree: .worktrees/user-authentication
Branch: feature/user-authentication

TDD scaffolding: 2 tasks marked TDD
  ✓ Written failing tests for: auth-token-validation
  ✓ Written failing tests for: refresh-token-rotation
  Committed: "test: failing tests for auth pipeline (TDD)"

Executing Layer 1 (3 tasks, parallel)...
  [agent-1] Implementing: JWT token generation service
  [agent-2] Implementing: User session model
  [agent-3] Implementing: Auth middleware
  ✓ Layer 1 complete. 3 commits.

Drift check: Layer 1... ✓ No drift detected.

Executing Layer 2 (2 tasks, parallel)...
  [agent-4] Implementing: Login endpoint
  [agent-5] Implementing: Refresh endpoint
  ✓ Layer 2 complete. 2 commits.

Quality gate...
  ✓ Lint passed
  ✓ Type check passed
  ✓ Tests: 47 passed, 0 failed

Smoke test...
  ✓ GraphQL introspection: OK
  ✓ POST /api/auth/login: 200
  ✓ POST /api/auth/refresh: 200

Pre-PR docs...
  ✓ PRD reconciled (1 minor deviation noted)
  ✓ Plan archived to docs/plans/completed/

PR created: #142 "user-authentication: JWT auth with refresh token rotation"
PR merged (squash). Branch deleted.

Metrics committed. Worktree cleaned.
✅ Feature complete.
```

## 使用するタイミング

`/plan-validate` がすべての問題が解決されていることを確認した後。検証をスキップしないこと — 未検証のプランを実行すると、平均で約18の問題を発見する独立したレビューをスキップすることになります。

## 参照

- [Plan-Validate-Execute パイプライン](../../guide/workflows/plan-pipeline.md)
- [Git Worktree コマンド](./git-worktree.md)
- [Claude での TDD](../guide/workflows/tdd-with-claude.md)
