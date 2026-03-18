---
title: "RPI: リサーチ → プラン → 実装"
description: "フェーズ間に明示的なバリデーションゲートを持つ3フェーズの機能開発パターン"
tags: [workflow, architecture, design-patterns, validation]
---

# RPI: リサーチ → プラン → 実装

> **信頼度**: Tier 2 — 本番チームのパターンから統合。ゲートベースの構造は、エージェントタスク分解とエージェントループ制御に関するAnthropicのガイダンスと一致。

3つのロックされたフェーズで機能を構築します: 最初に実現可能性をリサーチし、次に実装をプランし、3番目にコードを書きます。各フェーズは具体的なアーティファクトを生成します。各ゲートは次のフェーズが開始する前に明示的なGOが必要です。

---

## 目次

1. [要約](#要約)
2. [RPIを使う場面](#rpiを使う場面)
3. [ゲートの仕組み](#ゲートの仕組み)
4. [フェーズ1: リサーチ](#フェーズ1-リサーチ)
5. [フェーズ2: プラン](#フェーズ2-プラン)
6. [フェーズ3: 実装](#フェーズ3-実装)
7. [スラッシュコマンドテンプレート](#スラッシュコマンドテンプレート)
8. [ワークドエグザンプル](#ワークドエグザンプル)
9. [他のワークフローとの比較](#他のワークフローとの比較)
10. [ヒントとトラブルシューティング](#ヒントとトラブルシューティング)
11. [関連情報](#関連情報)

---

## 要約

```
フェーズ1 — リサーチ:
  Claudeが実現可能性を探索し、リスクを表面化させ、決定の質問をする
  出力: RESEARCH.md
  ゲート: GO / NO-GOを決定

フェーズ2 — プラン:
  Claudeがアーキテクチャの決定、ユーザーストーリー、テストプランを書く
  出力: PLAN.md
  ゲート: コードが書かれる前にプランを承認

フェーズ3 — 実装:
  Claudeがステップバイステップで実装し、次のステップ前にテストが通る
  出力: 動作するコード + 通過するテスト
  ゲート: 次のステップ開始前に各実装ステップを検証
```

**最適な用途**: 実現可能性が不明な機能、1日以上の作業、未知の技術領域、または後で誤った仮定を発見するとコストがかかる場合。

---

## RPIを使う場面

### RPIを使う場合

- **実現可能性が不明**: アイデアがあるが技術的に成立するか確かでない
- **スコープが大きい**: 1日以上の実装作業
- **要件が曖昧**: 達成したい結果はわかるが、そこへの道はわからない
- **間違った方向のリスクが高い**: セキュリティ、決済、データマイグレーション、外部システムとの統合
- **以前に驚かされた経験がある**: シンプルに見えた機能が6つの他のシステムを含んでいた

### RPIをスキップする場合

| シナリオ | より良いアプローチ |
|----------|----------------|
| 修正が明白（タイポ、色が違う） | 直接編集 |
| 機能がよく理解されていて要件が明確 | [仕様ファースト](./spec-first.md) または [デュアルインスタンス](./dual-instance-planning.md) |
| 探索モード — まだ何が欲しいかわからない | 探索ワークフロー |
| 些細な変更、単一ファイル | そのままやる |

### 判断ヒューリスティック

「リサーチフェーズで深刻な問題が明らかになった場合、先に2日間実装しなくてよかったと思うか？」

「はい」なら、RPIを実行します。リサーチフェーズは通常30-60分かかり、多くの時間を節約できます。

---

## ゲートの仕組み

RPIには2つの人間ゲートと実装ステップごとに1つの自動ゲートがあります。

```
[アイデア]
   |
   v
[フェーズ1: リサーチ]
   |
   +- NO-GO -> 停止。理由を文書化。RESEARCH.mdをアーカイブ。
   |
   +- GO -------------------------------------------------------->
                                                                 |
                                                       [フェーズ2: プラン]
                                                                 |
                                          +- 修正が必要 -> Claudeと反復
                                          |
                                          +- 承認 -------------------------------->
                                                                                      |
                                                                          [フェーズ3: 実装]
                                                                              ステップ1 -> テストゲート
                                                                              ステップ2 -> テストゲート
                                                                              ステップ3 -> テストゲート
                                                                                   |
                                                                                [完了]
```

**ゲート1（リサーチ後）**: RESEARCH.mdを読んでGO/NO-GOの決定をします。これが最も重要なゲートです — 完全に間違ったものを構築することを防ぎます。

**ゲート2（プラン後）**: コードが書かれる前にPLAN.mdをレビューします。ここでの小さな修正はゼロコストです。

**ステップゲート（実装中）**: 各実装ステップはClaudeが次のステップに進む前にテストに通る必要があります。自動化されており、ステップが失敗しない限り人間のアクションは不要です。

---

## フェーズ1: リサーチ

### リサーチがカバーすること

リサーチフェーズは5つの質問に答えます:

1. **すでに何があるか？** 関連するコード、ライブラリ、コードベース内の以前の試み
2. **何を構築する必要があるか？** スコープの境界、作成対変更するコンポーネント
3. **リスクは何か？** 技術的、セキュリティ、統合、パフォーマンス
4. **決定ポイントは何か？** プラン全体に影響するアーキテクチャの選択
5. **工数の見積もりは？** プランにコミットする前のおおよそのサイジング

Claudeはコードベースを探索し、関連するファイルを読み、依存関係を確認し、プランを変えるような制約を表面化させます。結果はRESEARCH.mdです。

### リサーチの開始

機能フォルダを作成してリサーチを呼び出します:

```bash
mkdir -p .claude/features/[feature-name]
```

その後Claudeで:

```
/rpi:research [機能の説明]
```

またはスラッシュコマンドなしで:

```
Run RPI Phase 1 (Research) for: [機能の説明]

Save output to .claude/features/[feature-name]/RESEARCH.md
Use Plan Mode to explore without modifying code.
```

### RESEARCH.mdテンプレート

```markdown
# Research: [Feature Name]

**Date**: [YYYY-MM-DD]
**Requested**: [機能の一文説明]
**Status**: PENDING DECISION

---

## What Exists Today

### Relevant Code
- [ファイルパス]: [何をするか、なぜ重要か]
- [ファイルパス]: [何をするか、なぜ重要か]

### Relevant Libraries
- [ライブラリ]: [現在使用中 / 利用可能 / 追加が必要]

### Prior Attempts or Related Work
- [既存の部分的な実装、関連PR、コードベース内のメモ]

---

## What Needs to Be Built

### New Files
- [ファイルパス]: [目的]
- [ファイルパス]: [目的]

### Files to Modify
- [ファイルパス]: [何が変わるか、なぜか]

### External Dependencies
- [依存関係]: [必要な理由、バージョン制約（あれば）]

---

## Risks

| Risk | Likelihood | Impact | Notes |
|------|-----------|--------|-------|
| [リスクの説明] | Low/Med/High | Low/Med/High | [緩和策またはブロッカー] |

---

## Architecture Decision Points

プランニングを開始する前に決定が必要な質問:

1. **[決定]**: オプションA（長所: X、短所: Y）対オプションB（長所: X、短所: Y）
2. **[決定]**: [オプションとトレードオフ]

---

## Effort Estimate

- リサーチからプランへ: [時間]
- 実装: [時間範囲]
- テスト: [時間]
- **総見積もり**: [範囲]

**見積もりの信頼度**: 低 / 中 / 高
**理由**: [信頼度レベルの理由]

---

## Recommendation

[GO / NO-GO / NEEDS CLARIFICATION]

[推奨の説明1-3文]

---

**Decision**: [ ] GO  [ ] NO-GO  [ ] NEEDS CLARIFICATION
**Notes**: [人間がここを記入]
```

### NO-GOの例

すべてのリサーチフェーズがGOで終わるわけではありません。よくあるNO-GOの理由:

- **技術的なブロッカー**: 外部APIが必要な操作をサポートしていない
- **発見されたスコープクリープ**: 「シンプルな機能」が認証レイヤーの書き直しを必要とすることが判明
- **より良い代替案が存在する**: リサーチが問題をよりシンプルに解決する既存のライブラリまたは設定変更を明らかにする
- **今はリスクが高すぎる**: 機能は有効だが、タイミングが悪い

NO-GOのリサーチドキュメントをアーカイブします — それらは行われた決定とその理由の貴重な記録です。

---

## フェーズ2: プラン

### プランがカバーすること

フェーズ2はRESEARCH.mdにGOをマークした後にのみ開始します。ClaudeはリサーチドキュメントをReadして精密な実装プランを作成します。

良いプランは、別のエンジニア（または新しいセッションのClaude）が質問なしに実行できるほど具体的です。

```
/rpi:plan .claude/features/[feature-name]/RESEARCH.md
```

またはスラッシュコマンドなしで:

```
Run RPI Phase 2 (Plan) using:
- Research: .claude/features/[feature-name]/RESEARCH.md

Save output to .claude/features/[feature-name]/PLAN.md
Do not write any code yet. Plan only.
```

### PLAN.mdテンプレート

```markdown
# Plan: [Feature Name]

**Date**: [YYYY-MM-DD]
**Research**: [RESEARCH.mdへのリンク]
**Estimated effort**: [リサーチからの見積もり]
**Risk level**: Low / Medium / High

---

## Summary

[2-4文: 何を実装するか、主要な設計決定、含まれないもの]

---

## Architecture Decisions

[リサーチの決定ポイントから行われた決定を記録]

1. **[決定]**: [Xの理由で][オプション]を選択
2. **[決定]**: [Xの理由で][オプション]を選択

---

## Implementation Steps

ステップは順次かつ独立してテスト可能である必要があります。

### Step 1: [Name]

**Files**: [作成または変更するファイルのリスト]
**What to build**: [正確な説明]
**Test gate**: [ステップ2開始前に通る必要がある具体的なテストまたは確認]

### Step 2: [Name]

**Files**: [作成または変更するファイルのリスト]
**What to build**: [正確な説明]
**Test gate**: [ステップ3開始前に通る必要がある具体的なテストまたは確認]

[...すべてのステップまで続ける]

---

## Success Criteria

- [ ] [テスト可能な基準 — 実装ではなく観察可能な動作を説明]
- [ ] [テスト可能な基準]
- [ ] すべてのステップのテストゲートが通る

---

## Out of Scope

このプランがカバーしないものを明示的にリストアップ:
- [除外されたもの]
- [除外されたもの]

---

## Risks Accepted

[RESEARCH.mdのリスクから、どれが受け入れられどのように緩和されるか]

---

## Rollback Plan

実装が途中で失敗した場合:
- [取り消すもの]
- [前の状態に戻す方法]

---

**Plan approved?** [ ] YES — 実装に進む
**Revision notes**: [変更が必要な場合は人間がここを記入]
```

### プランのレビュー

承認前にPLAN.mdを注意深く読んでください。目標は設計の問題を今見つけることで、実装中ではありません。具体的に確認すること:

- 実装ステップが正しい順序で、隠れた依存関係がない
- テストゲートが具体的で実行可能（「正しく見える」ではない）
- スコープ外が明示的（Claudeが過剰構築するのを防ぐ）
- データや共有状態に触れるものにはロールバックプランが存在する

プランに変更が必要な場合は、承認前にClaudeに修正するよう頼んでください。これは無料です — 承認後の修正は実装時間がかかります。

---

## フェーズ3: 実装

### ステップゲートパターン

実装はステップバイステップで実行されます。各ステップにはテストゲートがあります。Claudeは現在のゲートが通るまで次のステップを開始しません。

```
/rpi:implement .claude/features/[feature-name]/PLAN.md
```

またはスラッシュコマンドなしで:

```
Run RPI Phase 3 (Implement) using:
- Plan: .claude/features/[feature-name]/PLAN.md

Rules:
- Implement one step at a time
- After each step, run the test gate specified in the plan
- Do not start the next step until the test gate passes
- If a test gate fails, stop and report the failure — do not improvise a fix
- Commit after each step that passes its gate
```

### 実装中に起こること

Claudeはプランのステップを順次実行します。各ステップで:

1. 指定されたファイルと変更を実装
2. テストゲートを実行（ユニットテスト、統合チェック、または手動検証）
3. ゲートが通った場合: ステップを参照したメッセージでコミットし、次のステップの準備完了を告知
4. ゲートが失敗した場合: 失敗を報告し、具体的なテスト出力と考えられる原因を示す。確認なしに修正を試みない。

ステップコミットパターンにより、プランを反映するクリーンなgit履歴が得られます。ステップ4で何か問題が起きた場合、ステップ3のコミットにきれいにロールバックできます。

### ステップゲート失敗プロトコル

テストゲートが失敗した場合、Claudeは次のように報告します:

```
Step [N] gate failed.

Gate: [通るべきだったもの]
Output:
[実際のテスト出力]

Likely cause: [Claudeの診断]
Options:
1. Fix: [おそらく修正する具体的な変更]
2. Revise plan: [プランステップ自体に欠陥がある場合]
3. Stop and investigate: [失敗が予期しないことを明らかにした場合]

Which should I do?
```

あなたが決定します。Claudeは自動修正して続行しません — それがプランから実装がドリフトする原因です。

---

## スラッシュコマンドテンプレート

これらを `.claude/commands/` に保存して各フェーズを直接呼び出します。

### `/rpi:research`

`.claude/commands/rpi-research.md` に保存:

```markdown
# RPI Phase 1: Research

リクエストされた機能の実現可能性リサーチを実行します。

## Instructions

1. プランモードに入る（リサーチ中はファイルを変更しない）
2. コードベースを探索してこれらの質問に答える:
   - 関連して既に何があるか？
   - 変更または作成する必要があるファイルは何か？
   - 技術的なリスクは何か？
   - プランニング前に何が決定される必要があるか？
   - おおよその工数見積もりは？
3. 出力を `.claude/features/$ARGUMENTS/RESEARCH.md` に以下のテンプレートを使って保存
4. 明確な推奨で終わる: GO、NO-GO、またはNEEDS CLARIFICATION
5. 続行前にユーザーにGO/NO-GOの決定を求める

## Constraints

- コードを書かない
- ファイルを変更しない
- 実装ステップのプランニングを始めない
- スコープが不明確な場合は、決定ポイントとして表面化させる
```

### `/rpi:plan`

`.claude/commands/rpi-plan.md` に保存:

```markdown
# RPI Phase 2: Plan

承認されたリサーチに基づいて実装プランを作成します。

## Pre-check

開始前に:
1. $ARGUMENTS で指定されたRESEARCH.mdファイルを読む
2. GOの決定がマークされていることを確認
3. GOの決定が見つからない場合は、停止してユーザーに先に決定するよう求める

## Instructions

1. RESEARCH.mdを注意深く読む
2. 同じ機能フォルダにPLAN.mdを作成
3. アーキテクチャの決定: リサーチからのすべての決定ポイントを解決
4. 実装ステップ: 各ステップは具体的なテストゲートを持つ必要がある
5. 成功基準: 観察可能で、テスト可能で、実装内部ではない
6. スコープ外: このプランがカバーしないものの明示的なリスト
7. 実装コードを書かない
8. プランを書いた後、ユーザーにレビューと承認を求める

## Constraints

- 実装コードを書かない
- ステップは順次かつ独立してテスト可能である必要がある
- テストゲートは実行可能なコマンドまたは正確な手動チェックである必要がある（漠然とした説明ではない）
- 各ステップは単一の集中したセッションで達成可能である必要がある
```

### `/rpi:implement`

`.claude/commands/rpi-implement.md` に保存:

```markdown
# RPI Phase 3: Implement

承認されたプランに従って、機能をステップバイステップで実装します。

## Pre-check

開始前に:
1. $ARGUMENTS で指定されたPLAN.mdファイルを読む
2. 承認がマークされていることを確認
3. 承認が見つからない場合は、停止してユーザーに先に承認するよう求める

## Instructions

プランの各ステップについて:
1. ステップの説明を注意深く読む
2. ステップが指定するもののみを実装 — それ以上は不可
3. プランに書かれているとおりにテストゲートを実行
4. ゲートが通った場合:
   - メッセージ付きでコミット: "feat([feature]): step [N] — [step name]"
   - ステップ完了と次のステップへの準備完了を告知
5. ゲートが失敗した場合:
   - 正確な失敗出力を報告
   - 考えられる原因を診断
   - オプションを提示（修正、プランの修正、停止）
   - 続行前に人間の決定を待つ

## Constraints

- テストゲートをスキップしない
- 現在のゲートが通る前に次のステップを開始しない
- 現在のステップのスコープ外のファイルを変更しない
- プランを変えるような予期しないことに遭遇した場合は、停止して報告する
- 通過した各ステップの後にコミット — 最後ではない
```

---

## ワークドエグザンプル

**リクエスト**: 「パブリックAPIエンドポイントにレート制限を追加する。」

### フェーズ1: リサーチ出力（抜粋）

```markdown
# Research: API Rate Limiting

**Date**: 2026-03-12
**Status**: PENDING DECISION

## What Exists Today

- `src/middleware/` — 認証ミドルウェアあり、レート制限なし
- `package.json` — express-rate-limitは未インストール、redisは利用可能
- `src/routes/api.ts` — 14のパブリックエンドポイント、認証済みルートと未認証ルートが混在

## What Needs to Be Built

- パブリックエンドポイントのレート制限ミドルウェア
- 認証済みユーザーと未認証ユーザーの個別制限
- 分散レート制限のためのRedisストア（アプリは3インスタンスで実行）

## Risks

| Risk | Likelihood | Impact | Notes |
|------|-----------|--------|-------|
| Redisの接続失敗がすべてのAPIアクセスを無効にする | 低 | 高 | Redisが利用不可の場合のインメモリフォールバックが必要 |
| レート制限が積極的すぎて既存の統合を壊す | 中 | 高 | まず現在の使用パターンを調査する必要がある |

## Architecture Decision Points

1. **ライブラリ**: express-rate-limit（メンテナンス済み、実戦テスト済み）対カスタムミドルウェア
2. **信頼できるIPのバイパス**: 内部サービスにレート制限をバイパスさせるか？

## Effort Estimate

- 実装: 2-4時間
- テスト: 2時間
- **合計**: 4-6時間

**推奨**: GO — 標準的な問題、良いライブラリオプション、主なリスクはRedisフォールバックで解決可能。
```

**人間の決定**: GO。express-rate-limitを使用。今はIPバイパスなし。

### フェーズ2: プラン（抜粋）

```markdown
# Plan: API Rate Limiting

**Risk level**: Medium（共有Redisの状態、正当なトラフィックをブロックする可能性）

## Architecture Decisions

1. ライブラリ: express-rate-limit + rate-limit-redisストア
2. 当初IPバイパスなし — 内部サービスの問題が発生したら再検討
3. 未認証: 100リクエスト/15分。認証済み: 1000リクエスト/15分。
4. Redisフォールバック: インメモリストア（シングルインスタンスの不整合を受け入れる）

## Implementation Steps

### Step 1: 依存関係のインストールとRedisストアの設定

**Files**: `package.json`, `src/config/rate-limit.ts`
**Test gate**: `npm install` 完了、`src/config/rate-limit.ts` がエラーなしにconfigをエクスポート

### Step 2: レート制限ミドルウェアを実装

**Files**: `src/middleware/rate-limit.ts`
**Test gate**: ユニットテスト — リミッターが15分以内に同じIPからの101番目のリクエストをブロックする

### Step 3: ルートに適用

**Files**: `src/routes/api.ts`
**Test gate**: 統合テスト — 未認証ルートが100リクエスト後に429を返す；認証済みルートは返さない

### Step 4: Redisフォールバックを追加

**Files**: `src/config/rate-limit.ts`
**Test gate**: Redisが利用不可の状態でテスト — APIが依然として応答する（200、500ではない）、インメモリ制限がアクティブ
```

**人間のレビュー**: 承認。

### フェーズ3: 実装

Claudeはステップ1を実装し、ゲートを実行（`npm install` + インポートチェック）し、`feat(rate-limit): step 1 — dependencies and config` をコミットします。その後ステップ2、3、4を順番に。各コミットはクリーン。各ゲートは続行前に通る必要があります。

---

## 他のワークフローとの比較

| ワークフロー | フェーズ構造 | 人間ゲート | 最適な用途 |
|----------|----------------|------------|----------|
| **RPI** | リサーチ + プラン + 実装 | GO/NO-GO + プラン承認 | 不明な実現可能性、1日以上、間違った方向のリスクが高い |
| **デュアルインスタンス** | プラン + 実装（別々のClaudeインスタンス） | プラン承認 | 仕様が重い作業での慎重な実行が必要な既知の機能 |
| **仕様ファースト** | 仕様 + 実装 | なし（仕様が暗黙のゲート） | デザイン重視の作業、APIコントラクト、チームの整合 |
| **TDD** | テストファースト + 実装 | なし（テストがゲート） | テストカバレッジをドライバーとして、リファクタリング、インクリメンタルな動作 |
| **直接** | なし | なし | シンプルな変更、明白なスコープ、2時間未満 |

### RPI対デュアルインスタンス

デュアルインスタンスは、プランニングと実装を2つのClaudeインスタンスに分け、厳格なロール強制を行います。何を構築するかすでにわかっていて高品質なプランが欲しい場合に適しています。RPIはプランニング前に実現可能性フェーズを追加し、曖昧なリクエストに対してより適しています。明確な仕様がすでにある場合は、リサーチをスキップしてデュアルインスタンスまたは仕様ファーストを使用します。

### RPI対仕様ファースト

仕様ファーストはデザイン指向です: システムが何をすべきかを定義し、Claudeがそれを実装します。RPIはバリデーションゲートを持つ実装指向です: 目標を説明し、Claudeがそれを達成する方法をリサーチし、コードに触れる前に2人でプランに同意します。デザインが明確な場合は仕様ファーストを使用します。技術的な道が明確でない場合はRPIを使用します。

### RPI対直接コーディング

明確なスコープで2時間未満のものには、ClaudeにそのままやるよくGoすれよう依頼します。RPIは正当化されない小さなタスクへのオーバーヘッドを追加します。リサーチフェーズだけで30-60分かかります。そのオーバーヘッドは、後で誤った仮定を発見する方がはるかにコストがかかるマルチデイ機能に対して報われます。

---

## ヒントとトラブルシューティング

### リサーチフェーズでClaudeが実装に進んでしまう

**問題**: リサーチフェーズ中にClaudeがコードを書き始める。

**解決策**: リサーチフェーズで明示的にプランモード（Shift+Tabを2回）を使用します。リサーチコマンドにこの行を含めます:

```
You are in Plan Mode. Do not modify files. Do not write implementation code.
Research only. Output goes to RESEARCH.md.
```

またはCLAUDE.mdに追加します:

```markdown
## RPIルール
- /rpi:research はプランモードのみで実行 — ファイル変更なし
- /rpi:plan はPLAN.mdのみを生成 — 実装コードなし
- /rpi:implement は一度に1ステップ、次のステップ前にテストゲートを待つ
```

### リサーチフェーズが長すぎる

**問題**: Claudeが関連するものに集中する代わりにコードベース全体を探索する。

**解決策**: リサーチを明示的にスコープします:

```
/rpi:research payment-processing

Focus area: src/payments/, src/routes/checkout.ts
Do not explore: frontend, auth, unrelated backend modules
Time budget: complete research in one session
```

### プランのステップが多すぎる

**問題**: PLAN.mdに12のステップがあり、実装が扱いにくくなる。

**解決策**: 12以上のステップのプランは通常、より細かい実装ではなくスコープの削減が必要です。Claudeに尋ねます:

```
The plan has too many steps. What is the minimal viable scope that delivers
the core value? Revise the plan to implement only that, with a clear
"Future work" section for the rest.
```

### テストゲートが曖昧

**問題**: ステップのテストゲートが特定のコマンドではなく「正しく動作することを確認」と言っている。

**解決策**: プランを承認する前に曖昧なゲートを却下します。次のように反論します:

```
Step 3's test gate is "verify rate limiting works." Make it specific:
what command do I run, and what output do I expect to see when it passes?
```

良いテストゲート:

```
Test gate: `npm test src/middleware/rate-limit.test.ts` — 4つのテストすべて通過
```

悪いテストゲート:

```
Test gate: レート制限が正しく動作している
```

### ステップゲートが繰り返し失敗する

**問題**: ステップ2のゲートが修正を試みた後も失敗し続ける。

**解決策**: 2回の失敗は修正の反復ではなくプランを調査することを意味します。

```
Stop implementation. The Step 2 gate has failed twice.
Review the plan — is the test gate achievable given the Step 1 output?
Do we need to revise the plan before continuing?
```

---

## ファイル構造のまとめ

```
.claude/
└── features/
    └── [feature-name]/
        ├── RESEARCH.md     # フェーズ1の出力（人間がGO/NO-GOをアノテーション）
        └── PLAN.md         # フェーズ2の出力（人間が承認をアノテーション）

.claude/commands/
├── rpi-research.md         # /rpi:research スラッシュコマンド
├── rpi-plan.md             # /rpi:plan スラッシュコマンド
└── rpi-implement.md        # /rpi:implement スラッシュコマンド
```

完了した機能をアーカイブします:

```bash
mkdir -p .claude/features/_archive
mv .claude/features/payment-processing .claude/features/_archive/
```

アーカイブは学習リソースです: 完了したRESEARCH.mdとPLAN.mdファイルは、以前の機能がどのように推論されたかを示します。

---

## 関連情報

- [dual-instance-planning.md](./dual-instance-planning.md) — 仕様が重い実装のための2インスタンスパターン
- [spec-first.md](./spec-first.md) — CLAUDE.mdをコントラクトとして使用するデザインファーストワークフロー
- [tdd-with-claude.md](./tdd-with-claude.md) — テストゲート実装のためのTDDとの組み合わせ
- [task-management.md](./task-management.md) — セッションをまたいだマルチフェーズタスクの管理
- **メインガイド**: 発展パターンセクション — マルチインスタンスとプランニングパターンの概要
