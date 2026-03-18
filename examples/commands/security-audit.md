---
name: security-audit
description: "スコア付きのセキュリティポスチャ評価を含む包括的なセキュリティ監査"
---

# セキュリティ監査

プロジェクトと Claude Code 設定の包括的なセキュリティ監査。シークレットの露出、インジェクションサーフェス、依存関係、フックのセキュリティを分析し、スコア付きのセキュリティポスチャ評価と優先順位付けされた修正計画を生成します。

**時間**: 2-5分 | **スコープ**: フルプロジェクト + Claude Code 設定

> 設定のみのクイックチェックには `/security-check` を使用してください。

## 手順

あなたはシニアアプリケーションセキュリティエンジニアです。6フェーズのセキュリティ監査を実施し、優先順位付けされた修正計画を含むスコア付きレポートを生成してください。

---

### 事前ステップ: 監査コンテキストの確立

**チェックを実行する前に**、`AskUserQuestion` を使用して確認します:

1. **環境**: このコードは本番、ステージング、またはローカル開発で実行されていますか？
2. **スコープ**: 完全な監査または優先的に確認すべき特定のエリアがありますか？

正確な所見のために重要です:
- **ローカル開発**: `DEBUG=True`、CORS `*`、TLS なしの HTTP、`.env` ファイル — すべて正常。脆弱性としてフラグしない。代わりに「本番に移行する前に」という情報セクションに記載します。
- **ステージング**: 設定は本番を反映すべきです。逸脱は MEDIUM としてフラグします。
- **本番**: 設定ミスは完全な深刻度を持つ実際の所見です。

ユーザーが答えなかったり確認できない場合は、**本番**（保守的）をデフォルトとします。

---

### フェーズ 1: 設定のセキュリティ（/security-check 経由）

`/security-check`（`examples/commands/security-check.md` コマンド）のすべてのチェックを実行します。カバーする内容:
- CVE データベースに対する MCP サーバー監査
- 既知の悪意あるエントリに対するスキルとエージェント
- フックの漏洩パターン
- メモリポイズニング検出
- 権限と設定のレビュー
- Claude Code 設定内の公開されたシークレット

所見を記録します — 最終スコアに貢献します。

---

### フェーズ 2: プロジェクトのシークレットスキャン

公開されたシークレットと認証情報についてプロジェクト全体をスキャンします:

```bash
# API キーとトークン
grep -rn --include="*.{js,ts,py,go,java,rb,php,yaml,yml,json,toml,env,cfg,ini,conf}" \
  -E '(?i)(api[_-]?key|apikey|secret|password|passwd|token|bearer|auth)\s*[=:]\s*["'\''"][^"'\'']{8,}["'\''"]\s' \
  --exclude-dir={node_modules,vendor,.git,dist,build,target,__pycache__,.venv} . 2>/dev/null | head -30

# 既知のプロバイダーキーパターン
grep -rn -E 'sk-[a-zA-Z0-9]{20,}|sk-ant-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|AKIA[A-Z0-9]{16}|xox[bps]-[a-zA-Z0-9\-]{20,}' \
  --exclude-dir={node_modules,vendor,.git,dist,build,target} . 2>/dev/null | head -20

# 秘密鍵
grep -rn 'BEGIN.*PRIVATE KEY' --exclude-dir={node_modules,vendor,.git} . 2>/dev/null

# コミットされている可能性のある .env ファイル
find . -name ".env*" -not -path "*/node_modules/*" -not -path "*/.git/*" -type f 2>/dev/null

# .gitignore カバレッジを確認
[ -f ".gitignore" ] && {
  grep -q "\.env" .gitignore && echo "✅ .env in .gitignore" || echo "⚠️ .env NOT in .gitignore"
  grep -q "\.pem" .gitignore && echo "✅ .pem in .gitignore" || echo "⚠️ .pem NOT in .gitignore"
  grep -q "\.key" .gitignore && echo "✅ .key in .gitignore" || echo "⚠️ .key NOT in .gitignore"
}
```

**誤検知防止ルール — シークレット所見を報告する前に必須:**

シークレットの所見を上げる前に、これらの確認コマンドを実行します:

