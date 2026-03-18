---
layout: default
title: "コンテキストの復元"
parent: コマンド
grand_parent: テンプレート
nav_order: 3
---


# コンテキストの復元

`/clear` 後にコンテキストを復元し、最近の作業とプロジェクトの状態をまとめます。

## 目的

`/clear` でコンテキストをクリアした後、以下を素早く把握するためのコマンドです:
- 最近変更されたファイル
- 現在のプロジェクト状態
- 未解決の TODO と Issue
- 作業を再開する場所

## 手順

### ステップ 1: Git 履歴の分析

```bash
# 最近のコミット（最新10件）
git log --oneline -10

# 直近5コミットで変更されたファイル
git diff --stat HEAD~5 2>/dev/null || git diff --stat $(git rev-list --max-parents=0 HEAD)

# 現在のブランチとステータス
git branch --show-current
git status --short
```

### ステップ 2: 最近の変更サマリー

```bash
# 今日の変更
git log --oneline --since="midnight" --author="$(git config user.name)" 2>/dev/null

# コミットされていない作業
git diff --name-only
git diff --cached --name-only
```

### ステップ 3: TODO/FIXME スキャン

```bash
# 最近変更されたファイルの未解決マーカーを検索
git diff --name-only HEAD~5 2>/dev/null | head -20 | xargs grep -n "TODO\|FIXME\|XXX\|HACK" 2>/dev/null | head -30
```

### ステップ 4: プロジェクト状態の確認

```bash
# 一般的な状態インジケーターを確認
[ -f "package.json" ] && echo "📦 Node project: $(jq -r '.name // "unnamed"' package.json)"
[ -f "Cargo.toml" ] && echo "🦀 Rust project: $(grep '^name' Cargo.toml | head -1)"
[ -f "pyproject.toml" ] && echo "🐍 Python project"
[ -f "go.mod" ] && echo "🐹 Go project: $(head -1 go.mod | cut -d' ' -f2)"

# ブランチ名からブランチの目的を把握
BRANCH=$(git branch --show-current)
echo "🌿 Branch: $BRANCH"
```

## 出力フォーマット

構造化されたサマリーを表示します:


### 📍 コンテキスト復元完了

**プロジェクト**: [package.json/Cargo.toml などから取得した名前]
**ブランチ**: [現在のブランチ]
**最終アクティビティ**: [最後のコミットの時刻]

### 🔄 最近の作業（直近5コミット）

1. [コミットメッセージ 1] - [影響を受けたファイル]
2. [コミットメッセージ 2] - [影響を受けたファイル]
...

### 📝 コミットされていない変更

- [変更内容の簡単な説明付きの変更ファイル一覧]

### ⚠️ 未解決の TODO

- [ファイル:行] TODO: [説明]
- [ファイル:行] FIXME: [説明]

### 🎯 推奨される次のステップ

最近のアクティビティに基づいて:
1. [パターンから推測される最も可能性の高い次のアクション]
2. [代替フォーカスエリア]


## 使用例

**長期休暇後:**
```
/catchup
```
→ 完全なコンテキスト復元

**クイックステータス確認:**
```
/catchup --brief
```
→ コミットとコミットされていない変更のみ

**特定のエリアにフォーカス:**
```
/catchup auth
```
→ 認証関連の変更のみにフィルタリング

## プロのヒント

1. **`/clear` の前にドキュメント化する**: コンテキストをクリアする前に、コミットメッセージや CLAUDE.md に簡単なメモを残す
2. **Memory Bank と組み合わせる**: 永続的な状態管理のために `.claude/memory/` ファイルと組み合わせる
3. **ブランチ命名**: コンテキスト復元を助けるために説明的なブランチ名を使用する（例: `feat/user-auth`）

$ARGUMENTS
