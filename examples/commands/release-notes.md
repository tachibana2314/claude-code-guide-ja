---
name: release-notes
description: "git コミットから複数のフォーマットでリリースノートを生成する"
---

# リリースノートジェネレーター

git コミットから3つのフォーマットでリリースノートを生成します。本番リリース向け。

## プロセス

1. **Git 履歴の分析**: 最後のリリースタグ以降のコミットをスキャン
2. **PR の詳細を取得**: `gh api` でタイトル、説明を取得
3. **変更を分類**: タイプ別にグループ化（feat、fix、perf など）
4. **マイグレーションを確認**: データベースマイグレーションファイルを検出
5. **3つの出力を生成**: CHANGELOG、PR 本文、コミュニケーションメッセージ
6. **言語を変換**: 技術的な専門用語をプロダクト言語に変換

## 出力フォーマット

### 1. CHANGELOG.md セクション

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Summary
[このリリースの1-2文の概要]

### New Features
#### [Feature Name] (#PR)
- **Description**: 追加されたユーザー向け機能
- **Impact**: ユーザーへの利益

### Bug Fixes
- **[Module]**: 説明 (#issue, tracking-ID)

### Technical Improvements
- [内部改善、リファクタリング、パフォーマンス]

### Database Migrations
[該当する場合 — マイグレーションファイルを一覧表示]

### Statistics
- PRs: X | Features: Y | Fixes: Z | Files changed: N
```

### 2. PR リリース本文

プロジェクトのリリーステンプレートを使用します:
- `.github/PULL_REQUEST_TEMPLATE/release.md`
- `.github/pull_request_template_release.md`
- またはプロジェクト設定で指定されたカスタムの場所

### 3. コミュニケーションアナウンス

ユーザー向けアナウンスを生成します（Slack、メールなど）:
- 非技術的な言語
- ユーザーへの影響に焦点
- 読みやすいフォーマット（絵文字はオプション）

テンプレートの場所の例:
- `.github/COMMUNICATION_TEMPLATE/slack-release.md`
- `docs/templates/release-announcement.md`

## マイグレーションアラート

**マイグレーションが検出された場合:**

```
╔══════════════════════════════════════════════════════════════════╗
║  ⚠️  [ATTENTION] DATABASE MIGRATIONS REQUIRED                    ║
╠══════════════════════════════════════════════════════════════════╣
║  This release contains X migration(s):                           ║
║  • 20250110_add_user_preferences                                 ║
║  • 20250112_create_audit_log_table                               ║
║  Action required: Run migration command after deployment         ║
╚══════════════════════════════════════════════════════════════════╝
```

**マイグレーションなしの場合:**
```
✅ [OK] No database migrations required
```

## 技術→プロダクト用語の変換

技術的なコミットをユーザーフレンドリーな説明に変換します:

| 技術的 | プロダクト/ユーザー向け |
|-----------|----------------------|
| "Optimize N+1 queries with DataLoader" | "リストの読み込み時間の高速化" |
| "Implement AI embeddings with pgvector" | "新しいインテリジェント検索機能" |
| "Fix permissions scope bug" | "一部ユーザーのアクセス問題を解決" |
| "Migration webpack -> Turbopack" | *内部のみ — コミュニケーションしない* |
| "Refactor React hooks architecture" | *内部のみ — コミュニケーションしない* |
| "Add rate limiting to API endpoints" | "システムの安定性とセキュリティの改善" |

## コミットカテゴリー

| プレフィックス | カテゴリー | アナウンスに含める？ |
|--------|----------|--------------------------|
| `feat:` | 新機能 | はい |
| `fix:` | バグ修正 | はい（ユーザー向けの場合） |
| `perf:` | パフォーマンス | はい（簡略化） |
| `security:` | セキュリティ | はい |
| `refactor:` | アーキテクチャ | いいえ |
| `chore:` | メンテナンス | いいえ |
| `docs:` | ドキュメント | いいえ |
| `test:` | テスト | いいえ |
| `build:` | ビルドシステム | いいえ |
| `ci:` | CI/CD | いいえ |

## 実行するコマンド

```bash
# 1. 最後のリリースタグを取得
LAST_TAG=$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1)

# 2. タグ以降のコミットを一覧表示（マージを除く）
git log $LAST_TAG..HEAD --oneline --no-merges

# 3. PR 番号付きのコミット詳細を取得
git log $LAST_TAG..HEAD --format="%h %s" --no-merges

