---
layout: default
title: "Git Worktree ステータス"
parent: コマンド
grand_parent: テンプレート
nav_order: 10
---


# Git Worktree ステータス

`/git-worktree` によって起動されたバックグラウンド検証タスク（型チェック、テスト、ビルド）を確認します。

**コア原則:** 開発フローを中断せずに worktree の健全性に関するノンブロッキングフィードバックを提供。

**関連コマンド:** [Worktree ライフサイクルスイート](./git-worktree.md) | [`/git-worktree`](./git-worktree.md) | [`/git-worktree-remove`](./git-worktree-remove.md) | [`/git-worktree-clean`](./git-worktree-clean.md)

## プロセス

1. **現在の Worktree を検出**: git worktree 内にいるか確認
2. **ログファイルを確認**: バックグラウンドタスクの結果のために `.worktree-logs/` を読み込む
3. **結果を解析**: 合格/不合格の数、エラーを抽出
4. **ステータスを報告**: アクション可能な次のステップを含むカラーコードのサマリー

## Worktree の検出

```bash
# worktree 内にいるか確認（メインリポジトリではない）
git rev-parse --git-common-dir 2>/dev/null | grep -q "\.git/worktrees" || {
  echo "Not inside a worktree. Use from a worktree directory."
  exit 1
}

# worktree 情報を取得
WORKTREE_PATH=$(git rev-parse --show-toplevel)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
MAIN_REPO=$(git rev-parse --git-common-dir | sed 's|/\.git/worktrees/.*||')
```

## バックグラウンドタスクの確認

### 型チェックのステータス

```bash
LOG=".worktree-logs/typecheck.log"

if [ -f "$LOG" ]; then
  if grep -q "error TS" "$LOG"; then
    ERROR_COUNT=$(grep -c "error TS" "$LOG")
    echo "Type check: FAIL ($ERROR_COUNT errors)"
    # 最初の5つのエラーを表示
    grep "error TS" "$LOG" | head -5
  else
    echo "Type check: PASS"
  fi
elif pgrep -f "tsc --noEmit" > /dev/null; then
  echo "Type check: RUNNING..."
else
  echo "Type check: NOT RUN"
fi
```

### テストのステータス

```bash
LOG=".worktree-logs/tests.log"

if [ -f "$LOG" ]; then
  if grep -q '"numFailedTests":0' "$LOG"; then
    TOTAL=$(grep -o '"numTotalTests":[0-9]*' "$LOG" | cut -d: -f2)
    echo "Tests: PASS ($TOTAL tests)"
  else
    FAILED=$(grep -o '"numFailedTests":[0-9]*' "$LOG" | cut -d: -f2)
    echo "Tests: FAIL ($FAILED failures)"
    # 失敗したテスト名を表示
    grep '"fullName"' "$LOG" | head -5
  fi
elif pgrep -f "vitest run" > /dev/null; then
  echo "Tests: RUNNING..."
else
  echo "Tests: NOT RUN"
fi
```

### ビルドのステータス

```bash
LOG=".worktree-logs/build.log"

if [ -f "$LOG" ]; then
  if [ $? -eq 0 ]; then
    echo "Build: PASS"
  else
    echo "Build: FAIL"
    tail -10 "$LOG"
  fi
elif pgrep -f "cargo build\|next build\|go build" > /dev/null; then
  echo "Build: RUNNING..."
else
  echo "Build: NOT RUN"
fi
```

## レポートフォーマット

```
Worktree Status: .worktrees/feat/auth
Branch: feat/auth (from main, 3 commits ahead)

Checks:
  Type check:  PASS
  Tests:       PASS (142 tests)
  Build:       NOT RUN

Dependencies: symlinked from main
Disk usage: 2.3 MB (excl. node_modules)

Log files: .worktree-logs/
```

**失敗が検出された場合:**

```
Worktree Status: .worktrees/feat/auth
Branch: feat/auth (from main, 3 commits ahead)

Checks:
  Type check:  FAIL (3 errors)
    src/auth.ts:42 - error TS2345: Argument of type 'string' is not assignable
    src/auth.ts:67 - error TS2304: Cannot find name 'AuthConfig'
    src/middleware.ts:12 - error TS7006: Parameter 'req' implicitly has an 'any' type
  Tests:       FAIL (2 failures)
    auth.test.ts > should validate token
    auth.test.ts > should reject expired token
  Build:       NOT RUN

Action: Fix type errors before proceeding. Run `npx tsc --noEmit` for full output.
```

## ログ管理

```bash
# 古いログをクリーン（チェックを再実行する際に有用）
rm -rf .worktree-logs/*.log

# すべてのチェックを再実行
npx tsc --noEmit > .worktree-logs/typecheck.log 2>&1 &
npx vitest run --reporter=json > .worktree-logs/tests.log 2>&1 &
```

## クイックリファレンス

| 状況 | 出力 |
|-----------|--------|
| すべてのチェックが合格 | グリーンステータス、作業準備完了 |
| チェックがまだ実行中 | PID 付きの「RUNNING...」 |
| 型エラーが見つかった | エラー数 + 最初の5つのエラー |
| テストが失敗 | 失敗数 + 失敗したテスト名 |
| ログが見つからない | 「NOT RUN」（`--fast` 使用またはログ削除） |
| Worktree 内にいない | 手順付きエラーメッセージ |

## 使用法

```
/git-worktree-status
```

引数は不要。任意の worktree ディレクトリから実行します。
