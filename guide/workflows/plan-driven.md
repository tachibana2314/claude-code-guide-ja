---
title: "プラン駆動開発"
description: "非自明なタスクには/planモードを使い、実装プランを探索・提案する"
tags: [workflow, guide, architecture]
---

# プラン駆動開発

> **信頼度**: Tier 1 — Claude Codeのネイティブ/planモード機能に基づく。

非自明なものには `/plan` モードを使います。Claudeはコードベースを探索（読み取り専用）し、承認のための実装プランを提案します。

---

## 目次

1. [要約](#要約)
2. [/planワークフロー](#planワークフロー)
3. [使う場面](#使う場面)
4. [プランファイル構造](#プランファイル構造)
5. [他のワークフローとの統合](#他のワークフローとの統合)
6. [ヒント](#ヒント)
7. [発展: カスタムMarkdownプラン（Boris Taneパターン）](#発展-カスタムmarkdownプランboris-taneパターン)
8. [関連情報](#関連情報)

---

## 要約

```
1. プランモードに入る（Shift+Tabを2回）または複雑な質問をする
2. Claudeがコードベースを探索（読み取り専用）
3. ClaudeがプランをClaude/plans/に書く
4. レビューして承認
5. Claudeが実行
```

---

## /planワークフロー

### ステップ1: プランモードに入る

`Shift+Tab` でプランモードを切り替えます（2回押して「通常」→「自動承認」→「プラン」をサイクル）:
```
# Shift+Tabを2回押してプランモードに入る
# （プランモードのインジケーターがUIに表示される）
```

またはプランモードを自動的にトリガーする複雑な質問をします:
```
How should I refactor the authentication system to support OAuth?
```

### ステップ2: Claudeが探索する

プランモードでClaudeは:
- 関連するファイルを読む
- パターンを検索する
- 既存のアーキテクチャを理解する
- 変更は一切行えない

### ステップ3: Claudeがプランを書く

Claudeは `.claude/plans/[name].md` にプランファイルを作成します:

```markdown
# Plan: Refactor Authentication for OAuth

## Summary
Add OAuth support while maintaining existing email/password auth.

## Files to Modify
- src/auth/providers/index.ts (add OAuth provider)
- src/auth/middleware.ts (handle OAuth tokens)
- src/config/auth.ts (OAuth config)

## Files to Create
- src/auth/providers/oauth.ts
- src/auth/providers/google.ts

## Implementation Steps
1. Create OAuth provider interface
2. Implement Google OAuth provider
3. Update middleware to detect token type
4. Add OAuth routes
5. Update config schema

## Risks
- Breaking existing sessions during migration
- Token format differences between providers
```

### ステップ4: レビュー

以下の点でプランをレビューします:
- 完全性（すべての要件が網羅されているか）
- 正確性（コードベースに合ったアプローチか）
- スコープ（過剰設計になっていないか）

### ステップ5: 承認して実行

```
Looks good. Proceed with the plan.
```

または変更をリクエストします:
```
Modify the plan: also add support for GitHub OAuth, not just Google.
```

---

## 使う場面

### プランモードを使う場合

| シナリオ | 理由 |
|----------|-----|
| 複数ファイルの変更 | 影響するすべてのファイルを事前に確認 |
| アーキテクチャの変更 | コーディング前にアプローチを検証 |
| 新機能 | 完全な実装を確保 |
| 不慣れなコードベース | Claudeに先に探索させる |
| リスクの高い操作 | 実行前にレビュー |

### プランモードをスキップする場合

| シナリオ | 理由 |
|----------|-----|
| 1行の修正 | 明白で低リスク |
| タイポの修正 | プランニング不要 |
| シンプルな質問 | 実装ではなく探索 |
| コメントの追加 | 些細な変更 |

---

## プランファイル構造

プランは `.claude/plans/` に自動生成された名前で保存されます。

### 典型的なプランのセクション

```markdown
# Plan: [Title]

## Summary
[1-2文の概要]

## Context
[この変更が必要な理由]

## Files to Modify
[変更される既存ファイルのリスト]

## Files to Create
[新しいファイルのリスト]

## Files to Delete
[削除するファイルのリスト（あれば）]

## Implementation Steps
[順序付けられた手順のリスト]

## Testing Strategy
[変更を検証する方法]

## Risks & Mitigations
[何が問題になりうるか、その対処法]

## Open Questions
[進む前に明確にすべきこと]
```

---

## 他のワークフローとの統合

### プラン + TDD

```
# プランモードに入る（Shift+Tabを2回）、その後:

I need to implement a rate limiter.
Plan the test cases first, then the implementation.
```

Claudeは適切なTDDの順序でテストと実装の両方をプランします。

### プラン + 仕様ファースト

```
# プランモードに入る（Shift+Tabを2回）、その後:

Review the Payment Processing spec in CLAUDE.md.
Create an implementation plan that satisfies all acceptance criteria.
```

### プラン + タスクツール

プランの承認後、Claudeはタスクに分解できます:

```
Approved. Create tasks from this plan and start implementing.
```

---

## ヒント

### スコープを具体的に指定する

```
# 曖昧すぎる（Shift+Tabを2回でプランモードに入った後）
Improve the API

# より良い
Add pagination to the /users endpoint with cursor-based navigation.
Maintain backwards compatibility with existing clients.
```

### プランの修正をリクエストする

```
The plan looks good but:
- Add error handling for network failures
- Skip the caching optimization for now
- Include rollback procedure
```

### アーキテクチャの決定に使う

```
# プランモードに入る（Shift+Tabを2回）、その後:

I'm considering two approaches for state management:
A) Redux Toolkit
B) Zustand

Explore the codebase and recommend which fits better.
```

### ドキュメントとしてプランを保存する

`.claude/plans/` のプランは決定のドキュメントとして機能します:
- 特定のアプローチが選ばれた理由
- 変更される予定だったファイル
- 実装順序の根拠

---

## 発展: カスタムMarkdownプラン（Boris Taneパターン）

> **出典**: Boris Tane、Cloudflareのエンジニアリングリード — ["How I use Claude Code"](https://boristane.com/blog/how-i-use-claude-code/)（2026年2月）。9ヶ月の本番使用。
> **信頼度**: Tier 2 — 実践者が検証したパターン。Anthropicの公式ドキュメントではない。

プランモードでは不十分な場合に、コードが書かれる前の人間とエージェントによる反復プランニング。

### /planよりカスタムプランを使う理由

| 要素 | プランモード（ネイティブ） | カスタム.mdプラン |
|--------|----------------|-----------------|
| **永続性** | コンテキスト圧縮で失われる | 圧縮後も残り、共有可能 |
| **レビュー面** | チャットベース、線形 | 構造化ファイル、差分 |
| **反復** | 会話でのやり取り | ファイルをアノテーション、再実行 |
| **共有状態** | セッションごと | 人間とエージェントの「共有可変状態」 |
| **最適な用途** | 標準的な機能、30分未満のタスク | 複雑な機能、アーキテクチャの決定 |

**判断ルール**: スコープが明確な場合はプランモード（Shift+Tabを2回）を使用。誤解が予想される場合や、1行のコードの前に明示的なサインオフを求めたい場合はカスタム `.md` プランを使用。

---

### 3フェーズのワークフロー

```
┌─────────────────────────────────────────────────────────────────┐
│  フェーズ1: リサーチ                                              │
│  → 強調プロンプト → research.md（口頭ではなく書面）              │
├─────────────────────────────────────────────────────────────────┤
│  フェーズ2: プランニング（アノテーションサイクル）               │
│  → plan.md草稿 → 人間がアノテーション → エージェントが更新 → 繰り返し │
│  → 終了: プランが承認、未解決の質問なし                          │
├─────────────────────────────────────────────────────────────────┤
│  フェーズ3: 実装                                                  │
│  → 機械的な実行、すでに意思決定済み                              │
└─────────────────────────────────────────────────────────────────┘
```

---

### フェーズ1: 強調リサーチ

Claudeは強いシグナルなしに流し読みします。深さを強制するために強調言語を使います:

```
Research the authentication system in this codebase deeply.
Understand the intricacies of how sessions are managed, in great detail.
Cover edge cases, existing patterns, and any non-obvious dependencies.

Write your findings to research.md — do not implement anything.
```

**なぜ機能するか**: 「deeply」「in great detail」「intricacies」はClaudeを表面的なスキャンから徹底的な調査へシフトさせます。出力はファイルに書かれる必要があります — 口頭の要約はコンテキスト圧縮で消えてしまいます。

**research.mdに含めるべきもの**:
- 既存のパターンと規約
- ファイルパスと主要な関数
- 非自明な依存関係
- 特定された制約とリスク

---

### フェーズ2: アノテーションサイクル

Boris Taneパターンの核心。**実装前に** `plan.md` を準備完了まで繰り返します。

```
┌──────────────────────────────────────────────────────────────┐
│                    アノテーションサイクル                      │
│                                                              │
│  人間のプロンプト ──→ エージェントがplan.mdを書く             │
│       ↑                    ↓                                 │
│  プランをアノテーション  人間がplan.mdをレビュー              │
│  （コメントを追加、         ↓                                 │
│   質問をする、         問題があるか？                         │
│   トレードオフを指摘）       ├─ はい → アノテーション → ループ │
│                          └─ いいえ → 承認 → フェーズ3        │
│                                                              │
│  典型的: 承認まで1-6回の反復                                  │
└──────────────────────────────────────────────────────────────┘
```

**ガードプロンプト** — 早期実装を防ぐために常に含める:

```
Based on research.md, write a plan for implementing [feature].

Include: approach, affected file paths, code snippets for key decisions,
trade-offs considered, and open questions.

Write to plan.md. Do NOT implement anything yet.
```

**plan.mdに含めるべきもの**:

```markdown
# Plan: [Feature Name]

## Approach
[戦略と根拠]

## Files Affected
- path/to/file.ts — 何が変わりなぜか
- path/to/other.ts — 何が変わりなぜか

## Key Implementation Details
[非自明な部分のコードスニペット — 完全な実装ではない]

## Trade-offs
- オプションA対B: AをXの理由で選択
- 検討したが却下: Y（理由）

## Open Questions
- [ ] エッジケースZを処理すべきか？
- [ ] モバイルクライアントに影響するか？
```

**アノテーション例**:

```markdown
## Approach
Use JWT tokens stored in httpOnly cookies.
<!-- 人間のアノテーション: ✓ 同意。ただしリフレッシュトークンのローテーションも考慮 -->

## Open Questions
- [ ] Should we handle token expiry in middleware?
<!-- 人間のアノテーション: はい、集中化 — 各ルートに任せない -->
```

**終了基準** — プランの準備完了:
- 未解決の質問がない
- トレードオフが文書化され合意されている
- ファイルパスが具体的（「何らかの認証ファイル」ではない）
- 主要なスニペットがアプローチを示している（説明だけでなく）

> 「Markdownファイルはあなたとエージェントの間の共有可変状態として機能します。」— Boris Tane

---

### フェーズ3: 機械的な実装

プランが承認されると、実装は実行になります — 創造的な決定は残っていません。

```
Implement everything in plan.md.
Work through each item sequentially.
Mark tasks as completed as you go with [x].
Do not stop between tasks to ask for confirmation — keep going until done.
```

**実装中のフィードバック**:
- 簡潔に: 段落ではなく短いフレーズやスクリーンショット
- 決定はすでになされている — スコープの変更はplan.mdに戻す
- 予期しないことが起きた場合: 一時停止、plan.mdを更新、続行

**マインドセットの転換**: フェーズ3は機械的です。すべての思考はフェーズ2で行われました。

---

### 補完テクニック

| テクニック | 内容 | タイミング |
|-----------|------|------|
| **チェリーピッキング** | plan.mdのサブセットを実装 | プランが大きすぎる、段階的にシップ |
| **スコープの削減** | 実装前にアイテムを削除 | リスク軽減、コアに集中 |
| **参照ベースのガイダンス** | 既存のコードを指す: 「auth.tsのようにやる」 | 一貫性の強制 |
| **元に戻してリスコープ** | `git revert` + より狭いプランで再開始 | プランが間違っていた、きれいにリセット |

---

## 関連情報

- [exploration-workflow.md](./exploration-workflow.md) — プランニング前に代替案を探索
- [../ultimate-guide.md](../ultimate-guide.md) — セクション2.3 プランモード
- [tdd-with-claude.md](./tdd-with-claude.md) — TDDとの組み合わせ
- [spec-first.md](./spec-first.md) — 仕様ファーストとの組み合わせ
- [iterative-refinement.md](./iterative-refinement.md) — プラン後の反復
- [task-management.md](./task-management.md) — タスクAPIを使ってセッションをまたいでプランの実行を追跡
- [dual-instance-planning.md](./dual-instance-planning.md) — 発展: 品質重視のワークフローに2つのClaudeインスタンス（プランナー+実装者）を使う
