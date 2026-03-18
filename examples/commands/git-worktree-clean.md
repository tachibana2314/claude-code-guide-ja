---
name: git-worktree-clean
description: "マージ済みブランチ検出とディスク使用レポートを含む古い git worktree の一括クリーンアップ"
---

# Git Worktree クリーン

古い git worktree の一括クリーンアップ。マージ済みブランチを安全に削除し、ディスク使用量を報告し、未マージブランチをインタラクティブに処理します。

**コア原則:** マージ済み worktree を自動クリーン、未マージはインタラクティブレビュー、常に回収した容量を報告。

**関連コマンド:** [Worktree ライフサイクルスイート](./git-worktree.md) | [`/git-worktree`](./git-worktree.md) | [`/git-worktree-status`](./git-worktree-status.md) | [`/git-worktree-remove`](./git-worktree-remove.md)

## プロセス

1. **全 Worktree を一覧表示**: `git worktree list`
2. **各 Worktree を分類**: マージ済み vs 未マージ vs 保護済み
3. **ディスク使用量を計算**: Worktree ごとのサイズ
4. **自動モード**: マージ済み worktree をすべて削除（安全）
5. **インタラクティブモード**: 未マージ worktree を1つずつレビュー
6. **データベースクリーンアップリマインダー**: クリーンアップすべき DB ブランチを一覧表示
7. **レポート**: 実施したアクションと回収した容量のサマリー

## フラグ

| フラグ | 効果 |
|------|--------|
| `--dry-run` | 変更なしにクリーンアップされるものをプレビュー |
| `--all` | 未マージ worktree を含む（各確認のインタラクティブ） |
| `--force` | 確認なしにすべての worktree を削除（危険） |

## Worktree の検出

```bash
# メインブランチ名を取得
MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
MAIN_BRANCH=${MAIN_BRANCH:-main}

# 保護対象ブランチ（自動クリーンアップしない）
PROTECTED="main master develop staging production"

# すべての worktree を一覧表示（メインワーキングツリーはスキップ）
git worktree list --porcelain | while read line; do
  # worktree パスとブランチを解析
  # メインワーキングツリー（最初のエントリ）はスキップ
done
```

## 分類

```bash
for WORKTREE in $WORKTREES; do
  BRANCH=$(git -C "$WORKTREE" rev-parse --abbrev-ref HEAD)

  # 保護済みはスキップ
  if echo "$PROTECTED" | grep -qw "$BRANCH"; then
    echo "PROTECTED: $BRANCH (skipped)"
    continue
  fi

  # マージステータスを確認
  if git merge-base --is-ancestor "$BRANCH" "$MAIN_BRANCH" 2>/dev/null; then
    echo "MERGED: $BRANCH → safe to remove"
    MERGED_LIST="$MERGED_LIST $WORKTREE"
  else
    echo "UNMERGED: $BRANCH → requires review"
    UNMERGED_LIST="$UNMERGED_LIST $WORKTREE"
  fi
done
```

## ディスク使用量の計算

```bash
for WORKTREE in $ALL_WORKTREES; do
  # node_modules シンボリックリンクを除いたサイズを計算
  SIZE=$(du -sh --exclude='node_modules' "$WORKTREE" 2>/dev/null | cut -f1)
  # または macOS の場合:
  SIZE=$(du -sh -I 'node_modules' "$WORKTREE" 2>/dev/null | cut -f1)
  echo "  $WORKTREE: $SIZE"
done
```

## ドライランモード

```bash
# --dry-run: 変更を加えずに何が起こるかを表示

echo "=== Dry Run ==="
echo ""
echo "Would remove (merged):"
for WT in $MERGED_LIST; do
  echo "  $WT ($BRANCH) - $SIZE"
done
echo ""
echo "Would ask about (unmerged):"
for WT in $UNMERGED_LIST; do
  echo "  $WT ($BRANCH) - $SIZE - last commit: $(git log -1 --format='%s' $BRANCH)"
done
echo ""
echo "Total space to reclaim: $TOTAL_SIZE"
echo ""
echo "Run without --dry-run to execute."
```

## 自動モード（デフォルト）

**マージ済み worktree のみを削除。デフォルトで安全。**

