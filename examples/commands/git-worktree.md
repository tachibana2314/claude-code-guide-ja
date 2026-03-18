---
name: git-worktree
description: "ブランチを切り替えずに機能開発のための分離された git worktree を作成する"
---

# Git Worktree セットアップ

ブランチを切り替えずに機能開発のための分離された git worktree を作成します。

**コア原則:** スマートなディレクトリ選択 + シンボリックリンク最適化 + バックグラウンド検証 = 高速で信頼性の高い分離。

**要件:** Git 2.5.0 以上（2015年7月）

**関連コマンド:** [`/git-worktree-status`](./git-worktree-status.md) | [`/git-worktree-remove`](./git-worktree-remove.md) | [`/git-worktree-clean`](./git-worktree-clean.md)

## プロセス

1. **ブランチ名を検証**: 命名規則と競合を確認
2. **既存ディレクトリを確認**: `.worktrees/` または `worktrees/`
3. **.gitignore を確認**: worktree ディレクトリが無視されているか確認
4. **Worktree を作成**: `git worktree add`
5. **依存関係をシンボリックリンク**: メイン worktree から `node_modules/` を再利用
6. **データベースプロバイダーを検出**: DB ブランチング機能を確認
7. **依存関係をインストール**: パッケージマネージャーを自動検出（シンボリックリンクしない場合）
8. **バックグラウンド検証を実行**: バックグラウンドで型チェック + テスト
9. **ロケーションをレポート**: ステータス付きで準備完了を確認

## フラグ

| フラグ | 効果 |
|------|--------|
| `--fast` | 依存関係のインストールとベースラインテストをスキップ |
| `--isolated` | 新規 `node_modules` インストール（シンボリックリンクなし） |
| `--skip-install` | 依存関係のインストールをスキップ、ベースラインテストは維持 |

## ブランチ名の検証

```bash
# 命名規則に基づいて自動的にプレフィックスを付与
# "auth" → "feat/auth"（デフォルトプレフィックス）
# "fix/login-bug" → そのまま維持
# "refactor/db-layer" → そのまま維持

# 許可されるプレフィックス: feat/, fix/, refactor/, chore/, docs/, test/, perf/
# プレフィックスがない場合 → デフォルトで feat/ を付与

# 無効な文字を拒否
echo "$BRANCH_NAME" | grep -qE '^[a-zA-Z0-9/_-]+$' || exit 1

# ブランチが既に存在しないか確認
git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" && echo "Branch already exists" && exit 1
```

## ディレクトリの選択

### 優先順位

```bash
# 1. 既存ディレクトリを確認
ls -d .worktrees 2>/dev/null     # 推奨（隠し）
ls -d worktrees 2>/dev/null      # 代替

# 2. CLAUDE.md で設定を確認
grep -i "worktree.*director" CLAUDE.md 2>/dev/null

# 3. どちらも存在しない場合はユーザーに確認
```

**両方存在する場合:** `.worktrees/` が優先。

## 安全性の確認

**プロジェクトローカルディレクトリの場合:**

```bash
# ディレクトリが .gitignore に含まれているか確認
grep -q "^\.worktrees/$" .gitignore || grep -q "^worktrees/$" .gitignore
```

**.gitignore に含まれていない場合:**
1. .gitignore に行を追加
2. 変更をコミット
3. worktree 作成を続行

**重要な理由:** worktree の内容が誤ってコミットされるのを防ぐ。

## 作成ステップ

```bash
# 1. プロジェクト名を検出
project=$(basename "$(git rev-parse --show-toplevel)")

# 2. 新しいブランチで worktree を作成
git worktree add .worktrees/$BRANCH_NAME -b $BRANCH_NAME

# 3. ナビゲート
cd .worktrees/$BRANCH_NAME
```

## 依存関係の最適化（Node.js）

**デフォルトの動作:** 重複インストールを避けるためにメイン worktree から `node_modules` をシンボリックリンク（約30秒の節約）。

```bash
# node_modules のシンボリックリンク（デフォルト、--isolated でない限り）
if [ -d "../../node_modules" ] && [ ! "$ISOLATED" = true ]; then
  ln -s "$(cd ../.. && pwd)/node_modules" node_modules
  echo "Symlinked node_modules from main worktree"
fi

# --isolated の場合: 新規インストール
if [ "$ISOLATED" = true ]; then
  pnpm install   # またはロックファイルの検出に基づいて npm/yarn
fi
```

**`--isolated` を使用するタイミング:**
- 異なるパッケージバージョンが必要なスキーマ変更
- 依存関係のアップグレードのテスト
- `node_modules` の問題のデバッグ