# 4. マイグレーションを確認（ORM に合わせてパスを調整）
# Prisma:
git diff $LAST_TAG..HEAD --name-only -- prisma/migrations/
# Sequelize:
git diff $LAST_TAG..HEAD --name-only -- migrations/
# Django:
git diff $LAST_TAG..HEAD --name-only -- '**/migrations/*.py'
# Alembic:
git diff $LAST_TAG..HEAD --name-only -- alembic/versions/

# 5. GitHub CLI で PR の詳細を取得
gh api repos/{owner}/{repo}/pulls/{number}

# 6. 統計をカウント
TOTAL_PRS=$(git log $LAST_TAG..HEAD --oneline --merges | wc -l)
FEATURES=$(git log $LAST_TAG..HEAD --oneline --no-merges | grep -c 'feat:')
FIXES=$(git log $LAST_TAG..HEAD --oneline --no-merges | grep -c 'fix:')
```

## セマンティックバージョニング

変更に基づいてバージョン番号を決定します:

| 変更タイプ | バージョンバンプ | 例 |
|-------------|--------------|---------|
| 破壊的変更 | MAJOR (X.0.0) | API の削除、互換性のない変更 |
| 新機能 | MINOR (0.X.0) | 新機能、後方互換性あり |
| バグ修正/パッチ | PATCH (0.0.X) | バグ修正のみ |

**インジケーター**:
- コミット本文に `BREAKING CHANGE:` → MAJOR
- `feat:` コミットが存在 → MINOR
- `fix:` / `perf:` のみ → PATCH

## ワークフロー統合

典型的なリリースワークフロー:

```
1. すべての PR が develop ブランチにマージされていることを確認
2. 実行: /release-notes（またはバージョン/範囲を指定）
3. 生成された出力の正確さをレビュー
4. PR を作成: develop -> main（"release" ラベル付き）
5. 生成された CHANGELOG セクションを CHANGELOG.md に追加
6. 生成された PR 本文を PR の説明として使用
7. マージ後: git タグを作成してプッシュ
8. コミュニケーションアナウンスを投稿（Slack/メール/など）
9. デプロイとマイグレーションを監視
```

## Git タグの作成

PR マージ後、注釈付きタグを作成します:

```bash
# 注釈付きタグを作成
git tag -a v1.2.3 -m "Release v1.2.3: Brief description"

# タグをリモートにプッシュ
git push origin v1.2.3

# またはすべてのタグをプッシュ
git push --tags
```

## プロジェクト固有のカスタマイズ

これらのパスをプロジェクトに合わせて調整します:

```
# マイグレーション検出（ORM パスを調整）
prisma/migrations/        → あなたの ORM マイグレーションディレクトリ
db/migrate/               → Rails マイグレーション
alembic/versions/         → Alembic マイグレーション

# テンプレートファイル（必要に応じて作成）
.github/PULL_REQUEST_TEMPLATE/release.md
.github/COMMUNICATION_TEMPLATE/announcement.md
docs/templates/release-notes.md
```

## ヒント

- **リポジトリルートから実行**: git コマンドが正しく動作することを確認
- **GitHub CLI を認証**: 必要に応じて `gh auth login` を実行
- **公開前にレビュー**: 生成されたコンテンツを常に確認
- **破壊的変更**: コミットメッセージで `BREAKING CHANGE:` を検索
- **リンクされた Issue**: トレーサビリティのために Issue/チケット番号を含める
- **データベースマイグレーション**: 本番前にステージングでテスト

## エッジケース

| シナリオ | 動作 |
|----------|----------|
| タグが見つからない | 最初のコミットから開始 |
| 最後のタグ以降のコミットなし | エラー: 「リリースする変更がありません」 |
| 同じコミットに複数のタグ | 日付で最新のものを使用 |
| プレリリースタグ（v1.0.0-beta.1） | 「最後のリリース」検索から除外 |
| Conventional フォーマット以外のコミット | 「その他の変更」として分類 |

## 使用例

```bash
# 最後のタグから HEAD までのリリースノートを生成
/release-notes

# バージョンを手動で指定
/release-notes v1.5.0

# 範囲を指定
/release-notes from v1.4.0 to HEAD

# ファイルを作成せずにプレビュー
/release-notes --preview

# プレリリースのコミットを含める
/release-notes --include-pre-release
```

バージョン/範囲: $ARGUMENTS
