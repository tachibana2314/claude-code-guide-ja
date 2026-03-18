---
title: "チームAIインストラクション管理"
description: "プロファイルベースのモジュールアセンブリを使ってCLAUDE.mdを複数の開発者チームにスケールさせる"
tags: [workflow, team, claude-md, configuration]
---

# チームAIインストラクション管理

AIインストラクション（CLAUDE.md、.cursorrules）をチーム全体で断片化させずに管理する。

**パターン**: プロファイルベースのモジュールアセンブリ — 共有モジュール + 開発者ごとのプロファイル + 自動アセンブラー。

**使う場面**: 5人以上の開発者チーム、複数のAIツール（Claude Code + Cursor/Windsurf）、OS混在環境。
**スキップする場面**: ソロ開発者、均質なチーム（同じツール、同じOS）、短期プロジェクト（3ヶ月未満）。

---

## 問題: N x M x P の断片化

チームが成長すると、AIインストラクションはすぐに断片化します:

| 要因 | 値 | 例 |
|--------|--------|---------|
| **N人の開発者** | 5〜20 | Alice、Bob、Charlie... |
| **Mのツール** | 2〜4 | Claude Code、Cursor、Windsurf、Copilot |
| **PのOS** | 2〜3 | macOS、Linux、WSL |

**バリアント数の合計**: N x M x P = 5 x 3 x 2 = **30通りの設定**。

システムがない場合に起きること:

```
週1: チームが共有のCLAUDE.mdに合意
週3: AliceがTypeScriptの厳格ルールをローカルに追加
週5: BobがAliceのファイルをコピーして、ルールの半分を削除
週8: 新入社員のCharlieがBobの古いコピーを入手
週12: 5人の開発者、5つの異なるCLAUDE.mdファイル、誰が正規版か不明
```

**根本原因**: CLAUDE.mdがモジュール化された設定ではなく、モノリシックなファイルとして扱われている。

---

## アーキテクチャ概要

```
profiles/                    modules/
├── alice.yaml               ├── core-standards.md
├── bob.yaml                 ├── git-workflow.md
├── charlie.yaml             ├── typescript-rules.md
│                            ├── test-conventions.md
│                            ├── macos-paths.md
│                            ├── linux-paths.md
│                            ├── cursor-rules.md
│                            └── communication-verbose.md
│
├── skeleton/
│   └── claude-skeleton.md   ← {{MODULE:name}}プレースホルダーを持つテンプレート
│
└── sync-ai-instructions.ts  ← プロファイルを読む → モジュールを注入 → 出力を書く
        │
        ▼
output/
├── alice/CLAUDE.md          ← 生成済み（読み取り専用）
├── bob/CLAUDE.md
└── charlie/CLAUDE.md
```

**フロー**: プロファイル（YAML）+ スケルトン（テンプレート）+ モジュール（フラグメント）→ アセンブラー → 生成されたCLAUDE.md

---

## フェーズ1: 現在のCLAUDE.mdの監査

**目標**: すべての行をユニバーサル、条件付き、個人的なものに分類する。

```markdown
# 監査テンプレート

## ユニバーサル（全開発者、全ツール）
- アーキテクチャ: ヘキサゴナル
- テスト: PR前に必ずパス
- 命名規則: ファイルはkebab-case

## 条件付き（ツールまたはOSによる）
- Cursor: @filenameシンタックスを使用 → モジュール: cursor-rules
- macOSパス: /opt/homebrew → モジュール: macos-paths
- Linuxパス: /usr/local → モジュール: linux-paths

## 個人的（個人の好み）
- スタイル: 詳細な説明 → プロファイルの設定
- 言語: フランス語のコメント → プロファイルの設定
```

**計測コマンド**:
```bash
wc -l CLAUDE.md  # モジュール化前の総行数
# 各行に[U]niversal、[C]onditional、[P]ersonalとタグを付ける
# カテゴリ別に数えてモジュールの分割を見積もる
```

**典型的な結果**: 60%ユニバーサル、25%条件付き、15%個人的。

---

## フェーズ2: モジュールの抽出

**目標**: テーマグループごとに1つの`.md`ファイル。

**推奨構成**:

