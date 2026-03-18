---
name: security
description: "OWASP Top 10 脆弱性に焦点を当てた迅速なセキュリティ評価"
---

# セキュリティクイック監査

OWASP Top 10 脆弱性に焦点を当てた迅速なセキュリティ評価。

## 目的

一般的な脆弱性を特定するクイックセキュリティスキャンを実行します:
- ハードコードされたシークレットと認証情報
- SQL インジェクションリスク
- XSS 脆弱性
- 安全でない依存関係
- 認証/認可の問題

## 手順

### ステップ 1: シークレットスキャン

```bash
# 一般的なシークレットパターン
grep -rn --include="*.{js,ts,py,go,java,rb,php,env}" \
  -E "(password|secret|api_key|apikey|token|auth|credential).*[=:].*['\"][^'\"]{8,}['\"]" \
  --exclude-dir={node_modules,vendor,.git,dist,build} . 2>/dev/null | head -20

# コミットされている可能性のある .env ファイル
find . -name ".env*" -not -path "*/node_modules/*" -type f 2>/dev/null

# シークレットが gitignore に含まれているか確認
[ -f ".gitignore" ] && grep -q "\.env" .gitignore && echo "✅ .env in .gitignore" || echo "⚠️ .env NOT in .gitignore"
```

### ステップ 2: インジェクション脆弱性

```bash
# SQL インジェクションパターン（文字列連結を使用した生クエリ）
grep -rn --include="*.{js,ts,py,go,java,php}" \
  -E "(query|execute|raw|sql).*\+.*\$|f['\"].*SELECT|\.format\(.*SELECT" \
  --exclude-dir={node_modules,vendor,.git} . 2>/dev/null | head -15

# コマンドインジェクションパターン
grep -rn --include="*.{js,ts,py,go,rb,php}" \
  -E "(exec|spawn|system|shell_exec|popen)\s*\(" \
  --exclude-dir={node_modules,vendor,.git} . 2>/dev/null | head -15
```

### ステップ 3: XSS パターン

```bash
# 危険な innerHTML/dangerouslySetInnerHTML の使用
grep -rn --include="*.{js,ts,jsx,tsx,vue}" \
  -E "(innerHTML|dangerouslySetInnerHTML|v-html)" \
  --exclude-dir={node_modules,.git,dist} . 2>/dev/null | head -15

# HTML コンテキストでのエスケープされていないテンプレートリテラル
grep -rn --include="*.{js,ts,jsx,tsx}" \
  -E "\`.*\$\{.*\}.*<" \
  --exclude-dir={node_modules,.git,dist} . 2>/dev/null | head -10
```

### ステップ 4: 依存関係チェック

```bash
# npm パッケージの既知の脆弱性を確認
[ -f "package-lock.json" ] && npm audit --json 2>/dev/null | jq '{vulnerabilities: .metadata.vulnerabilities}' 2>/dev/null

# セキュリティ問題を持つ古いパッケージを確認
[ -f "package.json" ] && npm outdated --json 2>/dev/null | jq 'to_entries | map(select(.value.current != .value.latest)) | length' 2>/dev/null
```

### ステップ 5: 認証とセッションの問題

```bash
# ハードコードされた JWT シークレット
grep -rn --include="*.{js,ts,py,go}" \
  -E "(jwt|JWT).*secret.*[=:].*['\"].{8,}['\"]" \
  --exclude-dir={node_modules,vendor,.git} . 2>/dev/null

# 欠けている CSRF 保護のパターン
grep -rn --include="*.{js,ts,py}" \
  -E "(POST|PUT|DELETE|PATCH).*fetch|axios\.(post|put|delete|patch)" \
  --exclude-dir={node_modules,vendor,.git} . 2>/dev/null | head -10
```

## 出力フォーマット

---

### 🛡️ セキュリティ監査レポート

**スキャン日時**: [タイムスタンプ]
**スコープ**: [スキャンされたディレクトリ]

### 🔴 クリティカルな問題

| 問題 | 場所 | 説明 |
|-------|----------|-------------|
| [タイプ] | [ファイル:行] | [簡単な説明] |

### 🟠 高重大度

| 問題 | 場所 | 推奨事項 |
|-------|----------|----------------|
| [タイプ] | [ファイル:行] | [修正の提案] |

### 🟡 中重大度

| 問題 | 場所 | 注記 |
|-------|----------|------|
| [タイプ] | [ファイル:行] | [コンテキスト] |

### 📊 サマリー

- **クリティカル**: X 件
- **高**: X 件
- **中**: X 件
- **依存関係**: X 件の脆弱性

### 🔧 クイック修正

1. [コマンド/コード付きの最高優先度の修正]
2. [2番目の優先度]
3. [3番目の優先度]

---

## 重大度レベル

| レベル | 例 | アクション |
|-------|----------|--------|
| 🔴 クリティカル | ハードコードされた本番シークレット、SQL インジェクション | 今すぐ修正 |
| 🟠 高 | 認証の欠如、XSS ベクター | デプロイ前に修正 |
| 🟡 中 | 古い依存関係、CSRF の欠如 | 修正を計画 |
| 🟢 低 | ベストプラクティスの違反 | 改善のために追跡 |

## 使用法

**完全な監査:**
```
/security
```

**特定のエリアにフォーカス:**
```
/security auth
/security deps
/security injection
```

**特定のファイル/ディレクトリ:**
```
/security src/api/
```

## 注意事項

- これはクイックヒューリスティックスキャンであり、包括的なセキュリティ監査ではありません
- 本番システムには、専用ツール（Snyk、SonarQube、OWASP ZAP）で補完してください
- 誤検知が発生する可能性があります — 所見を手動で確認してください
- 自動化されたプリコミットセキュリティチェックには `examples/hooks/security-hooks.sh` を参照してください

$ARGUMENTS
