---
layout: default
title: "本番環境の安全性"
parent: セキュリティ
grand_parent: ガイド
nav_order: 2
---


# 本番環境の安全ルール

> **対象**: 本番環境にClaude Codeをデプロイするチーム。
> **個人学習者の場合**: 代わりに[はじめに](./ultimate-guide.md#1-getting-started)を参照。


## TL;DR（30秒）

**本番チームのための6つの交渉不可能なルール**:

1. ✅ **ポートの安定性**: バックエンド/フロントエンドのポートを絶対に変更しない
2. ✅ **データベースの安全性**: 破壊的な操作の前は必ずバックアップを取る
3. ✅ **機能の完全性**: 半端に実装された機能は絶対にリリースしない
4. ✅ **インフラのロック**: Docker/環境変更には許可が必要
5. ✅ **依存関係の安全性**: 承認なしに新しい依存関係を追加しない
6. ✅ **パターンの遵守**: 既存のコードベースの規約に従う


## これらのルールを使用するタイミング

| プロジェクトタイプ | これらのルールを使用するか | 理由 |
|--------------|------------------|-----|
| 学習 / チュートリアル | ❌ 不要 | 探索には制限が多すぎる |
| 個人プロトタイプ | ❌ 不要 | オーバーヘッドが見合わない |
| 小規模チーム（2〜3人）、ステージング環境 | ⚠️ 部分的 | ルール1、3、6のみ |
| 本番アプリ、複数開発者チーム | ✅ 必要 | 全6ルール |
| 規制産業（HIPAA、SOC2） | ✅ 必要 + コンプライアンスルールを追加 | 重要な安全性 |


## ルール1: ポートの安定性

### 問題

ポートを変更すると以下が壊れる:
- ローカル開発環境
- Docker Compose設定
- デプロイ済みサービス設定
- チームメンバーのセットアップ

**実際のインシデント**: リファクタリング中にバックエンドポートが3000から8080に変更された。すべての開発者がローカル環境の再設定に1日費やした。nginxプロキシが依然として3000を指していたため、ステージングのデプロイがサイレントに失敗した。

### ルール

**チームの明示的な許可なしにバックエンド/フロントエンドのポートを絶対に変更しない。**

### 実装

**オプションA: `settings.json`での権限拒否**

```json
{
  "permissions": {
    "deny": [
      "Edit(docker-compose.yml:*ports*)",
      "Edit(package.json:*PORT*)",
      "Edit(.env.example:*PORT*)",
      "Edit(vite.config.ts:*port*)"
    ]
  }
}
```

**オプションB: Pre-commitフック**

```bash
# .claude/hooks/PreToolUse.sh
if [[ "$TOOL" == "Edit" ]]; then
    FILE=$(echo "$INPUT" | jq -r '.tool.input.file_path')
    CONTENT=$(echo "$INPUT" | jq -r '.tool.input.new_string')

    if [[ "$FILE" =~ (docker-compose|vite.config|package.json) ]] && \
       [[ "$CONTENT" =~ (port|PORT):[[:space:]]*[0-9] ]]; then
        echo "⚠️ ブロック: $FILEでポートの変更を検出"
        echo "ポートはチームの調整のために安定を保つ必要があります。最初に許可を求めてください。"
        exit 2
    fi
fi
```

**オプションC: CLAUDE.mdの制約**

```markdown
## ポート設定

**重要**: ポートはチームの調整のためにロックされています。

現在のポート:
- フロントエンド (Vite): 5173
- バックエンド (Express): 3000
- データベース: 5432

ポートを変更するには:
1. `/docs/rfcs/`にRFCドキュメントを作成する
2. チームの承認を得る（3人以上のレビュワー）
3. すべての環境を同時に更新する
4. 48時間前にチームに通知する
```

### エッジケース

| シナリオ | 動作 |
|----------|----------|
| 新しいサービスを追加 | OK（既存のサービスを壊さない） |
| テスト環境のポートを変更 | OK（開発/本番から分離されている） |
| マシンのポート競合 | ユーザーにローカルで解決するよう依頼（.env.local） |


## ルール2: データベースの安全性

### 問題

本番環境での誤ったデータ削除 = データ損失。

**実際のインシデント**:
- `DELETE FROM users WHERE id = 123` → `WHERE`を忘れた → 全ユーザーが削除された
- クリーンアップ中の`DROP TABLE sessions` → 本番テーブルが削除された
- マイグレーションのロールバック → バックアップがなかったためデータ損失

### ルール

**破壊的な操作の前は必ずバックアップを取る。**

破壊的な操作:
- `DELETE FROM`（`LIMIT 1`なし）
- `DROP TABLE`
- `TRUNCATE`
- `ALTER TABLE ... DROP COLUMN`
- ロールバックできないデータベースマイグレーション

### 実装

**オプションA: バックアップ強制のPre-toolフック**

```bash
# .claude/hooks/PreToolUse.sh
#!/bin/bash
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool.name')

if [[ "$TOOL" == "Bash" ]]; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool.input.command')

    # 破壊的なデータベース操作を検出
    if [[ "$COMMAND" =~ (DROP TABLE|DELETE FROM|TRUNCATE|ALTER.*DROP) ]]; then
        echo "🚨 ブロック: 破壊的なデータベース操作を検出"
        echo ""
        echo "必要な手順:"
        echo "1. バックアップを作成: pg_dump -U user dbname > backup_\$(date +%Y%m%d_%H%M%S).sql"
        echo "2. バックアップサイズが妥当であることを確認"
        echo "3. バックアップの確認後に再実行"
        exit 2
    fi
fi

exit 0
```

**オプションB: マイグレーション安全ラッパー**

```bash
# scripts/safe-migrate.sh
#!/bin/bash
set -e

echo "🔍 マイグレーション前チェック..."

# 1. 環境を確認
if [[ "$NODE_ENV" == "production" ]]; then
    echo "❌ ブロック: 本番環境にはマイグレーションサービスを使用してください"
    exit 1
fi

# 2. バックアップを作成
BACKUP_FILE="backups/pre-migration-$(date +%Y%m%d_%H%M%S).sql"
mkdir -p backups
pg_dump $DATABASE_URL > "$BACKUP_FILE"
echo "✅ バックアップ作成完了: $BACKUP_FILE"

# 3. マイグレーションを実行
echo "🚀 マイグレーションを実行中..."
npm run prisma:migrate:dev

# 4. 検証
echo "🔍 データベース状態を検証中..."
npm run prisma:validate

echo "✅ マイグレーション完了。バックアップ: $BACKUP_FILE"
```

**オプションC: CLAUDE.mdプロトコル**

```markdown
## データベース操作

### 破壊的な操作のプロトコル

**バックアップなしで絶対に実行しないコマンド**:
- DELETE、DROP、TRUNCATE、ALTER...DROP

**必要な手順**:
1. #dev-ops Slackチャンネルでアナウンスする
2. バックアップを作成: `./scripts/backup-db.sh`
3. バックアップを確認: `ls -lh backups/`（0バイト以上であること）
4. まずステージングで実行する
5. 24時間問題が出ないか待つ
6. オンコールエンジニアと共に本番環境で実行する

**緊急ロールバック**:
```bash
psql $DATABASE_URL < backups/[latest].sql
```
```

### MCPデータベースの安全性

MCPデータベースサーバー（Postgres、MySQLなど）を使用する場合:

```json
{
  "mcpServers": {
    "database": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-postgres"],
      "env": {
        "POSTGRES_URL": "postgres://readonly:***@dev-db.example.com:5432/appdb"
      },
      "comment": "安全のために読み取り専用ユーザー"
    }
  }
}
```

**重要**: MCPには読み取り専用のデータベースユーザーを使用すること。[データプライバシーガイド](./data-privacy.md#risk-2-mcp-database-access)を参照。


## ルール3: 機能の完全性

### 問題

Claude Codeはコンテキストが少なくなると機能を「おざなり」にすることがある:
- バグを修正する代わりに既存の機能を削除する
- コアとなる機能に`TODO`コメントを追加する
- エラー状態を未処理のままにする
- モック実装を作成する

**実際のインシデント**:
- 決済バリデーションがバリデーションを完全に削除することで「修正」された
- エラーハンドリングが`throw new Error("Not implemented")`で「追加」された
- 機能が`// TODO: Add actual logic here`で「完了」された

### ルール

**半端に実装された機能は絶対にリリースしない。始めたら動作する状態まで完成させること。**

### 実装

**オプションA: CLAUDE.mdの制約**

```markdown
## 機能実装基準

### 交渉不可能なルール

1. **コアとなる機能にTODOを入れない**
   - TODOは将来の拡張機能のみ許可
   - コアとなる機能は完成して動作していること

2. **モック実装を作成しない**
   - `throw new Error("Not implemented")`は禁止
   - 本番コードパスに偽のデータジェネレーターを入れない

3. **完全なエラーハンドリング**
   - すべての非同期呼び出しにtry/catchがあること
   - すべてのユーザー入力が検証されていること
   - すべてのAPI呼び出しにタイムアウトとリトライロジックがあること

4. **ダウングレード = 機能を完全に削除する**
   - 正しく修正できない場合は機能を削除する
   - コミットメッセージに理由を記録する
   - 適切な実装のためにissueを作成する

### 検証

変更を受け入れる前に確認する:
- [ ] 変更されたファイルに`TODO`がない（将来の拡張機能を除く）
- [ ] `throw new Error("Not implemented")`がない
- [ ] 説明なしにコメントアウトされたコードがない
- [ ] 新しいすべての関数にエラーハンドリングがある
```

**オプションB: Pre-commit gitフック**

```bash
# .git/hooks/pre-commit
#!/bin/bash

# ステージングされたファイルに「おざなり」なパターンがないか確認
STAGED=$(git diff --cached --name-only --diff-filter=ACM)

for FILE in $STAGED; do
    if [[ "$FILE" =~ \.(ts|tsx|js|jsx|py)$ ]]; then
        # コアロジックのTODOを確認（テスト以外）
        if ! [[ "$FILE" =~ test|spec ]]; then
            if git diff --cached "$FILE" | grep -E "^\+.*TODO.*implement|^\+.*Not implemented"; then
                echo "❌ コミットブロック: $FILEにTODO/Not implementedがあります"
                echo "   機能を完成させるか、完全に削除してください。"
                exit 1
            fi
        fi

        # モックのプレースホルダーを確認
        if git diff --cached "$FILE" | grep -E "^\+.*(MOCK_DATA|fakeData|placeholder)"; then
            echo "⚠️ 警告: $FILEでモックデータを検出"
            echo "   これがステージング/開発専用であることを確認してください。"
        fi
    fi
done

exit 0
```

**オプションC: 出力評価コマンド**

```bash
# コミットする前に
/validate-changes

# これはoutput-evaluatorエージェントを実行する（examples/agents/output-evaluator.md参照）
# 変更を以下でスコアリングする:
# - 正確性 (10/10)
# - 完全性 (10/10)  ← おざなりを検出
# - 安全性 (10/10)
```


## ルール4: インフラのロック

### 問題

Claudeは本番環境への影響を理解せずにインフラ設定を変更する可能性がある:
- Docker Composeのボリュームを変更する → データ損失
- `.env.example`を変更する → オンボーディングが壊れる
- Terraformを更新する → 意図しないリソース変更
- Kubernetesマニフェストを調整する → ダウンタイム

### ルール

**インフラの変更にはチームの明示的な許可が必要。**

保護すべきファイル:
- `docker-compose.yml`、`Dockerfile`
- `.env.example`（テンプレート、個人の.env.localではない）
- `kubernetes/`、`k8s/`、`terraform/`、`helm/`
- CI/CD設定（`.github/workflows/`、`.gitlab-ci.yml`）
- データベーススキーマ（マイグレーションレビューが必要）

### 実装

**オプションA: 権限拒否**

```json
{
  "permissions": {
    "deny": [
      "Edit(docker-compose.yml)",
      "Edit(Dockerfile)",
      "Edit(.env.example)",
      "Edit(terraform/**)",
      "Edit(kubernetes/**)",
      "Edit(.github/workflows/**)",
      "Edit(prisma/schema.prisma)"
    ]
  }
}
```

**オプションB: CLAUDE.mdルール**

```markdown
## インフラの変更

明示的な許可なしにこれらを変更することは**禁止**:

- `docker-compose.yml`、`Dockerfile`
- `.env.example`（新しい開発者向けのテンプレート）
- `terraform/`、`kubernetes/`（インフラストラクチャーアズコード）
- `.github/workflows/`（CI/CDパイプライン）
- `prisma/schema.prisma`（データベーススキーマ）

**インフラの変更が必要な場合**:
1. ユーザーに確認: 「これにはインフラの変更が必要です。RFCを作成すべきでしょうか？」
2. `docs/rfcs/YYYYMMDD-<title>.md`にRFCドキュメントを作成する
3. RFCが承認されるまでファイルを変更しない
```

**注**: 個人の`.env.local`ファイルは変更しても問題ない（gitignoreされている）。


## ルール5: 依存関係の安全性

### 問題

チームの承認なしに依存関係を追加すると:
- バンドルサイズが増加する（パフォーマンス）
- セキュリティ脆弱性が導入される
- ライセンスコンプライアンスの問題が発生する
- メンテナンスの負担が増える

**実際のインシデント**:
- プロジェクトにすでに`date-fns`（小さい）があるのに`moment.js`（200KB）を追加した
- プロジェクトが`ramda`を使用しているのに`lodash`をインストールした
- GPLライブラリを追加した → プロプライエタリなコードベースのライセンス違反

### ルール

**明示的な承認なしに新しい依存関係を追加しない。**

### 実装

**オプションA: パッケージマネージャーの権限拒否**

```json
{
  "permissions": {
    "deny": [
      "Bash(npm install *)",
      "Bash(npm i *)",
      "Bash(pnpm add *)",
      "Bash(yarn add *)",
      "Bash(pip install *)",
      "Bash(poetry add *)"
    ],
    "allow": [
      "Bash(npm install)",
      "Bash(pnpm install)",
      "Bash(pip install -r requirements.txt)"
    ]
  }
}
```

**オプションB: CLAUDE.mdプロトコル**

```markdown
## 依存関係の管理

### 固定スタックルール

**新しい依存関係を追加することは禁止**（`npm install <package>`）。

**新しい依存関係が必要な場合**:
1. 既存の依存関係で解決できるか確認:
   - 日付操作? 既存の`date-fns`を使用
   - HTTPリクエスト? 既存の`axios`を使用
   - 状態管理? 既存の`zustand`を使用
2. 本当に必要な場合は確認:
   - 「[理由]のために[パッケージ]が必要です。既存の代替: [X, Y]。追加すべきですか？」
3. 明示的な承認を待つ
4. ユーザーが手動で実行: `npm install <package>`

**確認なしで許可されるもの**:
- `npm install`（既存のpackage.jsonの依存関係をインストール）
- 承認後のテスト用開発依存関係（`-D`フラグ）
```

**オプションC: Pre-toolフック**

```bash
# .claude/hooks/PreToolUse.sh
if [[ "$TOOL" == "Bash" ]]; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool.input.command')

    # 依存関係のインストールをブロック
    if [[ "$COMMAND" =~ (npm|pnpm|yarn)[[:space:]]+(install|add|i)[[:space:]]+[a-zA-Z] ]]; then
        echo "🚨 ブロック: 新しい依存関係のインストール"
        echo ""
        echo "依存関係はチームリードの承認が必要です。"
        echo "以下を説明するRFCでPRを作成してください:"
        echo "1. この依存関係が必要な理由"
        echo "2. 検討した代替案"
        echo "3. バンドルサイズへの影響"
        echo "4. ライセンスの互換性"
        exit 2
    fi

    # 許可: npm install（引数なし）、npm install -g、pnpm install
    if [[ "$COMMAND" =~ ^(npm|pnpm|yarn)[[:space:]]+install$ ]]; then
        exit 0
    fi
fi
```


## ルール6: パターンの遵守

### 問題

Claudeがコードベースと一致しない新しいパターンを導入する:
- プロジェクトが関数型Reactなのに`class`コンポーネントを使用する
- プロジェクトが`ramda`を使用しているのに`lodash`をインポートする
- プロジェクトがGraphQLなのにRESTエンドポイントを作成する
- プロジェクトが`axios`で標準化しているのに`fetch`を使用する

### ルール

**既存のコードベースの規約に従うこと。実装する前に確認すること。**

### 実装

**オプションA: CLAUDE.mdの規約**

```markdown
## コーディング規約

### 技術スタック（逸脱禁止）

**フロントエンド**:
- React 18の**関数コンポーネント + フック**（クラスコンポーネント禁止）
- 状態: Zustand（Redux、Contextは禁止）
- HTTP: axios（fetchは禁止）
- スタイリング: Tailwind CSS（styled-components、emotionは禁止）
- フォーム: React Hook Form + Zod

**バックエンド**:
- Node.js + Express
- データベース: Prisma ORM（生SQL、TypeORMは禁止）
- 認証: joseライブラリ経由のJWT
- バリデーション: Zodスキーマ

**テスト**:
- ユニット: Vitest（Jestは禁止）
- E2E: Playwright（Cypressは禁止）

### インポートパターン

**常に使用するもの**:
```typescript
import { useState } from 'react'           // ✅ 名前付きインポート
import axios from 'axios'                  // ✅ デフォルトインポート
```

**絶対に使用しないもの**:
```typescript
import React from 'react'                  // ❌ 廃止されたパターン
import * as axios from 'axios'             // ❌ 名前空間インポート
```

### ファイル構造

```
src/
  features/          ← 機能でグループ化（タイプではなく）
    auth/
      components/
      hooks/
      api/
  shared/            ← 共有ユーティリティ
    components/
    hooks/
```

### デザインシステム

UIの変更は既存のデザインシステムを必ず使用すること:
- `src/shared/components/`に既存のコンポーネントがないか確認
- `tailwind.config.js`のTailwindユーティリティクラスを使用
- `colors.ts`パレットの色のみ使用
- `typography.config.js`のタイポグラフィを使用

**新しいコンポーネントを作成する前に**:
1. 検索: `rg "Button" src/shared/components/`
2. 存在する場合は使用する
3. 存在しない場合は確認: 「新しいButtonコンポーネントを作成するか、既存のプリミティブを使用するか？」
```

**オプションB: 実装前の分析**

```markdown
## 実装する前に

**必ず**これらのチェックを実行すること:

1. **パターンチェック**:
```bash
# コードベースはXをどのように処理するか?
rg "import.*useState" src/  # Reactパターンを確認
rg "axios\." src/           # HTTPパターンを確認
rg "prisma\." src/          # DBパターンを確認
```

2. **既存のコンポーネント**:
```bash
# コンポーネントはすでに存在するか?
find src/shared/components -name "*Button*"
find src/shared/components -name "*Modal*"
```

3. **不明な場合はユーザーに確認**:
   - 「プロジェクトは[X]を使用しているようです。このパターンに従うべきか、[Y]を使用すべきか？」
```

**オプションC: 自動検証**

```bash
# .claude/hooks/PostToolUse.sh
#!/bin/bash
if [[ "$TOOL" == "Write" ]] || [[ "$TOOL" == "Edit" ]]; then
    FILE=$(echo "$INPUT" | jq -r '.tool.input.file_path')

    # パターン違反を確認
    if [[ "$FILE" =~ \.(tsx?)$ ]]; then
        CONTENT=$(cat "$FILE")

        # 違反: ReactのクラスコンポーネントR
        if echo "$CONTENT" | grep -q "class.*extends.*Component"; then
            echo "⚠️ 警告: $FILEでクラスコンポーネントを検出"
            echo "   プロジェクトは関数コンポーネントを使用しています。リファクタリングを検討してください。"
        fi

        # 違反: 間違ったHTTPライブラリ
        if echo "$CONTENT" | grep -q "import.*fetch\|window.fetch"; then
            echo "⚠️ 警告: $FILEでfetch()を検出"
            echo "   プロジェクトはaxiosを使用しています。使用方法: import axios from 'axios'"
        fi
    fi
fi
```


## ルール7: 検証のパラドックス

### 問題

AIが99%の確率で成功する場合、従来の人間による検証は脆弱になる:

**パラドックス**: AIの信頼性が増すと、人間のレビュー品質が低下する。

- **注意力疲れ**: 通常うまく機能するパターンを人間が無意識に信頼するようになると、まれなエラー（1%）が見逃される
- **パターン信頼行動**: レビュワーがエラーを予期しなくなるにつれ、手動レビューが低下する
- **過信**: 「最後の50回はうまくいった」が51回目の失敗への盲点を作る
- **認知負荷**: 人間は100回に1回のエラーを一貫してキャッチするのに最適化されていない

**実際のインシデント**:
- 200回の成功したトランザクション後に決済バリデーションがバイパスされた → 201回目のトランザクションで詐欺が発生
- 「AIは常に認証を正しく処理する」という理由でセキュリティチェックがスキップされた → 認証情報が漏洩
- テストスイートが99%合格 → テストされなかった1%のケースによる本番バグ

**出典**: [Alanエンジニアリングチーム（Charles Gorintin、Maxime Le Bras）、2026年2月](https://www.linkedin.com/pulse/le-principe-de-la-tour-eiffel-et-ralph-wiggum-maxime-le-bras-psmxe/)

### ルール

**人間の注意力に頼るのではなく、自動化された安全システムを構築する。**

AIの信頼性が約95%を超えたら、手動レビューから自動化されたガードレールに移行する。

### アンチパターン対より良いアプローチ

| アンチパターン | より良いアプローチ |
|--------------|-----------------|
| すべてのAI出力の手動レビュー | 自動テストスイート + 選択的レビュー |
| 「前回うまくいったから」という信頼 | 検証コントラクト（テスト、型、lint） |
| エラー検出者としての唯一の人間 | フェイルファストなガードレール（CI/CDゲート） |
| 高頻度AI操作の「スポットチェック」戦略 | 包括的な自動検証 |
| レビュワーの疲れ = 時間とともに低下する基準 | 一貫した自動化された品質バー |

### 実装

**オプションA: 自動化されたガードレールスタック**

```yaml
# .github/workflows/ai-safety.yml
name: AI出力の検証

on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: 型安全性
        run: npm run typecheck      # AIが見逃した型エラーをキャッチ

      - name: Lintルール
        run: npm run lint            # コーディング基準を強制

      - name: ユニットテスト
        run: npm run test            # 動作コントラクトを検証

      - name: E2Eテスト
        run: npm run test:e2e        # 統合の失敗をキャッチ

      - name: セキュリティ監査
        run: npm audit               # 脆弱な依存関係を検出

      - name: バンドル分析
        run: npm run analyze         # 肥大化/リグレッションをキャッチ

      # すべての自動化が合格した後にのみ人間がレビュー
```

**オプションB: CLAUDE.mdの検証コントラクト**

```markdown
## 検証プロトコル

### 人間のレビューだけに頼らない

**自動検証が必要**:
1. **型安全性**: `npm run typecheck`が合格すること（エラーゼロ）
2. **テスト**: `npm run test`のカバレッジ ≥ 新しいコードの80%
3. **Lint**: `npm run lint`が合格すること（警告ゼロ）
4. **セキュリティ**: `npm audit`がhigh/criticalの脆弱性ゼロを示すこと
5. **パフォーマンス**: 影響を受けるページのLighthouseスコア ≥ 90

**人間のレビューは以下のため**:
- アーキテクチャの決定
- UX/デザインの選択
- ビジネスロジックの検証
- 自動化がキャッチできないエッジケース

**人間のレビューは以下のためではない**:
- 構文エラー（linterを使用）
- 型エラー（TypeScriptを使用）
- パフォーマンスのリグレッション（ベンチマークを使用）
- セキュリティの問題（自動スキャナーを使用）
```

**オプションC: マージ前チェックリスト（自動化）**

```bash
# .claude/hooks/PreCommit.sh
#!/bin/bash

echo "🔍 自動検証を実行中（検証パラドックス防御）..."

# 1. 型安全性
npm run typecheck || { echo "❌ 型エラーを検出"; exit 1; }

# 2. Lint
npm run lint || { echo "❌ Lintエラーを検出"; exit 1; }

# 3. テスト
npm run test || { echo "❌ テストが失敗"; exit 1; }

# 4. セキュリティ
npm audit --audit-level=high || { echo "❌ セキュリティ脆弱性を検出"; exit 1; }

echo "✅ すべての自動チェックが合格"
echo "💡  人間のレビューはアーキテクチャ/UX/ビジネスロジックに集中できる"
```

### エッジケース

| シナリオ | 動作 |
|----------|----------|
| AIが99.9%の確率で完璧なコードを書く | それでも自動化を実行する（パラドックスは99.9%でも適用される） |
| 時間的プレッシャー、「ただリリースしたい」 | 自動化は交渉不可能（速さ ≠ 安全をスキップ） |
| 些細な変更（タイポ修正） | 自動化を実行する（タイポは本番を壊す可能性がある） |
| 緊急ホットフィックス | 自動化が必須（ストレス = 高いエラー率） |

### なぜこれが重要か

**旧モデル（AI以前）**:
- コード品質 = 人間の専門知識 + 注意深いレビュー
- 経験豊富な開発者がエラーをキャッチする
- レビュー品質が一定に保たれる

**新モデル（AI支援）**:
- AIは95%以上の確率で高品質なコードを生成する
- 人間が無頓着になる（「AIはたいていうまくやる」）
- 5%のエラー率が疲れたレビューをすり抜ける

**解決策**: 退屈な検証（構文、型、テスト）を自動化し、人間の注意力をクリエイティブ/戦略的なレビューのために確保する。

### 他のルールとの統合

- **ルール3（機能の完全性）**: 自動テストが機能が実際に完成していることを検証する
- **ルール2（データベースの安全性）**: マイグレーションテストが破壊的な操作をキャッチする
- **ルール6（パターンの遵守）**: Linterが自動的にプロジェクトの規約を強制する


## 既存のワークフローとの統合

### プランモードで

```bash
# 複数ファイルの変更前
/plan

# Claudeが読み取り専用モードに入り、コードベースを探索する
# パターン、規約、既存の実装を識別する
# プロジェクトの規約に従ったプランを提案する
# 実行前にレビューする
```

### Gitフックで

これらのルールは既存のgitワークフローと統合する:

```bash
# .git/hooks/pre-commit
#!/bin/bash

# 安全チェックを実行
./.claude/hooks/production-safety-check.sh

# ブロックされた場合、コミットは失敗する
exit $?
```

### CI/CDで

検証ステップを追加する:

```yaml
# .github/workflows/pr-validation.yml
name: PRの検証
on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: おざなり確認
        run: |
          if git diff origin/main...HEAD | grep -E "TODO.*implement|Not implemented"; then
            echo "❌ PRに未完成の機能が含まれています"
            exit 1
          fi

      - name: 未承認の依存関係を確認
        run: |
          git diff origin/main...HEAD -- package.json | grep -E '^\+.*"[^"]+": "[^"]+"' || exit 0
          echo "⚠️ 新しい依存関係を検出。レビューが必要です。"
```


## トラブルシューティング

### 「これらのルールは制限が多すぎる」

**解決策**: チームサイズとステージに応じて調整する。

| チームサイズ | 推奨ルール |
|-----------|-------------------|
| 1〜2人の開発者 | ルール1、3、6のみ |
| 3〜10人の開発者 | ルール1、3、5、6 |
| 10人以上または本番環境 | 全6ルール |

### 「Claudeが頻繁にブロックされる」

**解決策**: ルールが機能している！オプション:

1. **一時的な許可を付与する**:
   ```bash
   # CLAUDE.mdで
   ## 一時的なオーバーライド（2026-01-25に期限切れ）
   この機能のみ: インフラの変更が許可されています。
   理由: 新しいマイクロサービスのセットアップ。
   ```

2. **例外を作成する**:
   ```json
   {
     "permissions": {
       "allow": ["Edit(docker-compose.dev.yml)"],
       "deny": ["Edit(docker-compose.prod.yml)"]
     }
   }
   ```

3. **ルールが適切かどうかを検討する**:
   - 個人開発者が自分自身をブロックしている? → ルールを削除
   - チームに柔軟性が必要? → "deny"の代わりに"ask"を使用

### 「チーム全体でルールを強制するにはどうすればよいか？」

**解決策**: 個人設定ではなくリポジトリにコミットする。

```bash
# チームの共有ルール
/project/.claude/settings.json        # コミット済み
/project/CLAUDE.md                    # コミット済み

# 個人のオーバーライド
/project/.claude/settings.local.json  # gitignore済み
/project/.claude/CLAUDE.md            # gitignore済み
```

チーム設定が優先されるが、個人はより厳格なルールをオプトインできる。


## 関連情報

- [アルティメットガイド§9.12 Gitベストプラクティス](./ultimate-guide.md#912-git-best-practices--workflows) — コミットワークフロー、プラン → アクトパターン
- [セキュリティ強化ガイド](./security-hardening.md) — MCPセキュリティ、機密情報保護、フックスタック
- [データプライバシーガイド](./data-privacy.md) — MCPデータベースのリスク、保持ポリシー
- [エンタープライズAIガバナンス](./enterprise-governance.md) — 組織レベルのガバナンス: 使用チャーター、MCP承認ワークフロー、ガードレールティア、コンプライアンス
- [採用アプローチ](../roles/adoption-approaches.md) — チームセットアップ、共有規約、エンタープライズの展開
- [プランモード](./ultimate-guide.md#25-plan-mode) — 実行前の安全な探索
- [権限システム](./ultimate-guide.md#33-settings--permissions) — 許可/拒否ルール、フック


## クイックリファレンス

### ルールの重大度

| ルール | 重大度 | これを破ると起こること |
|------|----------|----------------------|
| 1. ポートの安定性 | 🔴 Critical | チームのダウンタイム、デプロイの失敗 |
| 2. データベースの安全性 | 🔴 Critical | データ損失、顧客への影響 |
| 3. 機能の完全性 | 🟡 High | 本番バグ、技術的負債 |
| 4. インフラのロック | 🟠 High | ダウンタイム、セキュリティの問題 |
| 5. 依存関係の安全性 | 🟡 Medium | バンドルの肥大化、ライセンスの問題 |
| 6. パターンの遵守 | 🟢 Low | コードの不整合、メンテナンスの負担 |

### 強制方法

| 方法 | 厳格さ | セットアップ時間 | 最適な用途 |
|--------|------------|------------|----------|
| **権限拒否** | 100%（ブロック） | 2分 | クリティカルなルール（1、2、4） |
| **Pre-toolフック** | 100%（ブロック） | 10分 | カスタムロジック、チーム固有 |
| **CLAUDE.mdルール** | ~70%（Claudeが尊重） | 5分 | 規約、ガイドライン |
| **Post-tool警告** | ~30%（警告のみ） | 5分 | ベストプラクティス、提案 |
| **Gitフック** | 100%（コミットをブロック） | 15分 | プッシュ前の最後のセーフティネット |

### 一般的なパターン

**ステージングの変更を許可し、本番をブロック**:
```json
{
  "permissions": {
    "allow": ["Edit(docker-compose.dev.yml)"],
    "deny": ["Edit(docker-compose.prod.yml)"]
  }
}
```

**機密操作の確認を要求**:
```json
{
  "permissions": {
    "ask": ["Bash(rm -rf *)", "Bash(DROP TABLE *)"]
  }
}
```

**有効期限付きの一時的なオーバーライド**:
```markdown
## 一時的なオーバーライド（2026-02-01に期限切れ）
マイグレーションプロジェクトのためにインフラの変更が許可されています。
期限切れ後: 標準ルールに戻す。
```


**バージョン**: 1.0.0
**最終更新**: 2026-01-21
**変更ログ**: コミュニティ検証済みの本番パターンに基づく初期バージョン
