---
title: "Claude CodeのエンタープライズAIガバナンス"
description: "大規模にClaude Codeを展開するチームのための組織レベルのガバナンス: 使用チャーター、MCP承認ワークフロー、ガードレールティア、コンプライアンス"
tags: [security, enterprise, governance, compliance]
---

# Claude CodeのエンタープライズAIガバナンス

> **対象**: Claude Codeをチーム全体にデプロイするテックリード、エンジニアリングマネージャー、セキュリティオフィサー。
>
> **スコープ**: 組織レベルのガバナンス（ポリシー、承認ワークフロー、ティア、コンプライアンス）。個人開発者のセキュリティ（インジェクション防御、MCPの審査、CVE）については[security-hardening.md](./security-hardening.md)を参照。6つの交渉不可能な本番ルールについては[production-safety.md](./production-safety.md)を参照。

---

## TL;DR

**ガバナンスのギャップ**: Claude Codeのセキュリティドキュメントは、個々の開発者が何をすべきかをカバーしている。しかし、組織全体でそれを使用する場合 — 50人の開発者、異なるリスクプロファイル、共有ポリシーなし — に何が起きるかはカバーされていない。

**このドキュメントのカバー内容**:

| セクション | 提供される内容 |
|---------|------------------|
| [ローカル対共有](#1-local-vs-shared-the-governance-split) | リスクマトリックス + 意思決定フレームワーク |
| [使用チャーター](#2-ai-usage-charter) | リーンテンプレート、適応可能 |
| [MCPガバナンス](#3-mcp-governance-workflow) | 承認ワークフロー + YAMLレジストリ |
| [ガードレールティア](#4-guardrail-tiers) | 4つの事前設定済みティア、settings.jsonをコピー&ペースト |
| [大規模ポリシー](#5-policy-enforcement-at-scale) | 展開、オンボーディング、CI/CDゲート |
| [監査とコンプライアンス](#6-audit-compliance--governance-structure) | SOC2/ISO27001の監査人が実際に尋ねること |

---

## 1. ローカル対共有: ガバナンスの分割

エンタープライズAIガバナンスにおける最大の間違いは、すべてに同じルールを適用することだ。ローカルの使用と共有の使用では、根本的に異なるリスクプロファイルを持つ。

### 1.1 リスクマトリックス

| 次元 | ローカルの使用 | 共有の使用 |
|-----------|-------------|--------------|
| **データ露出** | 開発者自身のファイル | 顧客データ、共有コードベース、機密情報 |
| **影響範囲** | 1台のマシン | リポジトリ全体、CI/CD、本番環境 |
| **説明責任** | 個人 | チーム / 組織 |
| **再現性** | セッションが終わると履歴が消える | 監査証跡が必要 |
| **コンプライアンス範囲** | 通常なし | SOC2、ISO27001、HIPAA（該当する場合） |
| **設定のドリフト** | 個人の好み | チームの一貫性が重要 |

### 1.2 制御できることと制御できないこと

**制御できること**（コミットされた設定経由）:
- どのMCPサーバーが承認されているか（リポジトリの`settings.json`）
- Claudeが使用できるツール（`permissions.deny`）
- CLAUDE.mdがプロジェクトの規約について何を言っているか
- ツール使用前後に実行されるフックスクリプト
- AIが生成したコードを検証するCI/CDゲート

**直接制御できないこと**:
- 開発者が持つ個人の`~/.claude/settings.json`
- 個人のAPIキーで使用するモデル
- 自分のリポジトリ外の個人プロジェクトでの行動
- セッション間のメモリ / セッションコンテンツ

**実際的な意味**: リポジトリにコミットされているものと共有環境にデプロイされているものにガバナンスを集中させる。個人の開発ワークフローは開発者の責任だ。

### 1.3 意思決定フレームワーク: いつガバナンスを適用するか

すべてのものに重いガバナンスが必要なわけではない。制御を比例的に適用する。

```
何をガバナンスしているか?
│
├─ 個人の開発ワークフロー（ローカル、使い捨てコード）
│   └─ 最小限: CLAUDE.mdガイドライン + 基本的なフック
│
├─ チームのコードベース（共有リポジトリ、本番ではない）
│   └─ 標準: 共有settings.json + MCPレジストリ + PRゲート
│
├─ 本番システム（顧客向け、実データ）
│   └─ 厳格: フルティア設定 + 承認ワークフロー + 監査ログ
│
└─ 規制環境（HIPAA、SOC2、PCI、金融）
    └─ 規制対応: 上記すべて + コンプライアンス監査証跡
```

---

## 2. AI使用チャーター

使用チャーターは、「この会社でClaude Codeで何ができるか？」という根本的な問いに答える。これがなければ、各チームが異なる答えを出し、一貫性のないリスク露出が生まれる。

これはリーン版だ。法的考慮事項を含む完全なチャーターについては、[ホワイトペーパー#11: エンタープライズAIガバナンス](../../whitepapers/en/11-enterprise-ai-governance.qmd)（利用可能になった時点）を参照。

### 2.1 リーンチャーターテンプレート

これを組織の`docs/ai-usage-charter.md`にコピーして適応させる:

```markdown
# AIコーディングツール使用チャーター

**適用範囲**: Claude Code（およびすべてのAIコーディングアシスタント）
**発効日**: [DATE]
**オーナー**: エンジニアリングリード / CTO
**レビューサイクル**: 四半期

---

## 承認済みツール

| ツール | スコープ | データ分類 |
|------|-------|---------------------|
| Claude Code (Pro/Team/Enterprise) | すべての開発作業 | CONFIDENTIALまで |
| Claude Code（個人アカウント） | 個人開発のみ | PUBLIC/INTERNALのみ |
| [その他の承認済みツール] | [スコープ] | [分類] |

---

## データ分類ルール

| 分類 | 例 | Claude Codeで許可? |
|----------------|----------|--------------------------|
| **PUBLIC** | オープンソース、公開ドキュメント | はい、制限なし |
| **INTERNAL** | 内部ツール、機密性の低いコード | はい、標準設定 |
| **CONFIDENTIAL** | 内部ビジネスシークレット、規制対象外のIP | はい、Enterpriseプランのみ |
| **RESTRICTED** | 顧客PII、PCIカードデータ、PHI、認証情報 | いいえ — 法務/コンプライアンスの承認なしにAIコンテキストに入れない |

**ハードルール**: RESTRICTEDデータはAIコンテキストウィンドウに絶対に入れない。プロンプトにも、Claudeが読み込むファイルにも、例としてもダメだ。制限されたファイルへのアクセスをブロックするために`permissions.deny`を設定すること。

---

## 承認されたユースケース

- コード補完、レビュー、リファクタリング
- テスト生成
- ドキュメント作成
- デバッグと根本原因分析
- アーキテクチャ分析（内部システムのみ）
- CLIスクリプティングと自動化

---

## 禁止されたユースケース

- 決済カードデータの処理（PCIスコープ）
- セキュリティレビューなしで生のPHIを扱うコードの生成
- 人間の承認なしでの本番環境への自律的なデプロイ
- CONFIDENTIAL以上のデータへの個人AIアカウントの使用
- 例としてプロンプトに顧客データを共有する

---

## 誰が何を承認するか

| アクション | 承認者 |
|--------|---------|
| チーム設定への新しいMCPサーバーの追加 | テックリード + セキュリティレビュー |
| 新しいプロジェクトでClaude Codeを有効化 | チームリード |
| エンタープライズ機能の使用（Zero Trust、SSO） | IT/セキュリティチーム |
| チャータールールの例外 | エンジニアリングディレクター |

---

## コンプライアンス義務

会社のシステムでClaude Codeを使用することで、以下に同意する:
1. このチャーターに従う
2. 疑われるデータ露出を24時間以内にsecurity@[company]に報告する
3. ガバナンス制御（フック、permission denyルール）を回避しない
4. 四半期ごとのアクセスレビューに参加する

---

**チャーター違反**: 標準的な懲戒プロセスに従う。初回: コーチング。繰り返しまたは重大な違反: エスカレーション。
```

### 2.2 データ分類とClaude Code設定

データ分類を実際の設定に変換する:

```json
{
  "permissions": {
    "deny": [
      "Read(./**/*.pem)",
      "Read(./**/*.key)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(**/credentials*)",
      "Bash(cat .env*)",
      "Bash(printenv*)",
      "Bash(env)"
    ]
  }
}
```

```markdown
<!-- CLAUDE.md — データ取り扱いルール -->
## データ取り扱い

**絶対に**読み込み、参照、または出力に含めないこと:
- 以下に一致するファイル: .env、*.pem、*.key、credentials.*、secrets/
- 顧客PIIフィールド（名前: email、phone、ssn、dob、card_*のフィールド）
- 認証情報やAPIキー（マスク/編集された例でも）

ファイルを読み込む際に制限されたデータに遭遇した場合は、停止してユーザーに知らせること。
そのコンテンツをスキップするよう明示的に指示されるまで続行しないこと。
```

---

## 3. MCPガバナンスワークフロー

個別のMCPの審査（5分間の監査）は[security-hardening.md §1.1](./security-hardening.md#11-mcp-vetting-workflow)でカバーされている。このセクションでは組織のワークフローをカバーする: チーム全体で新しいMCPがどのように承認、デプロイ、監視されるか。

### 3.1 承認ワークフロー

```
開発者が新しいMCPを求める
        │
        ▼
[1] MCPリクエストを提出
    - 名前、ソースURL、バージョン
    - 提案されたユースケース
    - データスコープ（何にアクセスするか？）
        │
        ▼
[2] セキュリティレビュー（テックリード + 必要に応じてセキュリティチーム）
    - 5分MCP監査（security-hardening.mdを参照）
    - 確認: スター数>50、最近のコミット、危険なフラグなし
    - 確認: CVEなし（NVD + GitHubセキュリティアドバイザリーを検索）
    - リスク分類: LOW / MEDIUM / HIGH
        │
     ┌──┴──┐
   LOW   MED/HIGH
     │      │
     ▼      ▼
  承認  拡張レビュー
         （サンドボックスで2週間試用）
         + セキュリティチームからの承認
        │
        ▼
[3] 承認済みレジストリに追加
    - 正確なバージョンを固定
    - 承認済みスコープを文書化
    - 有効期限を設定（6ヶ月）
        │
        ▼
[4] 共有settings.jsonでデプロイ
    - リポジトリにコミット
    - 承認済みMCPのローカルオーバーライドは不可
        │
        ▼
[5] 監視 + 定期再レビュー
    - 30日ごとにセキュリティアドバイザリーを確認
    - バージョンアップ時に再承認（パッチ: 自動、マイナー以上: 手動）
    - 四半期ごとのフルレジストリレビュー
```

### 3.2 MCPレジストリフォーマット

チームの共有設定リポジトリの`.claude/mcp-registry.yaml`に承認済みMCPレジストリを管理する:

```yaml
# .claude/mcp-registry.yaml
# [組織名]の承認済みMCPサーバー
# 最終更新: 2026-03-10
# レビュワー: [名前、役割]

metadata:
  review_cycle: quarterly
  next_review: "2026-06-10"
  owner: "platform-team@company.com"

approved:
  - name: context7
    version: "1.2.3"
    source: "https://github.com/context7/mcp-server"
    approved_by: "john.doe@company.com"
    approved_date: "2026-01-15"
    expires: "2026-07-15"
    data_scope: PUBLIC
    risk: LOW
    rationale: "読み取り専用のドキュメント検索。データ外部送信なし。"
    config:
      command: npx
      args: ["-y", "@context7/mcp-server@1.2.3"]

  - name: sequential-thinking
    version: "0.6.2"
    source: "https://github.com/modelcontextprotocol/servers"
    approved_by: "jane.smith@company.com"
    approved_date: "2026-01-15"
    expires: "2026-07-15"
    data_scope: INTERNAL
    risk: LOW
    rationale: "ローカル推論のみ。ネットワークアクセスなし。"
    config:
      command: npx
      args: ["-y", "@modelcontextprotocol/server-sequential-thinking@0.6.2"]

  - name: internal-db-readonly
    version: "2.1.0"
    source: "internal"
    approved_by: "security@company.com"
    approved_date: "2026-02-01"
    expires: "2026-05-01"  # リスクが高いため有効期間を短くする
    data_scope: CONFIDENTIAL
    risk: MEDIUM
    rationale: "読み取り専用レプリカへのアクセス。許可リストにPIIテーブルなし。"
    restrictions:
      - "読み取り専用の認証情報のみ"
      - "users、payments、auditテーブルへのアクセスなし"
    config:
      command: npx
      args: ["-y", "@company/db-mcp@2.1.0"]

pending_review:
  - name: github-mcp
    requested_by: "dev@company.com"
    requested_date: "2026-03-05"
    use_case: "PR自動化"
    status: under_review

denied:
  - name: browser-automation-mcp
    denied_date: "2026-02-10"
    reason: "スコープ制限なしのフルブラウザアクセス。リスクが高すぎる。"
```

### 3.3 フックを通じたレジストリの強制

ガバナンスフックを使用して、承認済みMCPのみが使用されていることを検証する。以下のスクリプトは`.claude/hooks/governance-check.sh`に配置できる最小限のインライン版だ。追加チェック（拒否リストの強制、危険な許可リストの検出）を含むより完全な実装については、[`examples/hooks/bash/governance-enforcement-hook.sh`](../../examples/hooks/bash/governance-enforcement-hook.sh)を参照。

```bash
#!/bin/bash
# .claude/hooks/governance-check.sh
# イベント: SessionStart
# アクティブなMCP設定を承認済みレジストリと照合して検証する

REGISTRY=".claude/mcp-registry.yaml"
SETTINGS="${HOME}/.claude.json"

if [[ ! -f "$REGISTRY" ]]; then
  exit 0  # レジストリなし = 強制なし（オプトインのガバナンス）
fi

# 未承認のMCPを確認（yqとjqが必要）
if command -v jq &>/dev/null && command -v yq &>/dev/null; then
  ACTIVE=$(jq -r '.mcpServers | keys[]' "$SETTINGS" 2>/dev/null)
  APPROVED=$(yq e '.approved[].name' "$REGISTRY" 2>/dev/null)

  for mcp in $ACTIVE; do
    if ! echo "$APPROVED" | grep -q "^${mcp}$"; then
      echo "ガバナンス警告: MCP '${mcp}'は承認済みレジストリにありません。"
      echo "リクエストを送信: https://your-internal-wiki/mcp-requests"
      echo "セッションは続行します — 48時間以内に対応してください。"
    fi
  done
fi

exit 0
```

**注**: このフックは警告するだけでブロックしない。セッション開始時のブロックは摩擦が大きすぎる。代わりに定期的なコンプライアンスチェックを使用する（§5.3参照）。

---

## 4. ガードレールティア

4つの一般的なシナリオに対応する事前設定済みのガードレールティア。関連するティアをプロジェクトの`.claude/settings.json`と`CLAUDE.md`にコピーする。

### ティア1: スターター

**適用対象**: 小規模チーム（<5人）、内部プロジェクト、本番データなし、低いコンプライアンス要件。

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./**/*.key)",
      "Read(./**/*.pem)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": ["~/.claude/hooks/dangerous-actions-blocker.sh"]
      }
    ]
  }
}
```

```markdown
<!-- CLAUDE.md追加 — スターターティア -->
## セキュリティの基本
- .envファイルや認証情報ファイルを読み込まない
- 破壊的なコマンド（DROP、DELETE、rm -rf）を実行する前に確認を取る
- コードベースの既存のパターンに従う
```

**投資**: セットアップ10分。基本をカバー。

### ティア2: 標準

**適用対象**: チーム5〜20人、本番に隣接するコード、一部の機密データ、ハードコンプライアンス要件なし。

{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./**/*.key)",
      "Read(./**/*.pem)",
      "Read(./secrets/**)",
      "Bash(cat .env*)",
      "Bash(printenv*)",
      "Edit(docker-compose.yml)",
      "Edit(.github/workflows/**)",
      "Edit(terraform/**)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          "~/.claude/hooks/dangerous-actions-blocker.sh"
        ]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [".claude/hooks/prompt-injection-detector.sh"]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": ["~/.claude/hooks/output-secrets-scanner.sh"]
      }
    ],
    "SessionStart": [
      ".claude/hooks/governance-check.sh"
    ]
  }
}

```markdown
<!-- CLAUDE.md追加 — 標準ティア -->
## 本番環境の安全性
- インフラファイル（docker-compose、terraform、CI/CD）はロックされています。
  変更する前に許可を求めてください。
- 新しい依存関係にはテックリードの承認が必要です。npm install <pkg>を実行しないでください。
- データベースの破壊的な操作（DROP、DELETE、TRUNCATE）にはバックアップの確認が必要です。

## コードレビューゲート
- 認証、決済、またはデータアクセスに触れるAI生成コードはすべて、
  PRの説明に「AI生成: レビュー必要」コメントでフラグを立てること。
```

**投資**: セットアップ30〜45分。ほとんどのチームをカバー。

### ティア3: 厳格

**適用対象**: チーム20人以上、本番クリティカルなシステム、顧客データ、非公式のコンプライアンス要件。

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./.env.local)",
      "Read(./**/*.key)",
      "Read(./**/*.pem)",
      "Read(./secrets/**)",
      "Read(**/credentials*)",
      "Bash(cat .env*)",
      "Bash(printenv*)",
      "Bash(env)",
      "Bash(npm install *)",
      "Bash(pnpm add *)",
      "Bash(pip install *)",
      "Edit(docker-compose.yml)",
      "Edit(docker-compose.prod.yml)",
      "Edit(.github/workflows/**)",
      "Edit(terraform/**)",
      "Edit(kubernetes/**)",
      "Edit(prisma/schema.prisma)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          "~/.claude/hooks/dangerous-actions-blocker.sh",
          "~/.claude/hooks/velocity-governor.sh"
        ]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [
          ".claude/hooks/prompt-injection-detector.sh",
          ".claude/hooks/unicode-injection-scanner.sh"
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": ["~/.claude/hooks/output-secrets-scanner.sh"]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [".claude/hooks/session-logger.sh"]
      }
    ],
    "SessionStart": [
      ".claude/hooks/governance-check.sh",
      "~/.claude/hooks/mcp-config-integrity.sh"
    ]
  }
}
```

```markdown
<!-- CLAUDE.md追加 — 厳格ティア -->
## セキュリティポスチャー: 厳格

あなたは厳格なセキュリティ環境で動作しています。これらのルールに例外なく従ってください。

### ロックされたファイル
これらのファイルはこの会話での明示的な許可なしに変更できません:
- docker-compose.yml、Dockerfile、.github/workflows/**、terraform/**、kubernetes/**
- prisma/schema.prisma（データベーススキーマ）
- /src/auth/、/src/payments/、/src/crypto/のすべてのファイル

### 依存関係プロトコル
依存関係を追加する前に:
1. 依存関係の名前と目的を述べる
2. 検討した2つ以上の代替案を列挙する
3. インストールコマンドを実行する前に明示的な承認を待つ

### データアクセスプロトコル
プロジェクトルート以外のファイルを読み込む前に:
1. ファイルパスとそれが必要な理由を述べる
2. パスが機密性の高いものに見える場合は承認を待つ

### AIの帰属
生成するすべてのコードブロックはPRで`// AI-generated`を先頭に付けること。
AIが生成したテストには`// AI-generated test`コメントを含めること。
```

**投資**: セットアップ1〜2時間。ほとんどの本番チームに適している。

### ティア4: 規制対応

**適用対象**: 金融、医療、規制産業。HIPAA、SOC2、PCI、ISO27001コンプライアンスが必要。

このティアは厳格ティアにコンプライアンス固有の制御を追加する。

```json
{
  "permissions": {
    "deny": [
      "Read(./.env*)",
      "Read(./**/*.key)",
      "Read(./**/*.pem)",
      "Read(./secrets/**)",
      "Read(**/credentials*)",
      "Read(**/patient*)",
      "Read(**/phi*)",
      "Read(**/pii*)",
      "Read(**/card*)",
      "Read(**/ssn*)",
      "Bash(cat .env*)",
      "Bash(printenv*)",
      "Bash(env)",
      "Bash(npm install *)",
      "Bash(pnpm add *)",
      "Bash(pip install *)",
      "Bash(curl *)",
      "Bash(wget *)",
      "Edit(docker-compose*.yml)",
      "Edit(.github/workflows/**)",
      "Edit(terraform/**)",
      "Edit(kubernetes/**)",
      "Edit(prisma/schema.prisma)",
      "Edit(**/auth/**)",
      "Edit(**/crypto/**)",
      "Edit(**/encryption/**)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          "~/.claude/hooks/dangerous-actions-blocker.sh",
          "~/.claude/hooks/velocity-governor.sh"
        ]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [
          ".claude/hooks/prompt-injection-detector.sh",
          ".claude/hooks/unicode-injection-scanner.sh"
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": ".*",
        "hooks": [
          "~/.claude/hooks/output-secrets-scanner.sh",
          ".claude/hooks/session-logger.sh"
        ]
      }
    ],
    "SessionStart": [
      ".claude/hooks/governance-check.sh",
      "~/.claude/hooks/mcp-config-integrity.sh"
    ]
  }
}
```

```markdown
<!-- CLAUDE.md追加 — 規制対応ティア -->
## コンプライアンスモード: [HIPAA | SOC2 | PCI] — 有効

あなたは規制コンプライアンス要件の下で動作しています。これらのルールは交渉不可能です。

### 禁止されたデータ
出力、提案、または例に絶対に含めないこと:
- PHI（患者の健康情報）、PII（顧客コンテキストでの名前、メール、電話）
- カード番号、CVV、銀行口座
- SSN、税務ID、政府ID
- 生の認証トークン、セッションクッキー、APIキー

### 必須レビューゲート
コードがコミットされる前に人間の承認が必要な変更:
- 認証または認可ロジックへの変更
- 暗号化または鍵管理への変更
- データベースマイグレーション
- 新しい外部API統合

### 監査証跡
規制対象データで動作するすべてのセッションには以下が必要:
- セッション開始時にユーザーIDをメモする（「このセッションは: [your-email]のためのものです」）
- セッション開始時にタスク説明をメモする（「タスク: [簡単な説明]」）
- 自然な区切り点でチェックポイントコメントを入れる

### AIの帰属（規制対応では必須）
すべてのAI生成コードには以下を含めること:
- `// AI-generated: [date] [model] [reviewer]`コメント
- PRの説明にはAI開示セクションを含めること
```

**規制環境のための追加ツール**: 承認ゲート付きの完全なセッション監査証跡にはEntire CLIを検討する。詳細と評価チェックリストについては[AIトレーサビリティ§5.1](../ops/ai-traceability.md#51-entire-cli)を参照。

---

## 5. 大規模なポリシーの強制

ポリシーを持つことと強制することは別物だ。このセクションでは、10〜100人の開発者チームでガバナンスを実際に機能させる方法をカバーする。

### 5.1 設定の配布

**核となる原則**: ガバナンス設定はリポジトリに存在し、個人のマシンではない。

```
your-org-config/                 ← 別の「プラットフォーム設定」リポジトリ
├── .claude/
│   ├── settings.json            ← 共有設定（ティアベース）
│   ├── mcp-registry.yaml        ← 承認済みMCP
│   ├── hooks/
│   │   ├── governance-check.sh  ← MCPレジストリチェック
│   │   ├── session-logger.sh    ← 監査証跡
│   │   └── velocity-governor.sh ← レート制限
│   └── agents/
│       └── security-reviewer.md ← コードレビュー用の共有エージェント
├── templates/
│   ├── CLAUDE.md.starter        ← ティアごとのCLAUDE.mdテンプレート
│   ├── CLAUDE.md.standard
│   ├── CLAUDE.md.strict
│   └── CLAUDE.md.regulated
└── scripts/
    └── setup-project.sh         ← 新しいプロジェクトを正しいティアでブートストラップ
```

**新しいプロジェクトのブートストラップ**:

```bash
#!/bin/bash
# scripts/setup-project.sh
# 使用方法: ./setup-project.sh [starter|standard|strict|regulated]

TIER=${1:-standard}
CONFIG_REPO="https://github.com/your-org/claude-code-config"

echo "Claude Codeガバナンスをセットアップ中: $TIERティア"

# .claudeディレクトリを作成
mkdir -p .claude/hooks

# ティア設定をコピー
curl -s "$CONFIG_REPO/raw/main/templates/.claude/settings.${TIER}.json" \
  -o .claude/settings.json

# CLAUDE.mdテンプレートをコピー
curl -s "$CONFIG_REPO/raw/main/templates/CLAUDE.md.${TIER}" \
  -o CLAUDE.md

# ガバナンスフックをコピー
curl -s "$CONFIG_REPO/raw/main/hooks/governance-check.sh" \
  -o .claude/hooks/governance-check.sh
chmod +x .claude/hooks/governance-check.sh

echo "完了。.claude/とCLAUDE.mdをリポジトリにコミットしてください。"
```

### 5.2 オンボーディングチェックリスト

Claude Codeを使用するチームに参加する新しい開発者はこのチェックリストを完了させること:

```markdown
## Claude Codeオンボーディングチェックリスト

### セットアップ（30分）
- [ ] Claude Codeをインストール: `npm i -g @anthropic-ai/claude-code`
- [ ] グローバルセーフティフックを設定: `./scripts/install-global-hooks.sh`
- [ ] プロジェクト設定が読み込まれることを確認: `claude`を起動して「このプロジェクトのティアは何ですか？」と聞く
- [ ] AI使用チャーターを読む（自社のドキュメントへのリンク）
- [ ] 承認済みMCPリストを確認: `.claude/mcp-registry.yaml`

### セキュリティの基本
- [ ] `~/.claude/settings.json`にプロジェクトの拒否ルールをバイパスする`permissions.allow`オーバーライドがないことを確認
- [ ] 本番データにアクセスする個人MCPサーバーが動作していないことを確認
- [ ] データ漏洩の報告方法を把握: security@[company]

### 最初の週
- [ ] Claude Codeで1つのタスクを完了する（バグ修正、小さな機能）
- [ ] 適切なAI帰属セクションを含む少なくとも1つのPRを提出する
- [ ] 設定改善のために摩擦点をテックリードに知らせる

### 四半期
- [ ] MCPレジストリレビューに参加する
- [ ] AI使用チャーターの更新をレビューする
- [ ] 個人設定のオーバーライドがないことを確認
```

### 5.3 コンプライアンスチェック

設定のドリフトを検出するための自動定期コンプライアンスチェック:

```bash
#!/bin/bash
# scripts/claude-governance-audit.sh
# CI/CDまたはcronで週次実行

PASS=0
FAIL=0
WARN=0

check() {
  local name="$1"
  local result="$2"
  local severity="${3:-FAIL}"

  if [[ "$result" == "OK" ]]; then
    echo "  合格: $name"
    ((PASS++))
  else
    echo "  $severity: $name — $result"
    [[ "$severity" == "FAIL" ]] && ((FAIL++)) || ((WARN++))
  fi
}

echo "=== Claude Codeガバナンス監査 ==="
echo ""

# 確認: settings.jsonが存在してコミットされている
echo "1. リポジトリ設定"
[[ -f ".claude/settings.json" ]] \
  && check "settings.jsonが存在" "OK" \
  || check "settings.jsonが存在" "見つからない — チーム設定が強制されていない" "FAIL"

git ls-files --error-unmatch .claude/settings.json &>/dev/null \
  && check "settings.jsonがコミット済み" "OK" \
  || check "settings.jsonがコミット済み" "gitで追跡されていない — チームに適用されない" "WARN"

# 確認: 機密情報の拒否ルール
echo ""
echo "2. 機密情報の保護"
if [[ -f ".claude/settings.json" ]]; then
  jq -e '.permissions.deny[]? | select(test("env|pem|key"))' \
    .claude/settings.json &>/dev/null \
    && check ".env保護ルール" "OK" \
    || check ".env保護ルール" ".envまたはキーファイルの拒否ルールなし" "FAIL"
fi

# 確認: フックがインストールされて実行可能
echo ""
echo "3. フックスタック"
for hook in ".claude/hooks/governance-check.sh"; do
  if [[ -f "$hook" ]]; then
    [[ -x "$hook" ]] \
      && check "$hookが実行可能" "OK" \
      || check "$hookが実行可能" "実行不可能 — chmod +x $hookを実行" "FAIL"
  else
    check "$hookが存在" "見つからない" "WARN"
  fi
done

# 確認: MCPレジストリが存在
echo ""
echo "4. MCPガバナンス"
[[ -f ".claude/mcp-registry.yaml" ]] \
  && check "MCPレジストリが存在" "OK" \
  || check "MCPレジストリが存在" "レジストリなし — MCP使用がガバナンスされていない" "WARN"

# 確認: CLAUDE.mdが存在してコミットされている
echo ""
echo "5. ドキュメント"
[[ -f "CLAUDE.md" ]] || [[ -f ".claude/CLAUDE.md" ]] \
  && check "CLAUDE.mdが存在" "OK" \
  || check "CLAUDE.mdが存在" "見つからない — AIのプロジェクトコンテキストなし" "WARN"

echo ""
echo "=== サマリー ==="
echo "  合格:   $PASS"
echo "  失敗:   $FAIL（修正必須）"
echo "  警告: $WARN（修正すべき）"
echo ""

[[ $FAIL -gt 0 ]] && exit 1 || exit 0
```

### 5.4 ロールベースのガードレール

開発者ごとにリスクプロファイルが異なる。それに応じてClaude Codeの設定を調整する。

**アプローチ: CLAUDE.mdで経験/ロールによるティア分け**

```markdown
<!-- CLAUDE.md — ロール対応ガイドライン -->
## 開発者コンテキスト

これは[JUNIOR|SENIOR|LEAD]開発者のプロジェクトコンテキストです。

### JUNIORの場合（会社在籍1年未満）
- 実装する前に常にアーキテクチャの決定を確認する
- シニアとペアリングせずにデータベーススキーマ、マイグレーション、認証コードを変更しない
- すべてのPRはAI生成セクションを明示的に確認する人間のレビュワーが必要
- 50行以上のものを実装する前に/planモードを使用する

### SENIORの場合（会社在籍1年以上）
- 標準レビューを適用する
- ほとんどのファイルを変更できるが、認証/決済/暗号はリードのレビューが必要
- PRでのAI帰属が必要

### LEAD/PRINCIPALの場合
- フルアクセス、判断ベースの制限
- チームプロジェクトのガードレールティアを設定する責任がある
- 四半期ごとのMCPレジストリレビューを実施しなければならない
```

**アプローチ: 環境ごとに異なるsettings.json**

CI/CDでは、パイプライン開始時にアクティブな`settings.json`パスを確認して、正しいティアを強制する。Claude Codeはプロジェクトルートから`.claude/settings.json`を読み込む — 厳格ティアの設定をそこにコミットすれば、開発者のローカル設定に関係なく、CIは常にそれを取得する。

```bash
# CIパイプラインのセットアップステップで、正しいティアがコミットされていることを確認
if ! grep -q '"Bash(curl \*)"' .claude/settings.json; then
  echo "エラー: CIには規制対応ティアのsettings.jsonが必要（curlが拒否されていること）"
  exit 1
fi
```

### 5.5 CI/CDゲート

非準拠のAI使用が本番環境に到達するのをブロックする:

```yaml
# .github/workflows/ai-governance.yml
name: AIガバナンスチェック

on: [pull_request]

jobs:
  governance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: ガバナンス設定が存在することを確認
        run: |
          if [[ ! -f ".claude/settings.json" ]]; then
            echo "::error::'.claude/settings.json'が見つかりません — ガバナンス設定が必要"
            exit 1
          fi

      - name: 認証情報アクセス権限がないことを確認
        run: |
          if jq -e '.permissions.allow[]? | select(test("env|pem|key|secret"))' \
            .claude/settings.json 2>/dev/null; then
            echo "::error::危険なpermissions.allowを検出 — 認証情報が公開される可能性があります"
            exit 1
          fi

      - name: ガバナンス監査を実行
        run: |
          chmod +x scripts/claude-governance-audit.sh
          ./scripts/claude-governance-audit.sh

      - name: PR説明でのAI帰属を確認
        if: ${{ env.REQUIRE_AI_ATTRIBUTION == 'true' }}
        uses: actions/github-script@v7
        with:
          script: |
            const body = context.payload.pull_request.body || '';
            const hasAttribution = body.includes('AI') ||
                                   body.includes('Claude') ||
                                   body.includes('AI-generated');
            if (!hasAttribution) {
              core.warning('AI帰属セクションが見つかりません。AIの使用を開示してください。');
            }
```

---

## 6. 監査、コンプライアンス、ガバナンス構造

### 6.1 SOC2とISO27001の監査人が実際に尋ねること

監査人がAIコーディングツールの使用をレビューするとき、通常これらの制御の証拠を探す:

| 監査人の質問 | 見たいもの | Claude Codeの実装 |
|-----------------|----------------------|---------------------------|
| 「AIツール使用のポリシーはありますか？」 | 書面のチャーター、署名/承認済み | `docs/ai-usage-charter.md` + オンボーディングチェックリスト |
| 「AIベンダーに送信されるデータをどのように制御しますか？」 | データ分類 + 技術的制御 | 機密ファイルの`permissions.deny` |
| 「サードパーティのAIコンポーネントをどのように審査しますか？」 | 承認ワークフロー + レジストリ | MCPレジストリ + 承認プロセス |
| 「AIアクションの監査証跡はありますか？」 | ツール呼び出し、アクセスされたファイルのログ | セッションJSONLログ + `compliance-audit-logger.sh` |
| 「AIが生成したコードをどのようにレビューしますか？」 | AI開示を含むコードレビュープロセス | PRテンプレート + 帰属ポリシー |
| 「インシデントが発生した場合はどうしますか？」 | インシデント対応手順 | 既存のIRプロセス + AI固有の追加 |

**SOC2の場合**: 関連するトラストサービスの基準はCC6.1（論理アクセス制御）、CC6.3（アクセスの削除）、CC7.1（監視）、CC9.2（ベンダーリスク）だ。Claude Codeのガバナンスはこれらにマッピングする必要がある。

**ISO27001の場合**: 関連する附属書Aの制御には、A.8.3（情報アクセス制限）、A.8.24（暗号の使用）、A.8.25（セキュアな開発ライフサイクル）、A.5.23（クラウドサービスの使用に関する情報セキュリティ）が含まれる。

### 6.2 監査証跡のセットアップ

Claude Codeのセッションはすでに`~/.claude/projects/<project>/*.jsonl`にログが記録されている。課題はそれを:
1. 事後にアクセス可能にすること（開発者が退職しても失われない）
2. 改ざん防止にすること（事後に編集できない）
3. 監査目的でクエリ可能にすること

**最小限の監査証跡（追加ツールなし）**:

```bash
#!/bin/bash
# .claude/hooks/compliance-audit-logger.sh
# イベント: PostToolUse（すべてのツール）
# 構造化された監査エントリーを共有ログに追記する

LOG_DIR="${COMPLIANCE_LOG_DIR:-/var/log/claude-audit}"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).jsonl"

mkdir -p "$LOG_DIR"

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool.name // "unknown"')
USER=$(whoami)
PROJECT=$(basename "$PWD")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "{\"timestamp\":\"$TIMESTAMP\",\"user\":\"$USER\",\"project\":\"$PROJECT\",\"tool\":\"$TOOL\"}" \
  >> "$LOG_FILE"
```

**不変ストレージへのログ送信**（規制環境に推奨）:

```bash
# 毎日: セッションログを不変バケットに同期
aws s3 sync ~/.claude/projects/ \
  s3://your-audit-bucket/claude-sessions/$(whoami)/ \
  --storage-class GLACIER_INSTANT_RETRIEVAL \
  --exclude "*.tmp"
```

**承認ゲート付きの完全なコンプライアンス監査証跡**については、Entire CLIを検討する — 完全なセッションコンテキスト（プロンプト、推論、ツール呼び出し、ファイル差分）をgitコミットへの暗号リンクでキャプチャする。セットアップと評価基準については[AIトレーサビリティ§5.1](../ops/ai-traceability.md#51-entire-cli)を参照。これは複数のオプションの中の1つのツールだ。特定のコンプライアンス要件に対して評価すること。

### 6.3 AIガバナンス委員会（コンパクトリファレンス）

大規模にAIリスクを管理する組織では、軽量なAIガバナンス委員会が監査人が期待する説明責任の構造を提供する。これはボトルネックではなく調整メカニズムだ。

**最小限の構造**（10〜100人の開発者に対応）:

| 役割 | 担当者 | 責任 |
|------|--------|----------------|
| **ガバナンスリード** | エンジニアリングマネージャーまたはリード | ポリシー更新、四半期レビュー、エスカレーション |
| **セキュリティ担当** | SecEngまたはDevSecOps | MCPリスクレビュー、インシデント対応 |
| **開発担当** | シニア開発者のローテーション（3ヶ月任期） | 開発者フィードバック、ユーザビリティバランス |
| **コンプライアンス担当** | 法務/コンプライアンス（規制対象のみ） | チャーター、規制のマッピング |

**会議サイクル**: 四半期ごと（30分）。常任議題:
1. MCPレジストリレビュー — 追加、削除、またはフラグが必要なものはあるか？
2. インシデントレビュー — 前回の会議以降にAI関連のセキュリティイベントはあったか？
3. ポリシー更新 — チャーターへの変更が必要か？
4. メトリクス — ガバナンス監査結果、コンプライアンスチェックステータス

詳細なAIガバナンス委員会の構造、RACIマトリックス、コンプライアンスマッピングについては、ホワイトペーパー#11: エンタープライズAIガバナンス（FR/EN）を参照。

### 6.4 コンプライアンスのための監視

ガバナンスの可観測性レイヤーについては[observability.md](../ops/observability.md)でカバーされている。コンプライアンスについては、以下の監視クエリが最も関連している:

```bash
# 過去30日間でClaudeがアクセスしたファイルは？
# macOS: date -v-30d; Linux: date -d '30 days ago'
if [[ "$OSTYPE" == "darwin"* ]]; then
  SINCE=$(date -v-30d +%Y-%m-%d)
else
  SINCE=$(date -d '30 days ago' +%Y-%m-%d)
fi

find ~/.claude/projects/ -name "*.jsonl" -newer "$SINCE" | \
  xargs jq -r 'select(.type == "assistant") |
    .message.content[]? |
    select(.type == "tool_use" and .name == "Read") |
    .input.file_path' 2>/dev/null | sort -u

# 機密パターンへのアクセスはあったか？
# （上記の後で実行し、grepにパイプ）
grep -E '\.(env|pem|key)$|secrets/|credentials'

# 今週Claudeが実行したBashコマンド
if [[ "$OSTYPE" == "darwin"* ]]; then
  SINCE_WEEK=$(date -v-7d +%Y-%m-%d)
else
  SINCE_WEEK=$(date -d '7 days ago' +%Y-%m-%d)
fi

find ~/.claude/projects/ -name "*.jsonl" -newer "$SINCE_WEEK" | \
  xargs jq -r 'select(.type == "assistant") |
    .message.content[]? |
    select(.type == "tool_use" and .name == "Bash") |
    .input.command' 2>/dev/null | sort
```

---

## クイックリファレンス

### ティア選択

| 状況 | ティア | セットアップ時間 |
|----------------|------|------------|
| サイドプロジェクト、個人使用 | スターター | 10分 |
| 小規模チーム、内部プロジェクト | スターター | 10分 |
| チーム5〜20人、本番コード | 標準 | 45分 |
| チーム20人以上、顧客データ | 厳格 | 2時間 |
| 規制産業（HIPAA/SOC2/PCI） | 規制対応 | 半日 |

### ガバナンス成熟度レベル

| 成熟度 | 持っているもの | 不足しているもの |
|----------|---------------|----------------|
| **アドホック** | 各開発者が独自のセットアップを設定 | 一貫性、説明責任 |
| **基本** | 共有CLAUDE.md + settings.json | MCPガバナンス、監査証跡 |
| **管理** | + MCPレジストリ + フック | コンプライアンスレポート |
| **準拠** | + 監査ログ + チャーター + レビューサイクル | 重要なものはなし |
| **監査済み** | + 外部検証 + トレーサビリティ | — |

### よくある間違い

| 間違い | 修正 |
|---------|-----|
| `~/.claude`（個人）のみのガバナンス | リポジトリの`.claude/`に移動 |
| `permissions.allow`がチームの`deny`をオーバーライド | 個人設定を四半期ごとにレビュー |
| MCPレジストリなし → 各開発者が異なるMCPを追加 | 3エントリーだけでもレジストリを開始する |
| CLAUDE.mdが長すぎる → Claudeがルールを無視する | 8KB以下に保ち、重要なルールを優先する |
| 監査人がAIログを求める → 何も保存されていない | セッションログのS3同期をセットアップする |

---

## 関連情報

- [セキュリティ強化](./security-hardening.md) — 個人開発者のセキュリティ: MCP CVE、インジェクション防御、5分間の監査
- [本番環境の安全ルール](./production-safety.md) — 本番チームのための6つの交渉不可能なルール（ポート、DBの安全性、インフラのロック）
- [データプライバシーガイド](./data-privacy.md) — Claude CodeがAnthropicに送信するデータ、保持ポリシー
- [AIトレーサビリティ](../ops/ai-traceability.md) — 帰属ポリシー、Entire CLI、git-ai、コンプライアンスフレームワーク
- [可観測性](../ops/observability.md) — セッション監視、コスト追跡、アクティビティ監査クエリ
- [採用アプローチ](../roles/adoption-approaches.md) — チーム展開パターン、CLAUDE.md戦略
- [MCPレジストリテンプレート](../../examples/scripts/mcp-registry-template.yaml) — すぐに使えるレジストリフォーマット
- [ガバナンスフック](../../examples/hooks/bash/governance-enforcement-hook.sh) — ポリシーに対して設定を検証するフック
- [AI使用チャーターテンプレート](../../examples/scripts/ai-usage-charter-template.md) — 適応可能なチャーターテンプレート

---

## 参考文献

- [Liminal AI エンタープライズガバナンスガイド](https://www.liminal.ai/blog/enterprise-ai-governance-guide) — 実践的な実装
- [Databricks AIガバナンスフレームワーク](https://www.databricks.com/blog/practical-ai-governance-framework-enterprises) — エンタープライズスケールのフレームワーク
- [Augmentcode AIコードガバナンス](https://www.augmentcode.com/guides/ai-code-governance-framework-for-enterprise-dev-teams) — 開発チーム向け
- [Partnership on AI — 2026年の6つのガバナンス優先事項](https://partnershiponai.org/resource/six-governance-priorities/) — 評価フレームワーク、説明責任
- [EU AI Act](https://www.europarl.europa.eu/doceo/document/TA-9-2024-0138_EN.html) — 高リスクAIシステムのキルスイッチ要件
- [NIST AI RMF](https://airc.nist.gov/RMF/Overview) — リスク管理フレームワーク
- [SOC2トラストサービス基準](https://www.aicpa.org/resources/article/soc-2-trust-services-criteria) — CC6.1、CC7.1、CC9.2

---

*バージョン 1.0.0 | 2026年3月 | [Claude Code アルティメットガイド](../README.md)の一部*
