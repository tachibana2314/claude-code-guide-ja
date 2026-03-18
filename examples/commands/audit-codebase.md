---
name: audit-codebase
description: "7 カテゴリのスコアリングと進捗計画によるコードベース健全性監査"
---

# コードベース健全性監査

7 つの健全性カテゴリにわたってコードベースをスコアリングし、弱点を特定して、優先順位付けされた進捗計画を作成します。各カテゴリは具体的でアクションに繋がる所見とともに 1〜10 でスコアリングされます。

**所要時間**: コードベースのサイズによって 3〜8 分 | **スコープ**: プロジェクト全体

## 指示

あなたはコードベース健全性評価を実施する上級エンジニアリングコンサルタントです。7 つのカテゴリ（または `$ARGUMENTS` でカテゴリが指定されている場合はそのサブセット）にわたってプロジェクトを分析し、各カテゴリをスコアリングして、進捗計画を作成してください。

`$ARGUMENTS` にカテゴリ名が含まれている場合（例: 「secrets security tests」）、それらのカテゴリのみを監査します。それ以外の場合は 7 つすべてを監査します。

---

### カテゴリ 1: シークレット（重み: 15%）

コード内のハードコードされた認証情報、API キー、機密データをスキャンします。

```bash
# コード内の API キーとトークン
grep -rn --include="*.{js,ts,py,go,java,rb,php,yaml,yml,json,toml,env,cfg,ini,conf}" \
  -E '(?i)(api[_-]?key|apikey|secret[_-]?key|password|passwd|token|bearer)\s*[=:]\s*["'\''"][^"'\'']{8,}' \
  --exclude-dir={node_modules,vendor,.git,dist,build,target,__pycache__,.venv} . 2>/dev/null | head -20

# 既知のプロバイダーパターン
grep -rn -E 'sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|AKIA[A-Z0-9]{16}|xox[bps]-[a-zA-Z0-9\-]{20,}' \
  --exclude-dir={node_modules,vendor,.git,dist,build,target} . 2>/dev/null | head -10

# コミットされた .env ファイル
find . -name ".env*" -not -name ".env.example" -not -path "*/node_modules/*" -not -path "*/.git/*" -type f 2>/dev/null

# .gitignore のカバレッジ
[ -f ".gitignore" ] && {
  for pattern in ".env" "*.pem" "*.key" "*.p12"; do
    grep -q "$pattern" .gitignore 2>/dev/null && echo "OK: $pattern in .gitignore" || echo "MISSING: $pattern not in .gitignore"
  done
}
```

**スコアリング:**
- 10: シークレットなし、.gitignore がすべての機密パターンをカバー、.env.example が存在する
- 7〜9: コードにシークレットなし、軽微な .gitignore のギャップ
- 4〜6: 1〜3 個の潜在的なシークレット（偽陽性の可能性）、または .env がコミットされている
- 1〜3: コードに複数のシークレット、秘密鍵がコミットされている、.gitignore による保護なし

---

### カテゴリ 2: セキュリティ（重み: 15%）

OWASP スタイルの脆弱性と安全でないパターンを確認します。

