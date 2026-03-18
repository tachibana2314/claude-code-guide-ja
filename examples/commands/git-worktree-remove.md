---
layout: default
title: "Git Worktree 削除"
parent: コマンド
grand_parent: テンプレート
nav_order: 9
---


# Git Worktree 削除

ブランチクリーンアップ、マージ確認、データベースブランチの破棄を含む単一 git worktree の安全な削除。

**コア原則:** 安全チェックを先に行い、worktree + ブランチ + DB リソースをクリーンに削除。

**関連コマンド:** [Worktree ライフサイクルスイート](./git-worktree.md) | [`/git-worktree`](./git-worktree.md) | [`/git-worktree-status`](./git-worktree-status.md) | [`/git-worktree-clean`](./git-worktree-clean.md)

## プロセス

1. **対象を検証**: 削除する worktree を特定
2. **安全チェック**: main/develop ブランチを保護
3. **マージステータスを確認**: ブランチに未マージの変更がある場合に警告
4. **未コミットの変更を確認**: worktree がダーティな状態の場合に警告
5. **Worktree を削除**: `git worktree remove`
6. **ローカルブランチを削除**: `git branch -d`（または確認付き `-D`）
7. **リモートブランチを削除**: `git push origin --delete`（確認付き）
8. **データベースクリーンアップリマインダー**: 該当する場合 DB ブランチの削除を提案
9. **参照を整理**: `git worktree prune`

## 安全チェック

### 保護対象ブランチ

```bash
# これらのブランチの worktree は削除しない（設定可能）
PROTECTED_BRANCHES="main master develop staging production"

if echo "$PROTECTED_BRANCHES" | grep -qw "$BRANCH"; then
  echo "BLOCKED: Cannot remove worktree for protected branch '$BRANCH'"
  echo "Protected branches: $PROTECTED_BRANCHES"
  exit 1
fi
```

### 未コミットの変更

```bash
cd "$WORKTREE_PATH"
if [ -n "$(git status --porcelain)" ]; then
  echo "WARNING: Worktree has uncommitted changes:"
  git status --short
  echo ""
  echo "Options:"
  echo "  1. Commit changes first"
  echo "  2. Force remove (--force)"
  echo "  3. Cancel"
  # ユーザーの決定を待つ
fi
```

### マージステータス

```bash
# ブランチが main にマージされているか確認
MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

if git merge-base --is-ancestor "$BRANCH" "$MAIN_BRANCH" 2>/dev/null; then
  echo "Branch '$BRANCH' is merged into $MAIN_BRANCH. Safe to delete."
  MERGED=true
else
  echo "WARNING: Branch '$BRANCH' is NOT merged into $MAIN_BRANCH."
  echo "You may lose work if you delete this branch."
  MERGED=false
fi
```

## 削除ステップ

```bash
# 1. worktree を削除
git worktree remove "$WORKTREE_PATH"
# ダーティな状態でユーザーが強制確認した場合:
# git worktree remove --force "$WORKTREE_PATH"

# 2. ローカルブランチを削除
if [ "$MERGED" = true ]; then
  git branch -d "$BRANCH"
else
  echo "Delete unmerged branch '$BRANCH'? (requires confirmation)"
  # 確認後:
  git branch -D "$BRANCH"
fi

# 3. リモートブランチを削除（確認付き）
if git ls-remote --heads origin "$BRANCH" | grep -q "$BRANCH"; then
  echo "Delete remote branch 'origin/$BRANCH'?"
  # 確認後:
  git push origin --delete "$BRANCH"
fi

# 4. 古い参照を整理
git worktree prune
```

## データベースブランチのクリーンアップ

**worktree の削除後、関連するデータベースブランチについてリマインド:**

```bash
# データベースプロバイダーを検出（/git-worktree と同じロジック）
if [ -f ".env" ] && grep -q "neon" ".env"; then
  echo ""
  echo "DB Cleanup: neonctl branches delete $BRANCH_SLUG"
elif [ -f ".pscale.yml" ]; then
  echo ""
  DB_NAME=$(grep 'database:' .pscale.yml | awk '{print $2}')
  echo "DB Cleanup: pscale branch delete $DB_NAME $BRANCH_SLUG"
elif [ -f ".env" ] && grep -q "postgresql" ".env"; then
  echo ""
  echo "DB Cleanup: psql \$DATABASE_URL -c \"DROP SCHEMA ${BRANCH_SLUG} CASCADE;\""
fi
```

## レポートフォーマット

**正常な削除（マージ済みブランチ）:**

```
Removed worktree: .worktrees/feat/auth
  Worktree directory: deleted
  Local branch feat/auth: deleted (was merged)
  Remote branch origin/feat/auth: deleted
  References: pruned

DB reminder: neonctl branches delete feat-auth
```

**警告付きの削除（未マージブランチ）:**

```
Removed worktree: .worktrees/feat/experimental
  Worktree directory: deleted
  Local branch feat/experimental: deleted (was NOT merged - forced)
  Remote branch: no remote branch found
  References: pruned

WARNING: Branch was not merged. Changes may be lost.
Last commit: a1b2c3d "WIP: experimental auth flow"
```

## フラグ

| フラグ | 効果 |
|------|--------|
| `--force` | 未コミットの変更の警告をスキップ |
| `--keep-branch` | worktree を削除するがブランチは保持 |
| `--keep-remote` | リモートブランチを削除しない |

## クイックリファレンス

| 状況 | アクション |
|-----------|--------|
| ブランチがマージ済み | 安全に削除（branch -d） |
| ブランチが未マージ | 警告 + 確認が必要（branch -D） |
| 未コミットの変更あり | 警告 + 強制/キャンセルを提案 |
| 保護対象ブランチ（main/develop） | 削除をブロック |
| リモートブランチが存在 | リモートの削除を確認 |
| DB ブランチが検出された | 正確なコマンドでリマインド |
| 古い参照 | 自動整理 |

## よくある間違い

**main/develop の worktree を削除する**
- 安全チェックで常にブロックされる。必要な場合は保護対象ブランチを再設定する。

**未マージブランチを確認なしに削除する**
- 常にマージステータスを確認すること。未マージブランチには明示的な `--force` または `-D` が必要。

**データベースブランチのクリーンアップを忘れる**
- リソースを消費する孤立した DB ブランチが残る。コマンドが自動的にリマインドする。

**`git worktree remove` の代わりに `rm -rf` を使用する**
- `.git/worktrees/` に古い worktree 参照が残る。常に git コマンドを使用すること。

## 使用法

```
/git-worktree-remove feat/auth
/git-worktree-remove fix/login-bug --force
/git-worktree-remove refactor/db --keep-branch
```

ブランチまたは worktree パス: $ARGUMENTS
