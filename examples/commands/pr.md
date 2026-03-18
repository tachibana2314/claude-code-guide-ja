---
layout: default
title: "プルリクエストの作成"
parent: コマンド
grand_parent: テンプレート
nav_order: 18
---


# プルリクエストの作成

変更を分析し、スコープの問題を検出して、プロジェクトの規約に従った適切に構造化された PR を作成します。

## プロセス

1. **変更の分析**: ファイル、コミット、ディレクトリから複雑さスコアを計算
2. **スコープの問題を検出**: PR が大きすぎるまたは無関係な変更が混在している場合に警告
3. **分割を提案**: 必要に応じてコミットをスコープ別にグループ化して別々の PR を提案
4. **情報を収集**: タイプ、ターゲットブランチ、ドラフトステータス、ラベルを確認
5. **コンテンツを生成**: TLDR + 説明 + チェックリストを作成
6. **PR を作成**: 適切なフォーマットで `gh pr create` を実行
7. **フォローアップをリマインド**: PR 後のチェックリスト（SonarQube、Claude レビュー）を表示

## 複雑さスコア

PR の分割が必要かどうかを検出するために PR の複雑さを計算します:

| 基準 | 重み | 説明 |
|-----------|--------|-------------|
| コードファイル | x2 | `*.ts, *.tsx`（テストを除く） |
| テストファイル | x0.5 | `*.test.ts, *.spec.ts` |
| 設定ファイル | x1 | `*.json, *.yml, *.md` |
| ディレクトリ | x3 | 異なる `src/*` ディレクトリ |
| コミット | x1 | コミット数 |

**しきい値**: 0-15 ✅ 通常 | 16-25 ⚠️ 大きい | 26+ 🔴 分割推奨

## スコープの整合性

| パターン | 判定 |
|---------|---------|
| 単一スコープ | ✅ OK |
| 関連するスコープ（セッション + カレンダー） | ✅ OK |
| 無関係なスコープ（決済 + 認証） | 🔴 分割 |
| feat + fix 同じスコープ | ✅ OK |
| feat + fix 異なるスコープ | 🔴 分割 |

## 分割提案フォーマット

分割が推奨される場合に表示します:

```
🔴 Scope trop large (score: 32)

Commits par scope :
├── payments (5 commits, 8 fichiers)
│   ├── feat(payments): add Stripe checkout
│   └── fix(payments): handle currency
│
└── notifications (3 commits, 6 fichiers)
    └── feat(notifications): add email templates

💡 Suggestion :
1. PR #1 : feature/payments-stripe → Commits payments
2. PR #2 : feature/notifications → Commits notifications

Options :
[A] Continuer avec une seule PR (non recommandé)
[B] Découper (semi-auto - commandes git fournies)
[C] Voir détail fichiers
```

**セミオート分割**はコピー&ペーストのコマンドを提供します:
```bash
git checkout develop
git checkout -b feature/payments-stripe
git cherry-pick abc1234 def5678
git push -u origin feature/payments-stripe
```

## 確認する質問

1. **タイプ**: feature | fix | tech | docs | security
2. **ターゲットブランチ**: 最近のブランチを表示（develop、main、その他）
3. **ドラフト**: Yes（WIP）| No（レビュー準備完了）
4. **ラベル**: タイプに基づく + オプション（breaking-change、security）

## PR タイトルフォーマット

```
<type>(<scope>): <description>
```

例:
- `feat(payments): add Stripe checkout integration`
- `fix(sessions): resolve timezone calculation bug`

## PR 本文テンプレート

```markdown
## TLDR
<!-- 最大2行 - エグゼクティブサマリー -->


## Type
{Feature | Fix | Tech | Docs | Security}

## Description
{コンテキストと変更内容}

## Technical Changes
{主な変更のリスト}

## Tests
- [ ] ユニットテストを追加/合格
- [ ] 手動テスト完了

## Checklist
- [ ] コードが規約に従っている
- [ ] console.log が残っていない
- [ ] 型OK（`pnpm typecheck`）


🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## 利用可能なラベル

| ラベル | 色 | 使用タイミング |
|-------|-------|----------|
| `feature` | 🟢 | 新機能 |
| `fix` | 🔴 | バグ修正 |
| `tech` | 🔵 | リファクタリング、技術的負債 |
| `docs` | 📘 | ドキュメントのみ |
| `security` | 🟣 | セキュリティ修正 |
| `breaking-change` | ⚫ | 破壊的変更 |
| `WIP` | 🟡 | 作業中（ドラフト） |

## 実行するコマンド

```bash
# 1. ベースブランチを取得（通常 develop）
BASE_BRANCH="develop"

# 2. 複雑さスコアを計算
CODE=$(git diff --name-only $BASE_BRANCH..HEAD | grep -E '\.(ts|tsx)$' | grep -v test | wc -l)
TESTS=$(git diff --name-only $BASE_BRANCH..HEAD | grep -E '\.test\.|\.spec\.' | wc -l)
DIRS=$(git diff --name-only $BASE_BRANCH..HEAD | cut -d'/' -f1-2 | sort -u | wc -l)
COMMITS=$(git rev-list --count $BASE_BRANCH..HEAD)
SCORE=$((CODE * 2 + TESTS / 2 + DIRS * 3 + COMMITS))

# 3. コミットからスコープを取得
git log --oneline $BASE_BRANCH..HEAD --format="%s" | sed -n 's/^\w*(\([^)]*\)).*/\1/p' | sort | uniq -c

# 4. 選択のための最近のブランチ
git branch --sort=-committerdate --format='%(refname:short)' | head -5

# 5. PR を作成
gh pr create \
  --title "<type>(<scope>): <description>" \
  --body "$BODY" \
  --base $BASE_BRANCH \
  --label "<label>" \
  --draft  # WIP の場合
```

## PR 作成後の出力

PR 作成後、常に以下を表示します:

```
✅ PR créée : https://github.com/org/repo/pull/XXX

📋 Prochaines étapes automatiques :
   • SonarQube analysera la qualité du code (bugs, vulnérabilités, code smells)
   • Claude Code Review fournira un feedback IA sur votre PR

⏳ Pensez à surveiller ces analyses dans les prochaines minutes.
   Si des problèmes sont détectés, corrigez-les avant de demander une review humaine.
```

## エッジケース

| 状況 | 動作 |
|-----------|----------|
| コミットにスコープがない | ディレクトリで分析 |
| 非コンベンショナルコミット | 警告 + タイプを手動で確認 |
| コミットなし（ベースと同じ） | エラー: 「変更がありません」 |
| 単一コミット | コミットメッセージをタイトルとして使用 |
| マージコミット | 無視（`--no-merges`） |

## 使用法

```
/pr
/pr --base main
/pr --draft
```

ターゲット: $ARGUMENTS（オプション: --base、--draft）