```
modules/
├── core-standards.md         # アーキテクチャ、命名規則、パターン（全開発者）
├── git-workflow.md           # Git規約（全開発者）
├── typescript-rules.md       # TS strictの設定（TypeScriptの場合）
├── test-conventions.md       # テストパターン（全開発者）
├── macos-paths.md            # macOS固有のパス（macOSの場合）
├── linux-paths.md            # Linuxのパス（Linuxの場合）
├── cursor-rules.md           # Cursor固有のルール（Cursorの場合）
└── communication-verbose.md  # 詳細な説明スタイル（好む場合）
```

**モジュール形式**（各モジュールは独立したMarkdownフラグメント）:

```markdown
<!-- modules/typescript-rules.md -->
## TypeScriptルール

- strictモードを使用: tsconfigで`"strict": true`
- Unionには`interface`より`type`を優先
- `any`は禁止 — `unknown` + 型ガードを使用
- 境界でのランタイム検証にはZod
```

**ガイドライン**:
- モジュールは自己完結型に（モジュール間の相互参照なし）
- 1モジュールあたり15〜50行がベスト
- 対象者ではなくドメインにちなんでモジュールを命名
- 1モジュール = 変更する理由が1つ

---

## フェーズ3: 開発者プロファイルの作成

**目標**: 開発者ごとに1つのYAML、モジュールをリストアップ。

```yaml
# profiles/alice.yaml
name: "Alice"
os: "macos"
tools:
  - claude-code
  - cursor
communication_style: "concise"
modules:
  core:
    - core-standards
    - git-workflow
    - typescript-rules
    - test-conventions
  conditional:
    - macos-paths          # os: macosの場合に自動含まれる
    - cursor-rules         # toolsにcursorがある場合に自動含まれる
preferences:
  language: "english"
```

**プロファイルルール**:
- `core`モジュール: 全開発者に含まれる（チームスタンダード）
- `conditional`モジュール: `os`と`tools`フィールドに基づいて含まれる
- `preferences`: スケルトン変数に注入される個人設定

**新しいチームメンバー向けテンプレート**: [profile-template.yaml](../../examples/team-config/profile-template.yaml)を参照

---

## フェーズ4: アセンブラースクリプトの作成

**目標**: プロファイルを読み込み、モジュールを注入し、CLAUDE.mdを出力するスクリプト。

```typescript
// sync-ai-instructions.ts (簡略版 〜30行)
import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { parse } from 'yaml';
import { join } from 'path';

const profile = parse(readFileSync(`profiles/${process.argv[2]}.yaml`, 'utf8'));
let skeleton = readFileSync('skeleton/claude-skeleton.md', 'utf8');

// プロファイルからモジュールを収集
const modules = [...profile.modules.core, ...profile.modules.conditional];

// 各プレースホルダーをモジュールコンテンツで置換
for (const mod of modules) {
  const content = readFileSync(`modules/${mod}.md`, 'utf8');
  skeleton = skeleton.replace(`{{MODULE:${mod}}}`, content);
}

// 未使用のプレースホルダーを削除
skeleton = skeleton.replace(/\{\{MODULE:\w+\}\}/g, '');

// 出力を書き込む
const outDir = `output/${process.argv[2]}`;
mkdirSync(outDir, { recursive: true });
writeFileSync(join(outDir, 'CLAUDE.md'), skeleton);
console.log(`Generated ${outDir}/CLAUDE.md (${modules.length} modules)`);
```

**実行方法**:
```bash
npx ts-node sync-ai-instructions.ts alice   # 単一の開発者
npx ts-node sync-ai-instructions.ts --all   # 全プロファイルを生成
npx ts-node sync-ai-instructions.ts --check # ずれがないか確認
```

完全なテンプレート: [sync-script.ts](../../examples/team-config/sync-script.ts)

---

## フェーズ5: CIドリフト検出

**目標**: 出力ファイルがプロファイル/モジュールと同期していない場合に検出する。