## 自動検出セットアップ（マルチスタック）

```bash
# Node.js（シンボリックリンクしない場合）
if [ -f package.json ] && [ ! -L node_modules ]; then
  pnpm install   # ロックファイルから検出: pnpm-lock.yaml / yarn.lock / package-lock.json
fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

## バックグラウンド検証

**フルテストスイートでブロックする代わりに、バックグラウンドで検証を実行:**

```bash
# ログディレクトリを作成
mkdir -p .worktree-logs

# バックグラウンド型チェック（Node.js）
if [ -f tsconfig.json ]; then
  npx tsc --noEmit > .worktree-logs/typecheck.log 2>&1 &
  echo "Type check running in background (check with /git-worktree-status)"
fi

# バックグラウンドテスト実行
if [ -f package.json ]; then
  npx vitest run --reporter=json > .worktree-logs/tests.log 2>&1 &
  echo "Tests running in background (check with /git-worktree-status)"
fi
```

**`--fast` の場合:** すべての検証をスキップ。

## 最終レポート

```
Worktree ready at <full-path>
Branch: feat/auth (created from main)
Dependencies: symlinked from main worktree
Background checks: type check + tests running
Check status: /git-worktree-status

Ready to implement <feature-name>
```

## データベースブランチの提案

**worktree 作成後、データベースプロバイダーを検出して分離を提案。**

### クイックコマンドリファレンス

| プロバイダー | 推奨コマンド |
|----------|-------------------|
| **Neon** | `neonctl branches create --name <branch> --parent main` |
| **PlanetScale** | `pscale branch create <db> <branch>` |
| **ローカル Postgres** | `psql -c "CREATE SCHEMA <schema>;"` |
| **その他** | 手動セットアップまたは共有 DB |

**出力例:**

```
Worktree created at .worktrees/feat/auth

DB Isolation: neonctl branches create --name feat-auth --parent main
   Then update .env with new DATABASE_URL
   Full guide: ../workflows/database-branch-setup.md
```

### .worktreeinclude のセットアップ

**環境変数のために重要:**

```bash
# .worktreeinclude（プロジェクトルート）
.env
.env.local
.env.development
**/.claude/settings.local.json
```

**理由:** これがないと `.env` ファイルが worktree にコピーされない。

### データベースブランチを作成するタイミング

| シナリオ | ブランチを作成？ |
|----------|---------------|
| スキーママイグレーション | はい |
| データモデルのリファクタリング | はい |
| バグ修正（スキーマ変更なし） | いいえ |
| パフォーマンス実験 | はい |

**参照:** [データベースブランチセットアップガイド](../workflows/database-branch-setup.md)（完全なワークフロー）

## クイックリファレンス

| 状況 | アクション |
|-----------|--------|
| `.worktrees/` が存在 | 使用（.gitignore を確認） |
| `worktrees/` が存在 | 使用（.gitignore を確認） |
| 両方存在 | `.worktrees/` を使用 |
| どちらも存在しない | CLAUDE.md を確認、次にユーザーに確認 |
| .gitignore に含まれていない | すぐに追加してコミット |
| ブランチプレフィックスなし | 自動的に `feat/` を付与 |
| Node.js プロジェクト | デフォルトで `node_modules` をシンボリックリンク |
| `--fast` フラグ | インストール + テストをスキップ |
| `--isolated` フラグ | 新規 `node_modules` インストール |
| Neon が検出された | `neonctl branches create` を提案 |
| PlanetScale が検出された | `pscale branch create` を提案 |
| .worktreeinclude がない | `.env` パターンで作成 |

## よくある間違い

**.gitignore の確認をスキップする**
- worktree の内容が追跡され、git ステータスが汚染される

**ディレクトリの場所を仮定する**
- 優先順位に従うこと: 既存 > CLAUDE.md > 確認

**すべての worktree に完全な node_modules をインストールする**
- ディスクと時間を無駄にする。デフォルトでシンボリックリンクを使用し、必要な時のみ `--isolated` を使用

**.env を worktree にコピーしない**
- 症状: Claude が「DATABASE_URL が見つかりません」で失敗
- 修正: `.worktreeinclude` に `.env` を追加

**スキーマ変更に共有データベースを使用する**
- 症状: マイグレーションの競合、破損した開発環境
- 修正: スキーマを変更する前にデータベースブランチを作成

## 使用法

```
/git-worktree auth
/git-worktree fix/session-bug
/git-worktree feature/new-api --fast
/git-worktree refactor/db-layer --isolated
```

ブランチ名: $ARGUMENTS