```bash
echo "Cleaning merged worktrees..."

for WORKTREE in $MERGED_LIST; do
  BRANCH=$(git -C "$WORKTREE" rev-parse --abbrev-ref HEAD)

  # worktree を削除
  git worktree remove "$WORKTREE"

  # ローカルブランチを削除
  git branch -d "$BRANCH" 2>/dev/null

  # リモートブランチを削除
  git push origin --delete "$BRANCH" 2>/dev/null

  echo "  Removed: $WORKTREE ($BRANCH)"
done

# 未マージを報告（触れない）
if [ -n "$UNMERGED_LIST" ]; then
  echo ""
  echo "Unmerged worktrees (kept):"
  for WT in $UNMERGED_LIST; do
    echo "  $WT - use /git-worktree-remove or --all to review"
  done
fi
```

## インタラクティブモード（--all）

**未マージ worktree を1つずつレビュー:**

```bash
for WORKTREE in $UNMERGED_LIST; do
  BRANCH=$(git -C "$WORKTREE" rev-parse --abbrev-ref HEAD)
  LAST_COMMIT=$(git log -1 --format='%h %s (%cr)' "$BRANCH")
  AHEAD=$(git rev-list --count "$MAIN_BRANCH".."$BRANCH")

  echo ""
  echo "Unmerged: $WORKTREE"
  echo "  Branch: $BRANCH ($AHEAD commits ahead of $MAIN_BRANCH)"
  echo "  Last commit: $LAST_COMMIT"
  echo "  Size: $SIZE"
  echo ""
  echo "  [r]emove  [k]eep  [s]kip remaining"

  # worktree ごとにユーザーの決定を待つ
done
```

## レポートフォーマット

**クリーンアップ後:**

```
=== Worktree Cleanup Report ===

Removed (merged):
  .worktrees/feat/auth (feat/auth) - 2.3 MB
  .worktrees/fix/login-bug (fix/login-bug) - 1.1 MB
  .worktrees/chore/deps-update (chore/deps-update) - 0.8 MB

Kept (unmerged):
  .worktrees/feat/experimental (feat/experimental) - 4.2 MB
    Last commit: a1b2c3d "WIP: new auth flow" (3 days ago)

Kept (protected):
  .worktrees/develop (develop)

Space reclaimed: 4.2 MB
Worktrees remaining: 2
References pruned: yes

DB branches to clean:
  neonctl branches delete feat-auth
  neonctl branches delete fix-login-bug
  neonctl branches delete chore-deps-update
```

**ドライランレポート:**

```
=== Dry Run - No Changes Made ===

Would remove (3 merged):
  .worktrees/feat/auth - 2.3 MB
  .worktrees/fix/login-bug - 1.1 MB
  .worktrees/chore/deps-update - 0.8 MB

Would keep (1 unmerged):
  .worktrees/feat/experimental - 4.2 MB

Would keep (1 protected):
  .worktrees/develop

Potential space savings: 4.2 MB
```

## クイックリファレンス

| 状況 | アクション |
|-----------|--------|
| デフォルト（フラグなし） | マージ済み worktree のみを削除 |
| `--dry-run` | 変更なしでプレビュー |
| `--all` | マージ済み（自動） + 未マージ（インタラクティブ） |
| `--force` | 保護済み以外をすべて削除 |
| 保護対象ブランチ | 常に保持 |
| マージ済みブランチ | 自動削除 |
| 未マージブランチ | 保持（デフォルト）またはインタラクティブ（--all） |
| DB ブランチが検出された | 正確なコマンドでリマインダー |

## よくある間違い

**`--dry-run` なしで `--force` を実行する**
- 強制クリーン前に必ず `--dry-run` でプレビューすること

**DB ブランチのクリーンアップを忘れる**
- worktree のクリーンアップは DB ブランチを自動削除しない。リマインダーコマンドに従うこと。

**定期的なクリーンアップを怠る**
- 古い worktree がディスクスペースを蓄積する。毎週 `/git-worktree-clean --dry-run` を実行すること。

## 使用法

```
/git-worktree-clean
/git-worktree-clean --dry-run
/git-worktree-clean --all
```

フラグ: $ARGUMENTS
