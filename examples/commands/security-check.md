---
layout: default
title: "セキュリティチェック"
parent: コマンド
grand_parent: テンプレート
nav_order: 25
---


# セキュリティチェック

既知の脅威データベースに対するクイックな設定セキュリティチェック。Claude Code の設定に対して既知の悪意あるスキル、脆弱な MCP、危険なパターン、公開されたシークレットを検証します。

**時間**: 約30秒 | **スコープ**: Claude Code 設定のみ

## 手順

あなたはセキュリティアナリストです。`examples/commands/resources/threat-db.yaml` にバンドルされた脅威インテリジェンスデータベースに対してユーザーの Claude Code 設定を確認します。簡潔で実行可能なレポートを生成します。

### フェーズ 1: 脅威データベースの読み込み

このリポジトリから `examples/commands/resources/threat-db.yaml` を読み込んで以下を取得します:
- 既知の悪意あるオーサーとスキル
- MCP サーバーの CVE データベース
- フック、エージェント、設定の疑わしいパターン

### フェーズ 2: MCP サーバー監査

ユーザーの MCP 設定を読み込みます:

```bash
# グローバル MCP 設定
cat ~/.claude.json 2>/dev/null | jq '.mcpServers // empty'

# プロジェクト MCP 設定
cat .mcp.json 2>/dev/null
```

**threat-db.yaml に対して確認:**
- [ ] CVE エントリと一致する MCP サーバーがあるか？ → CRITICAL
- [ ] バージョン固定: すべての MCP サーバーが正確なバージョンに固定されているか（`@latest` ではない）？ → 固定されていない場合 HIGH
- [ ] MCP 引数に `--dangerous-*` フラグがあるか？ → CRITICAL
- [ ] Safe List にない MCP サーバーがあるか（`guide/security-hardening.md` §1.1 参照）？ → MEDIUM（手動レビューのためフラグ）

### フェーズ 3: スキルとエージェントの監査

```bash
# インストールされたスキルを一覧表示
ls -la .claude/skills/ 2>/dev/null
ls -la ~/.claude/skills/ 2>/dev/null

# エージェントを一覧表示
ls -la .claude/agents/ 2>/dev/null
ls -la ~/.claude/agents/ 2>/dev/null

# エージェントのツールフィールドを確認
grep -r "^tools:" .claude/agents/ 2>/dev/null
grep -r "^tools:" ~/.claude/agents/ 2>/dev/null
```

**threat-db.yaml に対して確認:**
- [ ] `malicious_skills` エントリと一致するスキル/エージェント名があるか？ → CRITICAL
- [ ] `malicious_authors` エントリと一致するスキル/エージェントのオーサーがあるか？ → CRITICAL
- [ ] `tools: Bash` のみのエージェントがあるか？ → HIGH
- [ ] 広範なツールアクセスと曖昧な説明を持つエージェントがあるか？ → MEDIUM

### フェーズ 4: フックのセキュリティ

```bash
# すべてのフックを一覧表示
find .claude/hooks/ -type f 2>/dev/null
find ~/.claude/hooks/ -type f 2>/dev/null

# 疑わしいパターンのフックをスキャン
grep -rn "curl\|wget\|nc \|ncat\|netcat\|base64\|eval\|exec\|/dev/tcp\|/dev/udp" .claude/hooks/ 2>/dev/null
grep -rn "curl\|wget\|nc \|ncat\|netcat\|base64\|eval\|exec\|/dev/tcp\|/dev/udp" ~/.claude/hooks/ 2>/dev/null

# フック内の認証情報アクセスを確認
grep -rn "ssh\|id_rsa\|id_ed25519\|\.env\|credentials\|secret\|password\|token\|api.key" .claude/hooks/ 2>/dev/null
grep -rn "ssh\|id_rsa\|id_ed25519\|\.env\|credentials\|secret\|password\|token\|api.key" ~/.claude/hooks/ 2>/dev/null
```

