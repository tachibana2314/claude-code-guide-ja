---
name: commit
description: "ステージされた変更に対して Conventional Commit メッセージを生成する"
---

# Conventional Commit

ステージされた変更に対して Conventional Commit メッセージを生成します。

## 手順

1. `git diff --cached` でステージされた変更を確認する
2. 変更の性質を分析する
3. 以下のフォーマットに従ってコミットメッセージを生成する

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
- body: WHAT と WHY を説明（HOW ではなく）
- footer: 破壊的変更、Issue 参照

## 例

```
feat(auth): add password reset functionality

Implement password reset flow with email verification.
Users can now request a reset link and set new password.

Closes #123
```

```
fix(api): prevent race condition in order processing

Add mutex lock to ensure orders are processed sequentially.
This fixes duplicate charge issues reported by users.

Fixes #456
```

```
refactor(cart): extract pricing logic to separate module

No functional changes. Improves testability and
separates concerns for future discount feature.
```

## 実行

ステージされた変更を分析した後、コミットメッセージを提案します。
`git commit -m "..."` を実行する前に確認を求めます。

$ARGUMENTS
