---
layout: default
title: "Changelogフラグメント: PRごとのドキュメントの強制"
parent: ワークフロー
grand_parent: ガイド
nav_order: 3
---

# Changelogフラグメント: PRごとのドキュメントの強制

PRごとに、リリース時ではなく実装時にドキュメントを作成することを確実にする3層強制パターン。

---

## 問題

単一の`CHANGELOG.md`ファイルは活発なチームでは機能しなくなります。同じファイルに触れる3つのオープンなフィーチャーブランチは、すべてのマージでマージコンフリクトを引き起こします。誰かがコンフリクトを解決し、行を落とし、リリースノートが公開される前に間違ったものになってしまいます。

より深い問題はタイミングです。「リリース時にドキュメントを作成する」は合理的に聞こえますが、PR #840を3週間後に見て、ユーザーにとって何が変わったかを再構築しようとするまでそうです。コミットは`fix session handling`と言っています。開発者は別のタイムゾーンにいます。コンテキストは消えています。

CIゲートのない強制は、changelogがうんざりする仕事になることを意味します。誰かがリリースごとに時間的プレッシャーの下でgit logから空白を埋めながら人々を追いかけなければなりません。

解決策: PRごとに1つのYAMLフラグメント、実装中に書かれ、CIで検証され、リリース時に自動的にアセンブルされる。

---

## 3層アーキテクチャ

システムが機能するのは、強制が3つの独立したレベルで行われるからです。各層は異なる失敗モードをキャッチします。

### 層1: CLAUDE.mdワークフロールール

最初の層は、すべてのセッションでClaude Codeのコンテキストにロードされるルールです。フラグメントワークフロー全体をエンコードするので、PRの作成を依頼されたときにClaudeが自律的に完了できます。

```markdown
# git-workflow.md (CLAUDE.md経由でロード)

## Changelogフラグメント — すべてのPRの前に必須

PRを作成する前に、必ずchangelogフラグメントを生成してください。

### ステップ

1. **git diffから推測** — `git diff main...HEAD`を分析して以下を決定:
   - `type`: feat | fix | perf | refactor | security | docs | chore
   - `scope`: 影響を受ける機能領域（auth、sessions、apiなど）
   - `title`: 1行のユーザー向けの要約（80文字未満）

2. **フラグメントを作成** — `pnpm changelog:add`を実行するか直接書く:
   ```
   changelog/fragments/{PR_NUMBER}-{slug}.yml
   ```

3. **検証** — `pnpm changelog:validate changelog/fragments/{file}.yml`を実行

4. **PRと一緒にコミット** — 同じブランチにフラグメントを含める

### フラグメントスキーマ

```yaml
pr: 886                    # ファイル名のプレフィックスと一致しなければならない
type: fix                  # feat|fix|perf|refactor|security|docs|chore
scope: "visiochat"
title: "Fix empty chat after SSE race condition"   # < 80文字
description: |             # 任意 — 実装ではなくユーザーへの影響を説明
  SSEワークプランがAIストリームの完了前に発火し、ChatWrapperが
  0メッセージでマウントされる原因となっている。
breaking: false
migration: false           # PRがDBマイグレーションを追加する場合はtrueに設定
```

### バイパス

ユーザーへの影響がないPR（CI設定、deps更新、リリースコミット）には`skip-changelog`ラベルを追加する。
```

このルールは、Claude Codeを単なるコーディングツールではなく、強制の参加者にします。開発者が「PRを作ってください」と言うと、Claudeはdiffからフラグメントのコンテンツを推測し、PRを開く前に作成します。

### 層2: UserPromptSubmitフック（動作の検出）

2番目の層は、意図がアクションになる前にインターセプトします。開発者がPR作成の意図を示すものを入力すると、フックはchangelogフラグメントが言及されたかどうかを確認します。

```bash
# .claude/hooks/smart-suggest.sh（抜粋 — Tier 0の強制）

# PR作成の意図を検出
if echo "$PROMPT_LC" | grep -qE '(create.*pr|open.*pr|make.*pr|pull.?request|push.*pr)'; then
    # フラグメントが言及されていない → まず作成ステップにリダイレクト
    if ! echo "$PROMPT_LC" | grep -qE '(changelog|fragment|skip-changelog)'; then
        suggest "pnpm changelog:add" \
            "マージ前に必須 — changelog/fragments/{PR}-{slug}.ymlを作成"
    else
        # すでに言及している → 通常通りPRコマンドを提案
        suggest "/pr" "構造化された説明を含むPR作成"
    fi
fi
```

フックは`UserPromptSubmit`です: ノンブロッキング、プロンプトごとに最大1つの提案、一致しない場合はサイレント。Claude Codeがプロンプトを処理する前に実行されるので、Claudeが何かを始める前に開発者はリマインダーをインラインで見ます。

条件ロジック（`if X without Y`）がここでの重要なパターンです。一括ブロッカーではなく、コンテキストに適応します。開発者がすでにフラグメントを言及している場合、通常の提案が得られます。していない場合、強制リマインダーが得られます。

**3層アーキテクチャを持つ完全なフック**: [`examples/hooks/bash/smart-suggest.sh`](../../examples/hooks/bash/smart-suggest.sh)

### 層3: CI強制（GitHub Actions）

3番目の層はハードゲートです。メインブランチをターゲットとするすべてのPRで2つの独立したジョブが実行されます。