**threat-db.yaml の `suspicious_patterns.hooks` に対して確認:**
- [ ] ネットワーク呼び出し（`curl`、`wget`） → HIGH
- [ ] リバースシェルインジケーター（`nc`、`/dev/tcp`） → CRITICAL
- [ ] 認証情報アクセス（`ssh`、`.env`、`password`） → CRITICAL
- [ ] Base64 エンコーディング → MEDIUM（コンテキストをレビュー）

### フェーズ 5: メモリポイズニングチェック

```bash
# メモリ/設定ファイル内の疑わしい指示を確認
grep -in "ignore\|forget\|override\|disregard\|you are now\|new role\|system prompt" \
  CLAUDE.md .claude/CLAUDE.md SOUL.md .claude/SOUL.md MEMORY.md .claude/MEMORY.md \
  ~/.claude/CLAUDE.md ~/.claude/MEMORY.md 2>/dev/null
```

- [ ] CLAUDE.md / SOUL.md / MEMORY.md にプロンプトインジェクションパターンがあるか？ → HIGH
- [ ] セキュリティを無効にする、レビューをスキップする、広範な権限を付与するよう指示があるか？ → CRITICAL

### フェーズ 6: 権限と設定

```bash
# 設定を確認
cat .claude/settings.json 2>/dev/null
cat ~/.claude/settings.json 2>/dev/null
```

- [ ] `permissions.deny` が存在して `.env*`、`*.pem`、`*.key`、シークレットをカバーしているか？ → 欠けている場合 MEDIUM
- [ ] Bash または Write に対してワイルドカードの `permissions.allow` がないか？ → ある場合 HIGH
- [ ] `dangerouslySkipPermissions` や類似のフラグがないか？ → ある場合 CRITICAL

### フェーズ 7: 設定内の公開されたシークレット

```bash
# .claude/ ディレクトリのシークレットを確認
grep -rn "sk-[a-zA-Z0-9]\{20,\}\|sk-ant-[a-zA-Z0-9]\{20,\}\|ghp_[a-zA-Z0-9]\{36\}\|AKIA[A-Z0-9]\{16\}" \
  .claude/ ~/.claude/ 2>/dev/null

# 秘密鍵を確認
grep -rn "BEGIN.*PRIVATE KEY" .claude/ ~/.claude/ 2>/dev/null
```

- [ ] 設定ファイルに API キーまたはトークンがあるか？ → CRITICAL
- [ ] 設定に秘密鍵があるか？ → CRITICAL

## 出力フォーマット

```
## 🛡️ Security Check Report

**Date**: [timestamp]
**Scope**: Claude Code configuration

### Results Summary

| Severity | Count | Status |
|----------|-------|--------|
| 🔴 CRITICAL | X | [PASS/FAIL] |
| 🟠 HIGH | X | [PASS/FAIL] |
| 🟡 MEDIUM | X | [PASS/FAIL] |
| 🟢 LOW | X | [PASS/FAIL] |

### 🔴 Critical Issues
[各クリティカルな所見と場所、修正]

### 🟠 High Issues
[各 HIGH な所見と場所、修正]

### 🟡 Medium Issues
[各 MEDIUM な所見と場所、修正]

### ✅ Passed Checks
[合格したもの — 信頼のために重要]

### 🔧 Recommended Actions (Priority Order)
1. [最も緊急な修正と正確なコマンド]
2. [2番目の優先度]
3. [...]

### 📚 References
- Full security guide: guide/security-hardening.md
- Threat database: examples/commands/resources/threat-db.yaml
- MCP scan: `npx mcp-scan` (Snyk)
```

すべてのチェックが合格した場合:

```
## 🛡️ Security Check Report — ALL CLEAR ✅

**Date**: [timestamp]
No known threats detected in your Claude Code configuration.

**Recommendations for continued security:**
- Re-run `/security-check` after installing new skills or MCP servers
- Run `/security-audit` for a comprehensive project + config audit
- Keep Claude Code updated (current security fixes in v2.1.34+)
```

$ARGUMENTS
