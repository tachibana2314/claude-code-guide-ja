---
name: sonarqube
description: "特定の PR の SonarCloud 品質問題を分析する"
---

# SonarQube 分析

特定の PR の SonarCloud 品質問題を分析します。メトリクス、主要違反者、アクションプランを含む包括的なレポートを生成します。

**コア原則:** 分析のみ = コード変更なし、純粋なインサイト。

## プロセス

1. **トークンを確認**: `$SONARQUBE_TOKEN` 環境変数を確認
2. **問題を取得**: SonarCloud API に PR の問題を呼び出す
3. **データを解析**: 重大度、タイプ、ファイル、ルール別にグループ化
4. **レポートを生成**: アクションプラン付きの構造化出力
5. **クリーンアップ**: 一時ファイルを削除

## 前提条件

### 環境変数

```bash
# SonarQube トークンを設定（~/.bashrc または ~/.zshrc に追加）
export SONARQUBE_TOKEN="your_token_here"

# トークンが設定されているか確認
echo $SONARQUBE_TOKEN
```

**トークンの取得方法:**
1. SonarCloud → My Account → Security に移動
2. 新しいトークンを生成
3. コピーして環境変数としてエクスポート

### プロジェクト設定

SonarCloud プロジェクトの詳細を設定します:

```bash
# プロジェクトの CLAUDE.md または環境変数として追加
SONAR_ORGANIZATION="your-org-name"
SONAR_PROJECT_KEY="your-org_your-project"
SONAR_BASE_URL="https://sonarcloud.io/api"
```

**設定されていない場合:** オーガニゼーションとプロジェクトキーを提供するようユーザーに確認します。

## 問題の取得

**重要:** `-u "$SONARQUBE_TOKEN:"` 直接 curl は zsh での認証解析のため失敗します。bash スクリプトラッパーを使用します:

```bash
# 認証を処理するための一時 bash スクリプトを作成
cat > /tmp/fetch_sonar.sh << 'SCRIPT'
#!/bin/bash
curl -s -u "${SONARQUBE_TOKEN}:" \
  "https://sonarcloud.io/api/issues/search?componentKeys=${SONAR_PROJECT_KEY}&pullRequest=$1&issueStatuses=OPEN,CONFIRMED&sinceLeakPeriod=true&ps=500"
SCRIPT

chmod +x /tmp/fetch_sonar.sh
/tmp/fetch_sonar.sh $PR_NUMBER > /tmp/sonar_pr_$PR_NUMBER.json
```

**API パラメーター:**
- `componentKeys`: プロジェクトキー
- `pullRequest`: PR 番号
- `issueStatuses`: OPEN,CONFIRMED（解決済みを除外）
- `sinceLeakPeriod`: この PR の新しい問題のみ
- `ps`: ページサイズ（最大 500）

## 分析スクリプト

`/tmp/sonar_analyze.js` に Node.js 分析スクリプトを作成します:

```javascript
const fs = require('fs');
const prNumber = process.argv[2];
const data = JSON.parse(fs.readFileSync(`/tmp/sonar_pr_${prNumber}.json`, 'utf8'));
const issues = data.issues || [];

// 重大度別にグループ化
const bySeverity = issues.reduce((acc, i) => {
  acc[i.severity] = (acc[i.severity] || 0) + 1;
  return acc;
}, {});

// タイプ別にグループ化
const byType = issues.reduce((acc, i) => {
  acc[i.type] = (acc[i.type] || 0) + 1;
  return acc;
}, {});

// ファイル別にグループ化
const byFile = issues.reduce((acc, i) => {
  const file = i.component.split(':')[1] || i.component;
  acc[file] = (acc[file] || 0) + 1;
  return acc;
}, {});

// ルール別にグループ化
const byRule = issues.reduce((acc, i) => {
  if (!acc[i.rule]) {
    acc[i.rule] = {
      count: 0,
      severity: i.severity,
      message: i.message
    };
  }
  acc[i.rule].count++;
  return acc;
}, {});

// 構造化データを出力
console.log(JSON.stringify({
  total: data.total,
  bySeverity,
  byType,
  topFiles: Object.entries(byFile)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10),
  topRules: Object.entries(byRule)
    .map(([rule, d]) => ({ rule, ...d }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 5)
}, null, 2));
```