**`check-fragment`ジョブ**: まずバイパスラベルを確認し（クローズドリスト）、次に`changelog/fragments/{PR_NUMBER}-*.yml`が存在して構造検証をパスすることを要求します。

```yaml
- name: フラグメントの存在と有効性を確認
  env:
    PR_NUMBER: ${{ github.event.pull_request.number }}
    PR_LABELS: ${{ toJson(github.event.pull_request.labels.*.name) }}
  run: |
    SKIP_LABELS=("skip-changelog" "dependencies" "release" "chore: deps")
    for LABEL in "${SKIP_LABELS[@]}"; do
      if echo "$PR_LABELS" | grep -q "\"$LABEL\""; then
        echo "バイパスラベルを検出 — フラグメント不要"
        exit 0
      fi
    done

    FRAGMENT=$(ls "changelog/fragments/${PR_NUMBER}-"*.yml 2>/dev/null | head -1)
    if [ -z "$FRAGMENT" ]; then
      echo "フラグメントがありません。実行してください: pnpm changelog:add"
      exit 1
    fi

    pnpm tsx changelog/scripts/validate.ts "$FRAGMENT"
```

**`check-migration-flag`ジョブ**（独立して実行、バイパスなし）: `git diff --name-only --diff-filter=A`で新しいSQLマイグレーションファイルを検出します。マイグレーションが存在しフラグメントに`migration: false`が含まれている場合、失敗します。このジョブはラベルでバイパスできません — マイグレーションを追加する`skip-changelog`のPRでも引き続きチェックが実行されます。

2つのジョブは意図的に独立しています。PRはフラグメント作成をバイパス（ラベル経由）できますが、マイグレーションチェックには失敗する可能性があります。

---

## リリース時のフラグメントアセンブリ

フラグメントはPRがマージされるにつれて`changelog/fragments/`に蓄積されます。リリース時に1つのコマンドでバージョン管理されたCHANGELOGセクションにアセンブルします。

```bash
pnpm changelog:assemble --version 1.8.0 [--dry-run]
```

実行内容:
1. すべての`changelog/fragments/*.yml`を読み込む
2. 固定順序でタイプ別にグループ化（feat、fix、perf、refactor、security、docs、chore）
3. `breaking: true`のエントリを専用の`🔨 Breaking Changes`セクションに追加
4. `migration: true`のエントリに`⚠️ Migration DB.`でインラインアノテーションを付ける
5. `CHANGELOG.md`の`## [Next Release]`プレースホルダーを置換
6. フラグメントを`changelog/fragments/released/{version}/`にアーカイブ

出力:
```markdown
## [1.8.0] - 2026-03-15

### 🔨 Breaking Changes
- **Remove legacy token format (#871)** — v1.6.0以前に発行されたトークンは無効です。

### ✨ New Features
- **Add real-time presence indicators (#892)**

### 🔧 Bug Fixes
- **Fix empty chat after SSE race condition (#886)** — SSEワークプランがAI
  ストリームの完了前に発火し、ChatWrapperが0メッセージでマウントされる原因となっている。
```

---

## なぜ3層で1層ではないのか

各層は異なる失敗モードをキャッチします:

| 層 | キャッチする失敗 | タイミング |
|-------|---------------|------|
| CLAUDE.mdルール | ClaudeがワークフローをConvolutional | すべてのセッション |
| UserPromptSubmitフック | 開発者が考えずに「PRを作ってください」と入力する | プロンプト前 |
| CIゲート | フラグメントがスキップされたか破損している | マージ前 |

単一のCIゲートでは問題の発見が遅すぎます — PRがすでに開いた後に開発者はコンテキストを切り替えて戻る必要があります。フックは意図の時点でキャッチします。CLAUDE.mdルールはタスクが与えられたときにClaudeが自律的に処理することを意味します。

層は競合しません。互いを強化します。フックの提案を見た開発者は`pnpm changelog:add`を実行します。ClaudeはCLAUDE.mdルールに従って出力を検証します。CIはマージ前にすべてを確認します。

---

## このパターンの採用

TypeScriptスクリプト（add、validate、assemble、audit）はMéthode Aristoteスタックに固有です。3層強制パターンはそうではありません — 任意のフラグメント形式、任意のCIシステム、任意のアセンブラーで機能します。

**最小限のセットアップ:**

1. **フラグメントスキーマを定義する**（YAML、JSON、スタックに合うもの）
2. **CLAUDE.mdルールを追加する** — 作成ワークフローをエンコードしてClaudeが自律的に処理できるようにする
3. **`UserPromptSubmit`フックを追加する** — `if PR-intent without fragment-mention → suggest`パターンを使用
4. **CIジョブを追加する** — マージ前にフラグメントの存在を確認する

フックパターンはすべての必須ワークフローステップに一般化できます。「changelogフラグメント」を「ADR」、「マイグレーションフラグ」、「テストカバレッジチェック」に置き換えても — 条件付き検出ロジックは同じです。

---

## 関連情報

- フックの例: [`examples/hooks/bash/smart-suggest.sh`](../../examples/hooks/bash/smart-suggest.sh)
- フックのドキュメント: [UserPromptSubmitフック](../ultimate-guide.md)（「UserPromptSubmit」で検索）
- フラグメントバリデーターとアセンブラースクリプト: Méthode Aristoteリポジトリで利用可能
