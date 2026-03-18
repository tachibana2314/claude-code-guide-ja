---
name: commit
description: "ステージされた変更に対してConventional Commitメッセージを生成"
---

# Conventional Commit

ステージされた変更を分析し、Conventional Commitメッセージを生成する。

## 手順

1. `git diff --cached` でステージされた変更を確認
2. 変更の性質を分析
3. 以下のフォーマットに従ってコミットメッセージを生成

## コミットフォーマット

```
<type>(<scope>): <subject>

[任意の本文]

[任意のフッター]
```

### タイプ
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメントのみの変更
- `style`: フォーマット、セミコロン追加等
- `refactor`: バグ修正でも機能追加でもないコード変更
- `perf`: パフォーマンス改善
- `test`: テストの追加・修正
- `chore`: メンテナンスタスク

### ルール
- subject: 命令形、末尾にピリオドなし、最大50文字
- body: WHATとWHYを説明（HOWではなく）
- footer: 破壊的変更、Issue参照

## 例

```
feat(auth): パスワードリセット機能を追加

メール認証付きのパスワードリセットフローを実装。
ユーザーがリセットリンクをリクエストし、新しいパスワードを設定可能に。

Closes #123
```