```bash
# 1. .env が .gitignore に実際に含まれているか確認（はいなら、ローカルの .env は所見ではない）
grep -n '\.env' .gitignore 2>/dev/null || echo ".env NOT in .gitignore"

# 2. シークレットが実際にコミットされているか確認（出力が空 = 所見なし）
git log --all -p -- '*.env' '*.key' '*.pem' '*.secret' 2>/dev/null | grep -E '^\+.*(password|secret|api_key|token)' | head -20

# 3. プロバイダー固有のパターンの git 履歴を確認
git log --all -p 2>/dev/null | grep -E '^\+(sk-[a-zA-Z0-9]{20,}|AKIA[A-Z0-9]{16}|ghp_[a-zA-Z0-9]{36})' | head -10
```

これらのコマンドからの**具体的な証拠がある場合のみ**シークレットの所見を報告します。`.env` ファイルがローカルに存在することは、`.gitignore` に含まれている場合は所見ではありません。パターンマッチングだけに基づいて「シークレットが公開されている可能性がある」と報告しない。

**スコアリング:**
- シークレット 0個 → +20ポイント
- 1-3個 → +10ポイント
- 4個以上 → 0ポイント
- 秘密鍵がコミットされた → -10ポイント

---

### フェーズ 3: プロンプトインジェクションサーフェス

インジェクションベクターの Markdown と設定ファイルを分析します:

