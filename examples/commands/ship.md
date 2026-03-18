---
name: ship
description: "リリース準備を確認するための包括的なデプロイ前検証"
---

# Ship コマンド — デプロイ前チェックリスト

リリース準備を確認するための包括的なデプロイ前検証。

## 目的

すべての本番デプロイ前に実行して以下を確認します:
- コード品質ゲート
- テストカバレッジ
- セキュリティチェック
- ドキュメントの更新
- 環境の準備状況

## デプロイ前チェックリスト

### 🔴 ブロッカー（必須合格）

```bash
# 1. すべてのテストが合格している
npm test 2>/dev/null || pnpm test 2>/dev/null || yarn test 2>/dev/null
echo "Exit code: $?"

# 2. TypeScript/lint エラーがない
npm run typecheck 2>/dev/null || npx tsc --noEmit
npm run lint 2>/dev/null || npx eslint .

# 3. ビルドが成功する
npm run build 2>/dev/null || pnpm build 2>/dev/null

# 4. コードにシークレットがない
grep -rn "API_KEY=\|SECRET=\|PASSWORD=" --include="*.{ts,js,json}" . 2>/dev/null | grep -v node_modules | grep -v ".env.example"
```

### 🟠 高優先度（合格すべき）

```bash
# 5. セキュリティ監査
npm audit --audit-level=high 2>/dev/null || echo "Run manually: npm audit"

# 6. 本番コードに console.log がない
grep -rn "console\.log\|console\.debug" --include="*.{ts,js,tsx,jsx}" src/ 2>/dev/null | grep -v "// allowed" | head -10

# 7. クリティカルなパスに TODO/FIXME がない
grep -rn "TODO\|FIXME\|XXX\|HACK" --include="*.{ts,js}" src/ 2>/dev/null | head -10

# 8. データベースマイグレーションの準備
[ -d "prisma/migrations" ] && echo "Prisma migrations: $(ls prisma/migrations | wc -l) total"
[ -d "migrations" ] && echo "Migrations: $(ls migrations | wc -l) total"
```

### 🟡 推奨事項（あれば良い）

```bash
# 9. ドキュメントが更新されている
git diff --name-only HEAD~5 | grep -E "README|CHANGELOG|docs/" | head -10

# 10. バージョンがバンプされている
cat package.json | jq -r '.version' 2>/dev/null || echo "Check version manually"

# 11. 環境変数がドキュメント化されている
[ -f ".env.example" ] && echo "✅ .env.example exists" || echo "⚠️ Missing .env.example"
```

## 出力フォーマット

---

### 🚀 出荷準備レポート

**ブランチ**: [現在のブランチ]
**コミット**: [HEAD の短縮ハッシュ]
**ターゲット**: [本番/ステージング]
**タイムスタンプ**: [日時]

### ブロッカー（デプロイ前に修正が必要）

| チェック | ステータス | 詳細 |
|-------|--------|---------|
| テスト | ✅/❌ | X 合格、Y 失敗 |
| TypeScript | ✅/❌ | X エラー |
| Lint | ✅/❌ | X 警告、Y エラー |
| ビルド | ✅/❌ | 成功/失敗 |
| シークレット | ✅/❌ | X 件の潜在的な漏洩 |

### 高優先度

| チェック | ステータス | アクション |
|-------|--------|--------|
| セキュリティ監査 | ⚠️/✅ | X 件の脆弱性 |
| Console ログ | ⚠️/✅ | src/ で X 件発見 |
| TODO | ⚠️/✅ | X 件のクリティカルな TODO |
| マイグレーション | ⚠️/✅ | X 件の保留中 |

### 推奨事項

| チェック | ステータス | 注記 |
|-------|--------|------|
| ドキュメント更新 | ⚠️/✅ | CHANGELOG が更新されている |
| バージョンバンプ | ⚠️/✅ | 現在: X.Y.Z |
| 環境ドキュメント | ⚠️/✅ | .env.example が存在する |

### 📊 サマリー

```
🔴 Blockers:    X/5 passed
🟠 High:        X/4 passed
🟡 Recommended: X/3 passed
─────────────────────────
Overall:        [READY TO SHIP / NOT READY]
```

### 🎯 アクション項目

1. [最も重要な必要な修正]
2. [2番目の優先度]
3. [3番目の優先度]

---

## 環境固有のチェック

### 本番デプロイ

```bash
# 本番環境変数を確認
[ -f ".env.production" ] && echo "Production env exists"

# デバッグフラグを確認
grep -rn "DEBUG=true\|NODE_ENV=development" .env* 2>/dev/null

# API エンドポイントが本番を指しているか確認
grep -rn "localhost\|127\.0\.0\.1" --include="*.{ts,js,json}" src/ 2>/dev/null | grep -v test | head -5
```

### ステージングデプロイ

```bash
# ステージング固有のチェック
[ -f ".env.staging" ] && echo "Staging env exists"

# ステージングのフィーチャーフラグ
grep -rn "FEATURE_FLAG\|ENABLE_" .env* 2>/dev/null
```

## CI/CD 統合

パイプラインに追加します:

```yaml
# GitHub Actions の例
ship-check:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Run ship checklist
      run: |
        npm ci
        npm test
        npm run typecheck
        npm run lint
        npm run build
        npm audit --audit-level=high
```

## デプロイ後の確認

デプロイ後に確認します:

```bash
# 1. ヘルスチェック
curl -s https://your-app.com/health | jq .

# 2. バージョンチェック
curl -s https://your-app.com/version | jq .

# 3. スモークテスト
npm run test:smoke 2>/dev/null || echo "Run smoke tests manually"
```

## ロールバックの準備

出荷する前に、ロールバックできることを確認します:

```bash
# 現在の本番タグをメモ
git describe --tags --abbrev=0

# ロールバック手順が存在するか確認
[ -f "docs/runbooks/rollback.md" ] && echo "✅ Rollback docs exist"

# データベースマイグレーションの可逆性を確認
# Prisma: prisma migrate diff
# Rails: rails db:rollback (dry-run)
```

## 使用法

**フルチェックリスト:**
```
/ship
```

**本番デプロイ:**
```
/ship --production
```

**クイックチェック（ブロッカーのみ）:**
```
/ship --quick
```

**特定のターゲット指定:**
```
/ship --target=staging
```

## ヒント

1. **早めに、頻繁に実行**: デプロイ当日まで待たない
2. **CI で自動化**: ブロッカーをパイプラインで失敗させる
3. **チームの合意**: ブロッカーと警告の定義
4. **例外をドキュメント化**: チェックをスキップする場合はその理由を記録
5. **デプロイ後も監視**: モニタリングが成功を確認するまで出荷は完了しない

## 関連コマンド

- `/release-notes` — changelog とアナウンスを生成
- `/validate-changes` — LLM ベースのコードレビュー
- `/security` — 詳細なセキュリティ監査

$ARGUMENTS