**分析を実行:**
```bash
node /tmp/sonar_analyze.js $PR_NUMBER > /tmp/sonar_analysis_$PR_NUMBER.json
```

## レポートフォーマット

分析からフォーマットされたレポートを生成します:

```
📊 SonarCloud Analysis - PR #XXX

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📈 EXECUTIVE SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Issues: {TOTAL}

By Severity:
🔴 Blocker/Critical: {COUNT} ({PERCENTAGE}%)
🟡 Major: {COUNT} ({PERCENTAGE}%)
🔵 Minor/Info: {COUNT} ({PERCENTAGE}%)

By Type:
🐛 Bugs: {COUNT}
🛡️ Vulnerabilities: {COUNT}
🧹 Code Smells: {COUNT}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📂 TOP 10 FILES WITH ISSUES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. src/components/UserProfile.tsx - 8 issues
2. src/services/auth.service.ts - 5 issues
3. src/utils/validation.ts - 4 issues
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ TOP 5 VIOLATED RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. typescript:S1854 (MAJOR) - 12 occurrences
   "Dead stores should be removed"

2. typescript:S3776 (CRITICAL) - 8 occurrences
   "Cognitive Complexity of functions should not be too high"

3. typescript:S1186 (MINOR) - 6 occurrences
   "Functions should not be empty"
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ ACTION PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Priority 1 - CRITICAL/BLOCKER ({COUNT} issues):
  • マージ前に即座に修正
  • フォーカス先: {TOP_FILES}

Priority 2 - MAJOR ({COUNT} issues):
  • 可能であればこの PR で対処
  • 広範な場合は技術的負債チケットを検討

Priority 3 - MINOR/INFO ({COUNT} issues):
  • フォローアップ PR で対処可能
  • リファクタリングスプリントのバックログに追加

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 LINKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

View in SonarCloud:
https://sonarcloud.io/project/pull_requests_list?id={PROJECT_KEY}&pullRequest={PR_NUMBER}
```

## 重大度マッピング

| SonarCloud | シンボル | 優先度 | アクション |
|------------|--------|----------|--------|
| BLOCKER | 🔴 | P0 | 即座に修正 |
| CRITICAL | 🔴 | P0 | 即座に修正 |
| MAJOR | 🟡 | P1 | この PR で修正 |
| MINOR | 🔵 | P2 | フォローアップを検討 |
| INFO | 🔵 | P3 | オプションの改善 |

## 問題タイプ

| タイプ | シンボル | 説明 |
|------|--------|-------------|
| BUG | 🐛 | 明らかに間違っているコード |
| VULNERABILITY | 🛡️ | セキュリティの問題 |
| CODE_SMELL | 🧹 | 保守性の問題 |
| SECURITY_HOTSPOT | 🔒 | レビューが必要なセキュリティ重要コード |

## クリーンアップ

実行後は常に一時ファイルをクリーンアップします:

```bash
rm -f /tmp/fetch_sonar.sh
rm -f /tmp/sonar_pr_$PR_NUMBER.json
rm -f /tmp/sonar_analyze.js
rm -f /tmp/sonar_analysis_$PR_NUMBER.json
```

## エラーハンドリング

| エラー | 原因 | アクション |
|-------|-------|--------|
| トークンが設定されていない | `$SONARQUBE_TOKEN` がない | トークンをエクスポートするようユーザーに確認 |
| 401 Unauthorized | 無効または期限切れのトークン | SonarCloud から新しいトークンを取得 |
| 404 Not Found | SonarCloud に PR が存在しない | PR 番号とプロジェクトキーを確認 |
| 空のレスポンス | 問題が見つからない | クリーンな PR を報告、チームを称える |
| >500 の問題 | ページネーション制限に達した | データが不完全であることを警告、フィルタリングを提案 |
| ネットワークエラー | API に到達できない | インターネット接続を確認、再試行 |