```bash
# ゼロ幅文字（不可視の指示）
grep -rPn '[\x{200B}-\x{200D}\x{FEFF}]' --include="*.md" --include="*.yaml" --include="*.json" . 2>/dev/null

# 指示を含む隠れた HTML コメント
grep -rn '<!--' --include="*.md" . 2>/dev/null | grep -i 'ignore\|system\|admin\|instruction\|override\|forget'

# コメント内の Base64（潜在的な隠れたペイロード）
grep -rn -E '[#;].*[A-Za-z0-9+/]{20,}={0,2}' --include="*.py" --include="*.js" --include="*.ts" --include="*.md" \
  --exclude-dir={node_modules,vendor,.git} . 2>/dev/null | head -10

# ANSI エスケープシーケンス
grep -rPn '\x1b\[|\x1b\]|\x1b\(' --exclude-dir={node_modules,vendor,.git} . 2>/dev/null | head -10

# ヌルバイト
grep -rPn '\x00' --exclude-dir={node_modules,vendor,.git,dist} . 2>/dev/null | head -5

# Markdown/設定でのネストされたコマンド実行
grep -rn -E '\$\([^)]+\)|`[^`]+`' --include="*.md" --include="*.yaml" --include="*.json" \
  --exclude-dir={node_modules,vendor,.git} . 2>/dev/null | head -10
```

**スコアリング:**
- インジェクションベクター 0個 → +15ポイント
- 1-2個（おそらく誤検知） → +10ポイント
- 3個以上 → +5ポイント
- CLAUDE.md での確認済みインジェクション → 0ポイント

---

### フェーズ 4: 依存関係監査

プロジェクトに適切なパッケージ監査を実行します:

```bash
# Node.js
[ -f "package-lock.json" ] && npm audit --json 2>/dev/null | jq '{total: .metadata.vulnerabilities.total, critical: .metadata.vulnerabilities.critical, high: .metadata.vulnerabilities.high}' 2>/dev/null

# Python
[ -f "requirements.txt" ] && pip-audit -r requirements.txt 2>/dev/null || [ -f "pyproject.toml" ] && pip-audit 2>/dev/null

# Rust
[ -f "Cargo.toml" ] && cargo audit 2>/dev/null

# Go
[ -f "go.mod" ] && govulncheck ./... 2>/dev/null
```

パッケージマネージャーが検出されない場合は、その旨を記録してスキップします（ペナルティなし）。

**スコアリング:**
- 脆弱性 0個 → +20ポイント
- 0 クリティカル + 0 高 → +15ポイント
- 1-3 高 → +10ポイント
- クリティカルあり → +5ポイント
- 10以上の高または3以上のクリティカル → 0ポイント

---

### フェーズ 5: フックセキュリティ評価

`guide/security-hardening.md` のセキュリティフックが適切にインストールされているか確認します:

```bash
# 推奨されるセキュリティフックを確認
echo "=== Checking security hooks ==="

# PreToolUse フック（危険なパターンをブロックすべき）
ls .claude/hooks/PreToolUse* 2>/dev/null || echo "⚠️ No PreToolUse hooks found"

# PostToolUse フック（出力を監視すべき）
ls .claude/hooks/PostToolUse* 2>/dev/null || echo "⚠️ No PostToolUse hooks found"

# プロンプトインジェクション検出器が存在するか確認
find . -path "*/hooks/*injection*" -o -path "*/hooks/*security*" -o -path "*/hooks/*scanner*" 2>/dev/null

# フック設定の設定を確認
grep -c "hooks" .claude/settings.json 2>/dev/null || echo "No hooks in settings.json"
```

**スコアリング:**
- PreToolUse セキュリティフックがインストールされている → +10ポイント
- PostToolUse 出力スキャナーがインストールされている → +5ポイント
- プロンプトインジェクション検出器フック → +5ポイント
- フックが全くない → 0ポイント

---

### フェーズ 6: ポスチャスコア & レポート

合計スコアを計算してレポートを生成します。

**スコアリングの内訳:**

| カテゴリー | 最大ポイント | ソース |
|----------|-----------|--------|
| 設定セキュリティ（フェーズ 1） | 30 | /security-check の結果 |
| シークレットスキャン（フェーズ 2） | 20 | プロジェクト内で見つかったシークレット |
| インジェクションサーフェス（フェーズ 3） | 15 | 見つかったインジェクションベクター |
| 依存関係（フェーズ 4） | 20 | 脆弱性監査 |
| フックセキュリティ（フェーズ 5） | 15 | インストールされたセキュリティフック |
| **合計** | **100** | |

**フェーズ 1 スコアリングの詳細:**
- CRITICAL 所見 0個 → +15ポイント
- HIGH 所見 0個 → +10ポイント
- MEDIUM 所見 0個 → +5ポイント
- CRITICAL があれば → そのサブスコアは 0

**グレードスケール:**

| スコア | グレード | 意味 |
|-------|-------|---------|
| 90-100 | A | 優秀 — 本番対応のセキュリティポスチャ |
| 75-89 | B | 良好 — 軽微な改善を推奨 |
| 60-74 | C | 許容範囲 — 本番前に HIGH 問題に対処 |
| 40-59 | D | 不良 — 重大なセキュリティギャップ |
| 0-39 | F | クリティカル — デプロイしない、今すぐ CRITICAL 問題に対処 |

## 出力フォーマット

```
## 🛡️ Security Audit Report

**Date**: [timestamp]
**Project**: [directory name]
**Scope**: Full project + Claude Code configuration

### Security Posture Score: [XX]/100 (Grade [X])

[1文の評価]

### Phase Results

| Phase | Score | Max | Key Finding |
|-------|-------|-----|-------------|
| 1. Config Security | XX | 30 | [summary] |
| 2. Secrets Scan | XX | 20 | [summary] |
| 3. Injection Surface | XX | 15 | [summary] |
| 4. Dependencies | XX | 20 | [summary] |
| 5. Hook Security | XX | 15 | [summary] |
| **Total** | **XX** | **100** | |

### 🔴 Critical Findings
[各所見と場所、説明、正確な修正]

### 🟠 High Findings
[各所見と場所、説明、修正]

### 🟡 Medium Findings
[各所見と場所、説明、修正]

### 🔧 Remediation Plan (Priority Order)

| # | Action | Severity | Effort | Command/Steps |
|---|--------|----------|--------|---------------|
| 1 | [action] | CRITICAL | [time] | [how] |
| 2 | [action] | HIGH | [time] | [how] |
| ... | | | | |

### 📊 Benchmark

Your score vs security-hardening.md recommendations:
- [X] items from the guide are implemented
- [X] items are missing
- Top 3 missing items to implement next: [...]

### 📚 References
- Security hardening guide: guide/security-hardening.md
- Threat database: examples/commands/resources/threat-db.yaml
- Quick check: `/security-check`
- MCP scan tool: `npx mcp-scan` (Snyk)
```

$ARGUMENTS
