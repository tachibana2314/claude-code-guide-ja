---
layout: default
title: "開発手法"
parent: コア概念
grand_parent: ガイド
nav_order: 3
---


# 開発手法リファレンス

> **確信度**: Tier 2 — 複数の本番事例レポートと公式ドキュメントによって検証済み。
>
> **最終更新**: 2026年2月

これは、2025〜2026年にAI支援開発向けに登場した15の構造化開発手法のクイックリファレンスです。実践的なワークフローについては [workflows/](./workflows/) を参照してください。


## 目次

1. [意思決定ツリー](#意思決定ツリー-何が必要か)
2. [15の手法](#15の手法)
3. [SDDツールリファレンス](#sddツールリファレンス)
4. [効果的な仕様書の書き方](#効果的な仕様書の書き方)
5. [組み合わせパターン](#組み合わせパターン)
6. [ソース](#ソース)


## 意思決定ツリー: 何が必要か？

```
┌─ 「品質の高いコードが欲しい」 ──────────→ workflows/tdd-with-claude.md
│
├─ 「コードの前に仕様を決めたい」 ─────────→ workflows/spec-first.md
│
├─ 「アーキテクチャを計画したい」 ─────────→ workflows/plan-driven.md
│
├─ 「何かを反復改善したい」 ───────────────→ workflows/iterative-refinement.md
│
└─ 「手法論の理論が知りたい」 ─────────────→ このまま読み続ける
```


## 15の手法

戦略的オーケストレーションから最適化技術まで、6階層のピラミッド構造で整理されています。

### Tier 1: 戦略的オーケストレーション

| 名前 | 概要 | 最適な用途 | Claude適合度 |
|------|------|------------|-------------|
| **BMAD** | 憲法をガードレールとした多エージェントガバナンス | エンタープライズ10人以上のチーム、長期プロジェクト | ⭐⭐ ニッチだが強力 |
| **GSD** | タスクごとに新鮮なコンテキストを使った6フェーズメタプロンプトワークフロー | ソロ開発者、Claude Code CLI | ⭐⭐ ガイドのパターンに類似 |

**BMAD（Breakthrough Method for Agile AI-Driven Development）** は従来のパラダイムを逆転させます。コードではなくドキュメントが真実の源となります。厳格なガバナンスのもとで専門エージェント（アナリスト、PM、アーキテクト、開発者、QA）を統括します。*注: BMADのロールベースエージェント名はその手法論を反映しています。スコープ重視の代替手法については §9.17 Agent Anti-Patterns を参照してください。*

- **重要コンセプト**: 戦略的ガードレールとしての Constitution.md
- **使用タイミング**: ガバナンスを必要とする複雑なエンタープライズプロジェクト
- **回避タイミング**: 小規模チーム、MVP、ラピッドプロトタイピング

**GSD（Get Shit Done）** は体系的な6フェーズワークフロー（Initialize → Discuss → Plan → Execute → Verify → Complete）とタスクごとの新鮮な200kトークンコンテキストによってコンテキストの劣化に対処します。コアコンセプト（多エージェントオーケストレーション、新鮮なコンテキスト管理）はRalph Loop、Gas Town、BMADなどの既存パターンと大きく重複しています。詳細な比較は [リソース評価](../docs/resource-evaluations/gsd-evaluation.md) を参照してください。

> **新興**: [Ralph Inferno](https://github.com/sandstream/ralph-inferno) は自律的なマルチペルソナワークフロー（Analyst→PM→UX→Architect→Business）をVM実行と自己修正E2Eループで実装しています。実験的ですが「ヴァイブコーディングをスケールさせる」観点から興味深いです。


### 基礎的規律: Plan-Firstワークフロー

> **「計画が良ければ、コードも良い。」**
> — Boris Cherny、Claude Codeの開発者

**単なる機能（`/plan` コマンド）ではなく、体系的な規律です。**

> **コンテキストエンジニアリング**: ThoughtworksはTechnology Radar（2025年11月）[^thoughtworks2025] でこの広範なアプローチを「コンテキストエンジニアリング」と命名しています。LLMに提供する情報を推論時に体系的に設計することです。3つのコアテクニック: コンテキスト設定（最小限のシステムプロンプト、few-shotサンプル）、長期タスクのコンテキスト管理（要約、外部メモリ、サブエージェントアーキテクチャ）、動的な情報取得（JITコンテキストロード）。Claude Codeにおける関連パターン: AGENTS.md、MCP Context7、Plan Mode。

[^thoughtworks2025]: Thoughtworks Technology Radar Vol 33、2025年11月。[PDF](https://www.thoughtworks.com/content/dam/thoughtworks/documents/radar/2025/11/tr_technology_radar_vol_33_en.pdf). 参照: [マクロトレンドブログ記事](https://www.thoughtworks.com/insights/blog/technology-strategy/macro-trends-tech-industry-november-2025).

**メンタルモデル**:

複雑なタスクにおいて計画は任意ではありません。それが以下の違いを生みます。
- ❌ 「試す → 修正 → 再試行 → また修正」の8回の反復
- ✅ 「計画 → 検証 → クリーンな実行」の1回の反復

**最初に計画すべきタイミング**:

| タスクの複雑さ | まず計画? | 理由 |
|--------------|-----------|------|
| 3ファイル以上の変更 | ✅ はい | ファイル間の依存関係にはアーキテクチャが必要 |
| 50行以上の変更 | ✅ はい | ミスが起きる十分な複雑さがある |
| アーキテクチャの変更 | ✅ はい | 影響分析が必要 |
| 不慣れなコードベース | ✅ はい | 行動前に調査が必要 |
| タイポ/明白な修正 | ❌ いいえ | 計画のオーバーヘッド > タスク時間 |
| 1行の変更 | ❌ いいえ | やってしまえばいい |

**Plan-Firstの流れ**:

1. **調査フェーズ**（`Shift+Tab` でPlan Modeへ）:
   - Claudeがファイルを読み、アーキテクチャを調査する
   - 編集は禁止 → 行動前に思考することを強制
   - トレードオフを含むアプローチを提案する

2. **検証フェーズ**（あなたがレビュー）:
   - 計画が仮定とギャップを明らかにする
   - 100行書いた後より今の方向修正の方が簡単
   - 計画が実行のための契約になる

3. **実行フェーズ**（`Shift+Tab` で通常モードに戻す）:
   - 計画 → コードが機械的な変換になる
   - 驚きが少なく、よりクリーンな実装
   - 「遅い」スタートにもかかわらず全体的には速い

**Boris Chernyのワークフロー**:

> 「私は多くのセッションを実行し、plan modeで始め、計画が良さそうになったら実行に切り替えます。重要なアップグレードは検証です。Claudeが自分の出力をテストして確認できる手段を与えることです。」

**「ただコーディングを始める」より優れている点**:

- **修正の反復が少ない**: 計画がコードになる前に問題を発見する
- **より良いアーキテクチャ**: 最初に構造を考えることを強制
- **明確なコミュニケーション**: 計画はチーム/Claudeとの共通理解になる
- **コスト削減**: 1回のクリーンな反復 < 複数の乱雑な反復（計画フェーズのトークンコストを含めても）

**CLAUDE.mdとの統合**:

チームのplan-firstのトリガーをドキュメント化する:
```markdown
## 計画ポリシー
- 必ず先に計画: API変更、DBマイグレーション、新機能
- 任意の計画: 10行未満のバグ修正、テスト追加
- スキップ禁止: 2モジュール以上に影響する変更
```

**参照**: `/plan` コマンドの使い方については [Plan Modeドキュメント](./ultimate-guide.md#23-plan-mode) を参照してください。

> **上級パターン**: アノテーションベースの反復的なplan-driven開発アプローチについては [カスタムMarkdownプラン（Boris Taneパターン）](./workflows/plan-driven.md#advanced-custom-markdown-plans-boris-tane-pattern) を参照してください。


### Tier 2: 仕様とアーキテクチャ

| 名前 | 概要 | 最適な用途 | Claude適合度 |
|------|------|------------|-------------|
| **SDD** | コードの前に仕様 | API、コントラクト | ⭐⭐⭐ コアパターン |
| **Doc-Driven** | ドキュメント = 真実の源 | チーム横断の整合 | ⭐⭐⭐ CLAUDE.mdネイティブ |
| **Req-Driven** | 豊富なアーティファクトコンテキスト（20+アーティファクト） | 複雑な要件 | ⭐⭐ セットアップが重い |
| **DDD** | ドメイン言語を最初に | ビジネスロジック | ⭐⭐ 設計時 |

**SDD（Spec-Driven Development）** — コードの前に仕様。1回の構造化された反復は8回の非構造化反復に相当します。CLAUDE.mdがあなたの仕様ファイルです。

**Doc-Drivenドキュメント** — gitでバージョン管理された生きたドキュメントが唯一の真実の源になります。仕様の変更が実装をトリガーします。

**Requirements-Driven開発** — CLAUDE.mdを20+の構造化アーティファクトを持つ包括的な実装ガイドとして使用します。

**DDD（Domain-Driven Design）** — ソフトウェアをビジネス言語に合わせます:
- ユビキタス言語: コード内の共有語彙
- 境界コンテキスト: 隔離されたドメイン境界
- ドメイン蒸留: コアドメイン vs サポートドメイン vs 汎用ドメイン


### Tier 3: ふるまいと受け入れ

| 名前 | 概要 | 最適な用途 | Claude適合度 |
|------|------|------------|-------------|
| **BDD** | Given-When-Thenシナリオ | ステークホルダーとのコラボレーション | ⭐⭐⭐ テストと仕様 |
| **ATDD** | まず受け入れ基準 | コンプライアンス、規制業種 | ⭐⭐ プロセス重視 |
| **CDD** | APIコントラクトをインターフェースとして | マイクロサービス | ⭐⭐⭐ OpenAPIネイティブ |

**BDD（Behavior-Driven Development）** — テストを超えたコラボレーションプロセス:
1. 発見: 開発者とビジネス専門家を巻き込む
2. 定式化: Given-When-Thenサンプルを書く
3. 自動化: 実行可能なテストに変換する（Gherkin/Cucumber）

```gherkin
Feature: 注文管理
  Scenario: 在庫なしでは購入できない
    Given 在庫0の商品
    When 顧客が購入を試みる
    Then システムはエラーメッセージで拒否する
```

**ATDD（Acceptance Test-Driven Development）** — コーディングの前に共同で受け入れ基準を定義します（「3人の仲間」: ビジネス、開発、テスト）。

エージェント開発においてATDDは特に効果的です。エージェントには曖昧さのない成功条件が必要だからです。フローはエージェントタスクにきれいにマッピングされます:

1. **受け入れ基準を定義する** Gherkinで（人間が読めて機械実行可能）
2. **エージェントが失敗するテストを書く** シナリオに基づいて（実装ではなく）
3. **エージェントが実装する** テストが通るまで

```gherkin
Feature: パスワードリセット
  Scenario: ユーザーがメールでリセットする
    Given "user@example.com" というメールで登録済みのユーザー
    When パスワードリセットをリクエストする
    Then 60秒以内にリセットメールを受け取る
    And リセットリンクは24時間後に期限切れになる
```

このGherkinシナリオは意図と実装の間のコントラクトです。コードを1行も書く前に「完了」が定義されているため、エージェントはスコープを誤解できません。

> **エージェントへの応用**: 実装前にGherkinファイルをClaude Codeに渡す。「このフィーチャーファイルのための失敗するテストを書いて、それからパスするまで実装してください。」シナリオライター役（人間またはエージェント）は実行開始前に明示的なスコープを強制します。

**CDD（Contract-Driven Development）** — APIコントラクト（OpenAPI仕様）をチーム間の実行可能インターフェースとして使用します。パターン: コントラクトをテストとして、コントラクトをスタブとして。


### Tier 4: フィーチャーデリバリー

| 名前 | 概要 | 最適な用途 | Claude適合度 |
|------|------|------------|-------------|
| **FDD** | フィーチャーごとのデリバリー | 10人以上の大規模チーム | ⭐⭐ 構造 |
| **Context Eng.** | コンテキストをファーストクラスの設計要素として | 長いセッション | ⭐⭐⭐ 基本 |

**FDD（Feature-Driven Development）** — 5つのプロセス:
1. 全体モデルの開発
2. フィーチャーリストの構築
3. フィーチャーごとの計画
4. フィーチャーごとの設計
5. フィーチャーごとの構築

厳格な反復: フィーチャーごとに最大2週間。

**コンテキストエンジニアリング** — コンテキストを設計要素として扱う:
- プログレッシブディスクロージャー: エージェントが段階的に発見できるようにする
- メモリ管理: 会話メモリ vs 永続メモリ
- 動的リフレッシュ: レスポンスの前にTODOリストを書き換える


### Tier 5: 実装

| 名前 | 概要 | 最適な用途 | Claude適合度 |
|------|------|------------|-------------|
| **TDD** | Red-Green-Refactor | 品質コード | ⭐⭐⭐ コアワークフロー |
| **Eval-Driven** | LLM出力のための評価 | AI製品 | ⭐⭐⭐ エージェント |
| **Multi-Agent** | サブエージェントのオーケストレーション | 複雑なタスク | ⭐⭐⭐ Taskツール |

**TDD（Test-Driven Development）** — 古典的なサイクル:
1. **Red**: 失敗するテストを書く
2. **Green**: パスするための最小限のコード
3. **Refactor**: クリーンアップ、テストはグリーンのまま

Claudeで: 明示的にする。「まだ存在しない失敗するテストを書いてください。」

> **検証ループ** — 自律的な反復の形式化されたパターン（TDDより広範）:
>
> **コア原則**: Claudeが自分の出力を検証するメカニズムを与える。
>
> ```
> コード生成 → 検証ツール → フィードバックループ → 改善
> ```
>
> **なぜ機能するか**（Boris Cherny）: *「自分がしたことを『見られる』エージェントはより良い結果を生み出す。」*
>
> **ドメインごとの検証メカニズム**:
>
> | ドメイン | 検証ツール | Claudeが「見るもの」 |
> |---------|-----------|-------------------|
> | **フロントエンド** | ブラウザプレビュー（ライブリロード） | 視覚的レンダリング、レイアウト、インタラクション |
> | **バックエンド** | テスト（ユニット/インテグレーション） | パス/フェイルステータス、エラーメッセージ |
> | **型** | TypeScriptコンパイラ | 型エラー、非互換性 |
> | **スタイル** | リンター（ESLint、Prettier） | スタイル違反、フォーマットの問題 |
> | **パフォーマンス** | プロファイラー、ベンチマーク | 実行時間、メモリ使用量 |
> | **アクセシビリティ** | axe-core、スクリーンリーダー | WCAG違反、ナビゲーションの問題 |
> | **セキュリティ** | 静的アナライザー（Semgrep） | 脆弱性パターン |
> | **UX** | ユーザーテスト、レコーディング | ユーザビリティの問題、混乱ポイント |
>
> **TDDを典型例として**:
> 1. Claudeがフィーチャーのテストを書く
> 2. テストがパスするまでClaudeがコードを反復する
> 3. 明示的な完了基準が満たされるまで継続する
>
> **公式ガイダンス**: *「すべてのテストがパスするまで進み続けるようClaudeに伝えてください。通常は数回の反復が必要です。」* — [Anthropicベストプラクティス](https://www.anthropic.com/engineering/claude-code-best-practices)
>
> **実装パターン**:
> - **Hooks**: PostToolUseフックが各編集後に検証を実行
> - **ブラウザ拡張**: ChromeのClaudeがレンダリングされた出力を見る
> - **テストウォッチャー**: Jest/Vitestウォッチモードが即時フィードバックを提供
> - **CI/CDゲート**: GitHub Actionsが完全な検証スイートを実行
> - **Multi-Claude検証**: 1つのClaudeがコーディング、別のClaudeがレビュー
>
> **アンチパターン**: フィードバックなしの盲目的な反復。検証メカニズムがなければ、Claudeは正しい解決策に収束できません — 推測するだけです。

**Eval-Driven開発** — LLMのためのTDD。evaluationでエージェントのふるまいをテストする:
- コードベース: `output == golden_answer`
- LLMベース: 別のClaudeが評価
- 人間によるグレーディング: リファレンス、低速

> **Evalハーネス** — evaluationをエンドツーエンドで実行するインフラ: 指示とツールの提供、タスクの同時実行、ステップの記録、出力のグレーディング、結果の集約。
>
> Anthropicの包括的なガイドを参照: [Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)

**Multi-Agentオーケストレーション** — シングルアシスタントからオーケストレーションされたチームへ:
```
Meta-Agent (Orchestrator)
├── Analyst (requirements)
├── Architect (design)
├── Developer (code)
└── Reviewer (validation)
```

### ADR-Driven開発

**パターン**: プレーンな英語のADRを書く → implement-adrスキルに渡す → ネイティブに実行

アーキテクチャ決定記録（ADR）とClaude Codeスキルを組み合わせると、アーキテクチャ決定が直接実装を促進するワークフローが生まれます。

**ワークフローステップ**:
1. **決定をドキュメント化する** ADR形式で（コンテキスト、決定、結果）
2. **実装スキルを作成する**（汎用または `implement-adr` 専用）
3. **ADRをプロンプトとして渡す** 明確な受け入れ基準を持つスキルに
4. **Claudeが実行する** ADRのアーキテクチャガイダンスに基づいて

**ADRテンプレートの例**:
```
# ADR-001: データベースマイグレーション戦略

## コンテキスト
レガシーMySQLスキーマをより良いJSONサポートのためにPostgreSQLに移行する必要がある。

## 決定
フィーチャーフラグを使ったインクリメンタルなデュアルライトパターンを使用する。

## 結果
- ポジティブ: ゼロダウンタイムマイグレーション
- ネガティブ: 移行期間中の一時的なコードの複雑さ
```

**実装ワークフロー**:
```bash
# 1. ADRを書く（プレーンな英語）
vim docs/adr/001-database-migration.md

# 2. 実装スキルに渡す
/implement-adr docs/adr/001-database-migration.md

# 3. ClaudeがADRガイダンスに基づいて実行する
# → マイグレーションスクリプトを作成
# → ORM設定を更新
# → フィーチャーフラグを追加
# → デュアルライトロジックを実装
```

**メリット**:
- ✅ **ドキュメント駆動**: アーキテクチャとコードが同期し続ける
- ✅ **ネイティブ実行**: 外部フレームワーク不要
- ✅ **追跡可能な決定**: 決定から実装までの明確な監査トレイル
- ✅ **チームの整合**: ADRが人間とAIの両方に意図を伝える

**ソース**: [Gur Sannikov embedded engineeringワークフロー](https://www.linkedin.com/posts/gursannikov_claudecode-embeddedengineering-aiagents-activity-7423851983331328001-DrFb)


### Tier 6: 最適化

| 名前 | 概要 | 最適な用途 | Claude適合度 |
|------|------|------------|-------------|
| **Iterative Loops** | 自律的な改善 | 最適化 | ⭐⭐⭐ コア |
| **Fresh Context** | タスクごとにリセット、ファイルに状態を持つ | 長い自律セッション | ⭐⭐⭐ パワーユーザー |
| **Prompt Engineering** | テクニックの基礎 | あらゆること | ⭐⭐⭐ 前提条件 |

**Iterative Refinement Loops** — 自律的な収束:
1. プロンプトを実行
2. 結果を観察
3. 結果 ≠ 「DONE」 → 改善して繰り返す

**Prompt Engineering** — すべてのClaude使用の基礎:
- Zero-Shot Chain of Thought: 「ステップバイステップで考えてください」
- Few-Shot Learning: 期待されるパターンの2〜3例
- 構造化プロンプト: 整理のためのXMLタグ
- 位置が重要: 長いドキュメントでは、質問を末尾に置く

**Fresh Contextパターン（Ralph Loop）** — タスクごとに新鮮なエージェントインスタンスを生成することでコンテキストの劣化を解決します。状態はチャット履歴ではなく、git + progressファイルに永続化されます。長い自律セッション（マイグレーション、夜間実行）に理想的です。実装については [Ultimate Guide - Fresh Context Pattern](./ultimate-guide.md#fresh-context-pattern-ralph-loop) を参照してください。


## SDDツールリファレンス

Spec-Driven Developmentを形式化するために3つのツールが登場しています:

| ツール | ユースケース | 公式ドキュメント | Claude統合 |
|--------|-------------|----------------|-----------|
| **Spec Kit** | グリーンフィールド、ガバナンス | [github.blog/spec-kit](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/) | `/speckit.constitution`, `/speckit.specify`, `/speckit.plan` |
| **OpenSpec** | ブラウンフィールド、変更管理 | [github.com/Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec) | `/openspec:proposal`, `/openspec:apply`, `/openspec:archive` |
| **Specmatic** | APIコントラクトテスト | [specmatic.io](https://specmatic.io) | MCPエージェント対応 |
| **Spec-to-Code Factory** | グリーンフィールド、ツール強制実装 | [github.com/SylvainChabaud/spec-to-code-factory](https://github.com/SylvainChabaud/spec-to-code-factory) | マルチエージェントリファレンス実装（BREAK→MODEL→ACT→DEBRIEF） |

### Spec Kit（グリーンフィールド）

5フェーズワークフロー:
1. Constitution: `/speckit.constitution` → ガードレール
2. Specify: `/speckit.specify` → 要件
3. Plan: `/speckit.plan` → アーキテクチャ
4. Tasks: `/speckit.tasks` → 分解
5. Implement: `/speckit.implement` → コード

### OpenSpec（ブラウンフィールド）

2フォルダアーキテクチャ:
```
openspec/
├── specs/      ← 現在の真実（安定）
└── changes/    ← 提案（一時的）
```

ワークフロー: 提案 → レビュー → 適用 → アーカイブ

### Specmatic（APIコントラクト）

- **コントラクトをテストとして**: OpenAPI仕様から数千のテストを自動生成
- **コントラクトをスタブとして**: 並行開発のためのモックサーバー
- **後方互換性**: 破壊的変更を検出


## 効果的な仕様書の書き方

> 2,500以上のエージェント設定ファイルの分析に基づく。
> ソース: [Addy Osmani](https://addyosmani.com/blog/good-spec/)

### 6つの必須コンポーネント

| コンポーネント | 含めるべきこと | 例 |
|--------------|--------------|-----|
| **コマンド** | フラグ付きで実行可能 | `npm test -- --coverage` |
| **テスト** | フレームワーク、カバレッジ、場所 | `vitest, 80%, tests/` |
| **プロジェクト構造** | 明示的なディレクトリ | `src/`, `lib/`, `tests/` |
| **コードスタイル** | 1例 > 段落 | 実際の関数を見せる |
| **Gitワークフロー** | ブランチ、コミット、PR形式 | `feat/name`、conventional commits |
| **境界** | 権限の階層 | 以下を参照 |

### 権限の階層

| 階層 | シンボル | 使用用途 |
|------|---------|---------|
| 常に実行する | ✅ | 安全なアクション、承認不要（lint、format） |
| まず確認する | ⚠️ | 高影響の変更（削除、公開） |
| 絶対にしない | 🚫 | ハードストップ（シークレットのコミット、force push main） |

### 指示の呪い

> ⚠️ 研究によると **指示が多いほど = 各指示への遵守率が低下する** ことが示されています。
>
> 解決策: ドキュメント全体ではなく、タスクごとに関連する仕様セクションだけを渡す。

### モノリシックvs モジュラー仕様

| プロジェクトサイズ | アプローチ |
|-----------------|----------|
| 小（10ファイル未満） | 単一仕様ファイル |
| 中（10〜50ファイル） | セクション分けした仕様、タスクごとに渡す |
| 大（50ファイル以上） | ドメインごとにサブエージェントルーティング |


## 組み合わせパターン

状況別の推奨スタック:

| 状況 | 推奨スタック | 備考 |
|------|------------|------|
| ソロMVP | SDD + TDD | 最小限のオーバーヘッド、品質重視 |
| 5〜10人チーム、グリーンフィールド | Spec Kit + TDD + BDD | ガバナンス + 品質 + コラボレーション |
| マイクロサービス | CDD + Specmatic | コントラクトファースト、並行開発 |
| 既存SaaS（100+フィーチャー） | OpenSpec + BDD | 変更追跡、仕様ドリフトなし |
| エンタープライズ10人以上 | BMAD + Spec Kit + Specmatic | フルガバナンス + コントラクト |
| LLMネイティブ製品 | Eval-Driven + Multi-Agent | 自己改善システム |


## クイックリファレンステーブル

| 手法 | レベル | 主な焦点 | チームサイズ | 学習曲線 |
|-----|-------|---------|------------|---------|
| BMAD | オーケストレーション | ガバナンス | 10人以上 | 高 |
| SDD | 仕様 | コントラクト | 任意 | 中 |
| Doc-Driven | 仕様 | 整合 | 任意 | 低 |
| Req-Driven | 仕様 | コンテキスト | 5人以上 | 中 |
| DDD | 仕様 | ドメイン | 5人以上 | 非常に高い |
| BDD | ふるまい | コラボレーション | 5人以上 | 中 |
| ATDD | ふるまい | コンプライアンス | 5人以上 | 中 |
| CDD | ふるまい | API | 5人以上 | 中 |
| FDD | デリバリー | フィーチャー | 10人以上 | 中 |
| Context Eng. | デリバリー | AIセッション | 任意 | 低 |
| TDD | 実装 | 品質 | 任意 | 低 |
| Eval-Driven | 実装 | AI出力 | 任意 | 中 |
| Multi-Agent | 実装 | 複雑さ | 任意 | 中 |
| Iterative | 最適化 | 改善 | 任意 | 低 |
| Prompt Eng. | 最適化 | 基礎 | 任意 | 非常に低い |


## ソース

### 公式ドキュメント（Tier 1）

- Anthropic: [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- Anthropic: [Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- Anthropic: [Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
- GitHub: [Spec-Driven Development Toolkit](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- Microsoft: [Spec-Driven Development with Spec Kit](https://developer.microsoft.com/blog/spec-driven-development-spec-kit)

### 手法リファレンス（Tier 2）

**SDD & Spec-First**
- Addy Osmani: [How to Write Good Specs for AI Agents](https://addyosmani.com/blog/good-spec/)
- Addy Osmani: [My AI Coding Workflow in 2026](https://addyosmani.com/blog/ai-coding-workflow/) — エンドツーエンドワークフロー: spec-first、コンテキストパッキング、TDD、gitチェックポイント
- Martin Fowler: [SDD Tools Analysis](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)
- InfoQ: [Spec-Driven Development](https://www.infoq.com/articles/spec-driven-development/)
- Kinde: [Beyond TDD - Why SDD is the Next Step](https://kinde.com/learn/ai-for-software-engineering/best-practice/beyond-tdd-why-spec-driven-development-is-the-next-step/)
- Tessl.io: [Spec-Driven Dev with Claude Code](https://tessl.io/blog/spec-driven-dev-with-claude-code/)

**BMAD**
- GMO Recruit: [The BMAD Method](https://recruit.group.gmo/engineer/jisedai/blog/the-bmad-method-a-framework-for-spec-oriented-ai-driven-development/)
- Benny Cheung: [BMAD - Reclaiming Control in AI Dev](https://bennycheung.github.io/bmad-reclaiming-control-in-ai-dev)
- GitHub: [BMAD-AT-CLAUDE](https://github.com/24601/BMAD-AT-CLAUDE)

**AIを使ったTDD**
- Steve Kinney: [TDD with Claude](https://stevekinney.com/courses/ai-development/test-driven-development-with-claude)
- Nathan Fox: [Taming GenAI Agents](https://www.nathanfox.net/p/taming-genai-agents-like-claude-code)
- Alex Op: [Custom TDD Workflow Claude Code](https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)

**BDD & DDD**
- Alex Soyes: [BDD Behavior-Driven Development](https://alexsoyes.com/bdd-behavior-driven-development/)
- Alex Soyes: [DDD Domain-Driven Design](https://alexsoyes.com/ddd-domain-driven-design/)
- Inflectra: [Behavior-Driven Development](https://www.inflectra.com/Ideas/Topic/Behavior-Driven-Development.aspx)

**コンテキストエンジニアリング**
- Intuition Labs: [What is Context Engineering](https://intuitionlabs.ai/articles/what-is-context-engineering)
- Manus.im: [Context Engineering for AI Agents](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus)

**Eval-Driven & Multi-Agent**
- Fireworks AI: [Eval-Driven Development with Claude Code](https://fireworks.ai/blog/eval-driven-development-with-claude-code)
- Brandon Casci: [Transform into a Dev Team using Claude Code Agents](https://www.brandoncasci.com/2025/09/21/how-to-transform-yourself-into-a-dev-team-using-claude-codes-ai-agents.html)
- The Unwind AI: [Claude Code's Multi-Agent Orchestration](https://www.theunwindai.com/p/claude-code-s-hidden-multi-agent-orchestration-now-open-source)

### ツールドキュメント（Tier 1）

- OpenSpec: [github.com/Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec)
- Spec Kit: [github.com/github/spec-kit](https://github.com/github/spec-kit)
- Specmatic: [specmatic.io](https://specmatic.io)
- Specmatic Article: [Spec-Driven Development with GitHub Spec Kit and Specmatic MCP](https://specmatic.io/article/spec-driven-development-api-design-first-with-github-spec-kit-and-specmatic-mcp/)

### 追加リファレンス

- Talent500: [Claude Code TDD Guide](https://talent500.com/blog/claude-code-test-driven-development-guide/)
- Testlio: [Acceptance Test-Driven Development](https://testlio.com/blog/what-is-acceptance-test-driven-development/)
- Monday.com: [Feature-Driven Development](https://monday.com/blog/rnd/feature-driven-development-fdd/)
- Paddo.dev: [Ralph Wiggum Autonomous Loops](https://paddo.dev/blog/ralph-wiggum-autonomous-loops/)
- Walturn: [Prompt Engineering for Claude](https://www.walturn.com/insights/mastering-prompt-engineering-for-claude)
- AWS: [Prompt Engineering with Claude on Bedrock](https://aws.amazon.com/blogs/machine-learning/prompt-engineering-techniques-and-best-practices-learn-by-doing-with-anthropics-claude-3-on-amazon-bedrock/)


## 参照

- [workflows/tdd-with-claude.md](./workflows/tdd-with-claude.md) — 実践的なTDDガイド
- [workflows/spec-first.md](./workflows/spec-first.md) — Spec-first開発
- [workflows/plan-driven.md](./workflows/plan-driven.md) — /planモードの使い方
- [workflows/iterative-refinement.md](./workflows/iterative-refinement.md) — 改善ループ
- [ultimate-guide.md#912](./ultimate-guide.md) — セクション9.12サマリー