```bash
# SQL インジェクションパターン
grep -rn --include="*.{js,ts,py,java,go,rb,php}" \
  -E '(query|execute|exec)\s*\(\s*[`"'\''"].*\+|\$\{|%s|\.format\(' \
  --exclude-dir={node_modules,vendor,.git,dist,build,target,test,__test__} . 2>/dev/null | head -15

# eval/exec の使用
grep -rn -E '\b(eval|exec|execSync|Function\(|setTimeout\([^,]*[+`]|setInterval\([^,]*[+`])' \
  --include="*.{js,ts,py}" --exclude-dir={node_modules,vendor,.git,dist} . 2>/dev/null | head -10

# 安全でないデシリアライゼーション
grep -rn -E '(pickle\.loads|yaml\.load\(|JSON\.parse\(.*user|unserialize\()' \
  --exclude-dir={node_modules,vendor,.git,dist} . 2>/dev/null | head -10

# ルート/エンドポイントの入力バリデーション欠如
grep -rn -E '(app\.(get|post|put|delete|patch)|router\.(get|post|put|delete))' \
  --include="*.{js,ts}" --exclude-dir={node_modules,.git,dist} . 2>/dev/null | wc -l
```

**スコアリング:**
- 10: インジェクションパターンなし、eval/exec なし、すべてのエンドポイントで入力バリデーション、CSP ヘッダー
- 7〜9: 軽微な問題（ユーザー向けでないコードでの 1〜2 個の eval 使用）
- 4〜6: いくつかのインジェクションパターン、複数のエンドポイントでバリデーション欠如
- 1〜3: 積極的な SQL インジェクションリスク、ユーザー入力での eval、入力サニタイゼーションなし

---

### カテゴリ 3: 依存関係（重み: 15%）

パッケージの健全性、既知の CVE、鮮度を監査します。

```bash
# Node.js 監査
[ -f "package-lock.json" ] && npm audit --json 2>/dev/null | jq '.metadata.vulnerabilities' 2>/dev/null
[ -f "package.json" ] && npx npm-check 2>/dev/null | tail -20

# Python
[ -f "requirements.txt" ] && pip-audit -r requirements.txt 2>/dev/null | tail -20
[ -f "pyproject.toml" ] && pip-audit 2>/dev/null | tail -20

# Rust
[ -f "Cargo.toml" ] && cargo audit 2>/dev/null | tail -20

# Go
[ -f "go.mod" ] && govulncheck ./... 2>/dev/null | tail -20

# ロックファイルの存在
for lockfile in package-lock.json yarn.lock pnpm-lock.yaml Cargo.lock go.sum poetry.lock; do
  [ -f "$lockfile" ] && echo "OK: $lockfile exists"
done
[ ! -f "package-lock.json" ] && [ ! -f "yarn.lock" ] && [ ! -f "pnpm-lock.yaml" ] && [ -f "package.json" ] && echo "MISSING: No lockfile for Node.js project"
```

**スコアリング:**
- 10: CVE なし、ロックファイルあり、すべての依存関係が 6 ヶ月未満
- 7〜9: クリティカル/高 CVE なし、軽微な古い依存関係
- 4〜6: 1〜3 個の高 CVE、または 50% 超の依存関係が 1 年以上古い
- 1〜3: クリティカルな CVE、ロックファイルなし、放棄された依存関係

---

### カテゴリ 4: 構造（重み: 10%）

ファイル構成、命名規則、モジュール境界を評価します。

```bash
# トップレベルディレクトリごとのファイル数
for dir in */; do
  [ -d "$dir" ] && [ "$dir" != "node_modules/" ] && [ "$dir" != ".git/" ] && [ "$dir" != "vendor/" ] && \
    echo "$dir: $(find "$dir" -type f -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | wc -l) files"
done

# 深くネストされたファイル（複雑さの指標）
find . -type f -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/vendor/*" -mindepth 6 2>/dev/null | head -10

# 混在した命名規則
find . -type f -name "*_*" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -5
find . -type f -name "*-*" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -5

# 循環依存の指標（JS/TS プロジェクト向け）
[ -f "package.json" ] && npx madge --circular --extensions ts,js src/ 2>/dev/null | head -20
```

**スコアリング:**
- 10: 明確なモジュール境界、一貫した命名、循環依存なし、フラットな階層
- 7〜9: 軽微な不整合のある良好な構造
- 4〜6: 混在した規約、いくつかの循環依存、不明確なモジュール境界
- 1〜3: 明確な構造なし、深くネストされたファイル、広範な循環依存

---

### カテゴリ 5: テスト（重み: 15%）

テストカバレッジ、テスト品質、テストプラクティスを評価します。

```bash
# ソースファイルに対するテストファイル数
TEST_COUNT=$(find . -type f \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*" -o -path "*/test/*" -o -path "*/__tests__/*" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | wc -l)
SRC_COUNT=$(find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.java" \) \
  -not -name "*.test.*" -not -name "*.spec.*" -not -name "test_*" \
  -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
echo "Test files: $TEST_COUNT | Source files: $SRC_COUNT | Ratio: $(echo "scale=2; $TEST_COUNT / ($SRC_COUNT + 1)" | bc)"

# カバレッジ設定の存在
for cfg in jest.config.* vitest.config.* .nycrc .coveragerc pytest.ini setup.cfg; do
  [ -f "$cfg" ] && echo "OK: $cfg exists"
done

# カバレッジレポート（利用可能な場合）
[ -d "coverage" ] && [ -f "coverage/coverage-summary.json" ] && cat coverage/coverage-summary.json | jq '.total' 2>/dev/null

# スナップショットテスト数（潜在的なメンテナンス負担）
find . -name "*.snap" -not -path "*/node_modules/*" 2>/dev/null | wc -l
```

**スコアリング:**
- 10: >0.8 のテスト比率、カバレッジ >80%、CI でテストを実行、古いスナップショットなし
- 7〜9: >0.5 のテスト比率、カバレッジ >60%、カバレッジ設定あり
- 4〜6: テストは存在するがギャップが明らか、カバレッジ追跡なし
- 1〜3: <0.2 のテスト比率またはテストなし

---

### カテゴリ 6: インポート（重み: 10%）

未使用のインポート、循環依存、型カバレッジを確認します。

```bash
# 未使用のインポート（TypeScript/JavaScript）
[ -f "tsconfig.json" ] && npx tsc --noEmit 2>&1 | grep -c "declared but" 2>/dev/null
[ -f "tsconfig.json" ] && npx tsc --noEmit 2>&1 | grep "declared but" | head -10

# TypeScript の strict モード
[ -f "tsconfig.json" ] && grep -E '"strict"|"noImplicitAny"|"strictNullChecks"' tsconfig.json 2>/dev/null

# Python の未使用インポート
[ -f "pyproject.toml" ] || [ -f "setup.py" ] && python -m pyflakes . 2>/dev/null | grep "imported but unused" | head -10

# ワイルドカードインポート（コードスメル）
grep -rn 'import \*' --include="*.{py,ts,js}" --exclude-dir={node_modules,vendor,.git} . 2>/dev/null | head -10
```

**スコアリング:**
- 10: 未使用インポートなし、TypeScript strict モード、ワイルドカードインポートなし
- 7〜9: 未使用インポート 5 件未満、strict モードが有効で軽微なギャップ
- 4〜6: 未使用インポート 5〜20 件、strict モードなし、いくつかのワイルドカードインポート
- 1〜3: 未使用インポート 20 件超、広範なワイルドカードインポート、型チェックなし

---

### カテゴリ 7: AI パターン（重み: 20%）

Claude Code 設定の成熟度と AI 支援開発の準備状況を評価します。

```bash
# CLAUDE.md の存在と品質
[ -f "CLAUDE.md" ] && echo "OK: CLAUDE.md exists ($(wc -l < CLAUDE.md) lines)" || echo "MISSING: No CLAUDE.md"
[ -f ".claude/settings.json" ] && echo "OK: .claude/settings.json exists" || echo "MISSING: No .claude/settings.json"

# カスタムコマンド
COMMANDS=$(find .claude/commands -name "*.md" 2>/dev/null | wc -l)
echo "Custom commands: $COMMANDS"

# フック
HOOKS_CFG=$(grep -c "hooks" .claude/settings.json 2>/dev/null || echo "0")
echo "Hook configurations: $HOOKS_CFG"

# ルールファイル
RULES=$(find .claude/rules -name "*.md" 2>/dev/null | wc -l)
echo "Rule files: $RULES"

# エージェント
AGENTS=$(find .claude/agents -name "*.md" 2>/dev/null | wc -l)
echo "Agent definitions: $AGENTS"

# スキル
SKILLS=$(find .claude/skills -name "*.md" 2>/dev/null | wc -l)
echo "Skills: $SKILLS"

# AI アーティファクトの .gitignore
grep -q "claude" .gitignore 2>/dev/null && echo "OK: Claude patterns in .gitignore" || echo "INFO: No Claude patterns in .gitignore"
```

**スコアリング:**
- 10: 規約付きの CLAUDE.md、設定済みフック、カスタムコマンド、ルール、エージェント
- 7〜9: プロジェクトコンテキストのある CLAUDE.md、いくつかのコマンドまたはルール
- 4〜6: 基本的な CLAUDE.md、フックやコマンドなし
- 1〜3: CLAUDE.md なしまたは空

---

## スコアリングとレポート

### 総合スコアの計算

```
Overall = (Secrets * 0.15) + (Security * 0.15) + (Dependencies * 0.15) +
          (Structure * 0.10) + (Tests * 0.15) + (Imports * 0.10) +
          (AI Patterns * 0.20)
```

小数点第 1 位に丸める。

### 出力フォーマット

```markdown
## コードベース健全性監査

**プロジェクト**: [ディレクトリ名]
**日付**: [タイムスタンプ]
**監査されたカテゴリ**: [全 7 カテゴリまたは絞り込まれたサブセット]

### 総合スコア: [X.X] / 10

| カテゴリ | スコア | 重み | 加重 | 主な所見 |
|----------|-------|--------|----------|-------------|
| シークレット | X/10 | 15% | X.XX | [一行サマリー] |
| セキュリティ | X/10 | 15% | X.XX | [一行サマリー] |
| 依存関係 | X/10 | 15% | X.XX | [一行サマリー] |
| 構造 | X/10 | 10% | X.XX | [一行サマリー] |
| テスト | X/10 | 15% | X.XX | [一行サマリー] |
| インポート | X/10 | 10% | X.XX | [一行サマリー] |
| AI パターン | X/10 | 20% | X.XX | [一行サマリー] |
| **総合** | | **100%** | **X.XX** | |

### 詳細な所見

#### 🔴 クリティカル（即座に修正）
- [file:line 参照と具体的な修正を含む所見]

#### 🟡 警告（今週中に修正）
- [コンテキストと提案アプローチを含む所見]

#### 🟢 情報（改善できれば良い）
- [オプションの提案を含む観察]

### 進捗計画

[総合スコアに基づいて適切なティアを表示]

#### ティア 1: 基盤（現在のスコア <5、目標: 5）
他のことの前にクリティカルなリスクの排除に集中する。

| 優先度 | アクション | カテゴリ | 影響 | 工数 |
|----------|--------|----------|--------|--------|
| 1 | [具体的なアクション] | [カテゴリ] | [スコア増加] | [時間見積もり] |
| 2 | [具体的なアクション] | [カテゴリ] | [スコア増加] | [時間見積もり] |
| ... | | | | |

#### ティア 2: 安定（現在のスコア 5〜7、目標: 8）
基盤の上に信頼性の高いプラクティスを構築する。

| 優先度 | アクション | カテゴリ | 影響 | 工数 |
|----------|--------|----------|--------|--------|
| 1 | [具体的なアクション] | [カテゴリ] | [スコア増加] | [時間見積もり] |
| ... | | | | |

#### ティア 3: 優秀（現在のスコア 8+、目標: 10）
最大のチームベロシティのために仕上げと最適化を行う。

| 優先度 | アクション | カテゴリ | 影響 | 工数 |
|----------|--------|----------|--------|--------|
| 1 | [具体的なアクション] | [カテゴリ] | [スコア増加] | [時間見積もり] |
| ... | | | | |

### クイックウィン（各 30 分未満）
1. [最小限の工数でスコアを改善するアクション]
2. [...]
3. [...]
```

### 重大度の分割

所見の約 70% は自動化可能であるべきです（スクリプト、リンター、CI チェックで検出できる）。残りの 30% は人間の判断が必要としてフラグを立て、それらのケースで自動化が不十分な理由を説明してください。

---

**出典**:
- Variant Systems コードベース分析プラグイン（variantsystems.io, 2026 年 2 月）: 7 カテゴリ分析フレームワーク
- OWASP Top 10（2021）: セキュリティカテゴリパターン
- Claude Code セキュリティ強化ガイド: AI パターンカテゴリベースライン

$ARGUMENTS