## 設定オプション

### プロジェクトレベルの設定

`.sonarcloud.properties` を作成または `CLAUDE.md` に追加します:

```properties
# SonarCloud Configuration
SONAR_ORGANIZATION=your-org
SONAR_PROJECT_KEY=your-org_your-project
SONAR_EXCLUSIONS=**/*.test.ts,**/*.spec.ts,**/migrations/**
SONAR_COVERAGE_EXCLUSIONS=**/*.test.ts,src/test/**
```

### API レート制限

SonarCloud API の制限:
- 無料ティア: 10,000 リクエスト/日
- 有料ティア: 無制限

**ヒント:** 同じ PR への繰り返しクエリには結果をキャッシュします。

## 統合例

### GitHub Actions

```yaml
- name: SonarQube Analysis
  run: |
    export SONARQUBE_TOKEN=${{ secrets.SONAR_TOKEN }}
    export SONAR_PROJECT_KEY="${{ secrets.SONAR_PROJECT }}"
    claude -p "/sonarqube ${{ github.event.pull_request.number }}"
```

### プレマージフック

`.claude/hooks/pre-merge.sh` に追加します:

```bash
#!/bin/bash
PR_NUMBER=$(gh pr view --json number -q .number)
claude -p "/sonarqube $PR_NUMBER"
```

## 禁止事項

**決してやってはいけないこと:**
- ❌ コードを変更または問題を自動修正する（分析のみのコマンド）
- ❌ トークン確認をスキップする（セキュリティリスク）
- ❌ `/tmp` に一時ファイルを残す（クリーンアップが必要）
- ❌ SonarQube トークンをリポジトリにコミットする（環境変数を使用）
- ❌ トークンの有効期限を確認せずに実行する

**常に行うこと:**
- ✅ 構造化された実行可能なレポートを生成する
- ✅ 実行後にクリーンアップする
- ✅ API エラーを適切に処理する
- ✅ API 呼び出し前にトークンが有効か確認する
- ✅ データを解析して明確に表示する

## 高度な使用法

### カスタムフィルター

```bash
# クリティカル/ブロッカーの問題のみを表示
/sonarqube 123 --severity BLOCKER,CRITICAL

# バグと脆弱性のみを表示
/sonarqube 123 --types BUG,VULNERABILITY

# 特定のファイルパターン
/sonarqube 123 --files "src/services/**"
```

### 複数の PR

```bash
# PR 間で問題を比較
/sonarqube 123,124,125 --compare
```

## トラブルシューティング

### 問題: "curl: (22) The requested URL returned error: 401"

**原因:** 無効または欠落しているトークン

**修正:**
```bash
# SonarCloud でトークンを再生成
# 新しいトークンをエクスポート
export SONARQUBE_TOKEN="new_token_here"
```

### 問題: 「空のレスポンスまたは問題なし」

**原因:** 分析がまだ完了していないか PR が分析されていない

**修正:** SonarCloud の分析が完了するのを待つ（PR 作成後約2-5分）

### 問題: 「componentKeys が見つかりません」

**原因:** プロジェクトキーが間違っている

**修正:** SonarCloud URL でプロジェクトキーを確認:
```
https://sonarcloud.io/project/overview?id=YOUR_PROJECT_KEY
```

## 使用例

```bash
# 基本的な使用法
/sonarqube 170

# PR プレフィックス付き
/sonarqube PR #234

# PR URL を使用
/sonarqube https://github.com/org/repo/pull/170

# カスタム重大度フィルター（実装されている場合）
/sonarqube 170 --critical-only
```

PR 番号: $ARGUMENTS