```yaml
# .github/workflows/ai-instructions-check.yml
name: AIインストラクション ドリフトチェック
on:
  push:
    paths:
      - 'modules/**'
      - 'profiles/**'
      - 'skeleton/**'
  schedule:
    - cron: '0 9 * * 1-5'  # 平日午前9時

jobs:
  check-drift:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npx ts-node sync-ai-instructions.ts --check
      - name: ドリフトが検出された場合に失敗
        run: |
          if git diff --quiet output/; then
            echo "ドリフトなし"
          else
            echo "::error::AIインストラクションが同期されていません！"
            git diff output/
            exit 1
          fi
```

**検出するもの**:
- モジュールが編集されたがアセンブラーが再実行されていない
- プロファイルが追加されたが出力のCLAUDE.mdが存在しない
- 開発者が生成済みのCLAUDE.mdを手動で編集した

**ポリシー**: 生成されたファイルは読み取り専用。すべての変更はプロファイル/モジュールを通じて行い、その後アセンブラーを再実行する。

---

## フェーズ6: 新しい開発者のオンボーディング

**目標**: 新しい開発者が5分以内にCLAUDE.mdを取得できる。

```bash
# 1. リポジトリをクローン
git clone <repo>

# 2. プロファイルテンプレートをコピー
cp examples/team-config/profile-template.yaml profiles/dave.yaml
# 編集: name、os、tools、modules

# 3. 生成
npx ts-node sync-ai-instructions.ts dave

# 4. インストール
cp output/dave/CLAUDE.md .claude/CLAUDE.md
```

**CLAUDE.mdの配置に関するリマインダー**:
- プロジェクト全体: `project/CLAUDE.md`（コミット済み、チーム規約用）
- 個人的なオーバーライド: `.claude/CLAUDE.md`（.gitignore済み、個人の好み用）

---

## トラブルシューティング

| 問題 | 原因 | 解決策 |
|---------|-------|-----|
| 生成ファイルが長すぎる | モジュールが多すぎる | プロファイルを見直す: めったに使わないモジュールを削除 |
| 出力にモジュールがない | スケルトンのプレースホルダーのタイポ | `{{MODULE:name}}`がファイル名と一致するか確認 |
| CIドリフトアラート | モジュール編集後に出力が再生成されていない | `sync-ai-instructions.ts`を実行してコミット |
| 開発者AはBにないルールを持っている | 想定内 — それが目的 | そのDevのプロファイルが正しいか確認 |
| マージ後の古い出力 | マージが再生成をトリガーしなかった | マージ後にアセンブラーを実行（gitフックを追加） |

---

## スケーリングのしきい値

| チームサイズ | アプローチ |
|-----------|----------|
| 1〜2人 | 共有CLAUDE.md + 優先順位ルール（[セクション3.4](../ultimate-guide.md#34-precedence-rules)） |
| 3〜5人、同一ツール | 任意: プロファイルなしのモジュールのみ |
| 5人以上または複数ツール | プロファイルベースのモジュールアセンブリ（このワークフロー） |
| 20人以上 | CLAUDE.md設定サーバー + PRベースのモジュール変更を検討 |

---

## 測定結果

本番チームからの実績（5人の開発者、3つのツール、2つのOS）:

| 指標 | 変更前 | 変更後 |
|--------|--------|-------|
| CLAUDE.mdの行数 | 〜380（モノリシック） | 〜185（アセンブルされた） |
| トークン削減 | — | 消費コンテキストが59%削減 |
| 抽出されたモジュール数 | 0 | 12 |
| オンボーディング時間 | 「誰かのファイルをコピー」 | 5分（テンプレート + 生成） |
| ドリフト発生件数 | 毎週 | 0件（CIが検出） |

---

## 関連

- [セクション3.5 チーム設定のスケール](../ultimate-guide.md#35-team-configuration-at-scale) — 概念の概要と測定結果
- [セクション3.4 優先順位ルール](../ultimate-guide.md#34-precedence-rules) — Claudeが複数のCLAUDE.mdファイルを読む仕組み
- [profile-template.yaml](../../examples/team-config/profile-template.yaml) — プロファイルテンプレート
- [claude-skeleton.md](../../examples/team-config/claude-skeleton.md) — スケルトンテンプレート
- [sync-script.ts](../../examples/team-config/sync-script.ts) — 完全なアセンブラースクリプト
