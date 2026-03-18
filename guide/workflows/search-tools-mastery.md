---
layout: default
title: "検索ツールマスタリー: rg、grepai、Serena & ast-grepの組み合わせ"
parent: ワークフロー
grand_parent: ガイド
nav_order: 17
---


# 検索ツールマスタリー: rg、grepai、Serena & ast-grepの組み合わせ

> **適切なツールを組み合わせて最大の効率でコード検索をマスターする**

**著者**: Florian BRUNIAUX | Claudeによる貢献（Anthropic）
**読了時間**: 約20分
**最終更新**: 2026年1月


## 目次

1. [クイックリファレンスマトリクス](#クイックリファレンスマトリクス)
2. [ツール比較](#ツール比較)
3. [デシジョンツリー](#デシジョンツリー)
4. [組み合わせワークフロー](#組み合わせワークフロー)
5. [実世界のシナリオ](#実世界のシナリオ)
6. [パフォーマンス最適化](#パフォーマンス最適化)
7. [よくある落とし穴](#よくある落とし穴)


## クイックリファレンスマトリクス

| やりたいこと | 使うツール | コマンド例 |
|--------------|---------------|-----------------|
| 正確なテキストを見つける | `rg`（Grepツール） | `rg "authenticate" --type ts` |
| 意味で検索する | `grepai` | `grepai search "user login flow"` |
| 関数定義を見つける | `Serena` | `serena find_symbol --name "login"` |
| 構造パターンを見つける | `ast-grep` | `ast-grep "async function $F"` |
| 関数の呼び出し元を見る | `grepai` | `grepai trace callers "login"` |
| ファイル構造を取得する | `Serena` | `serena get_symbols_overview` |
| ファイルをまたいでリファクタリング | `Serena + ast-grep` | 組み合わせワークフロー |
| 未知のコードベースを探索する | `grepai → Serena` | 発見パターン |


## ツール比較

### 完全な機能マトリクス

| 機能 | rg（ripgrep） | grepai | Serena | ast-grep |
|---------|--------------|--------|--------|----------|
| **検索タイプ** | 正規表現/テキスト | セマンティック（意味） | シンボル対応 | AST構造 |
| **技術** | パターンマッチング | 埋め込み（Ollama） | シンボル解析 | 抽象構文ツリー |
| **速度** | ⚡ ~20ms | 🐢 ~500ms | ⚡ ~100ms | 🕐 ~200ms |
| **セットアップ** | ✅ なし（組み込み） | ⚠️ Ollama + インストール | ⚠️ MCP設定 | ⚠️ npm install |
| **統合** | ✅ ネイティブ（`Grep`） | ⚠️ MCPサーバー | ⚠️ MCPサーバー | ⚠️ プラグイン |
| **プライバシー** | ✅ 100%ローカル | ✅ 100%ローカル | ✅ 100%ローカル | ✅ 100%ローカル |
| **必要なコンテキスト** | なし | なし | プロジェクトのインデックス | なし |
| **言語** | すべて（テキスト） | すべて | TS/JS/Py/Rust/Go | TS/JS/Py/Rust/Go/C++ |
| **コールグラフ** | ❌ なし | ✅ あり | ❌ なし | ❌ なし |
| **シンボル追跡** | ❌ なし | ❌ なし | ✅ あり | ❌ なし |
| **セッションメモリ** | ❌ なし | ❌ なし | ✅ あり | ❌ なし |
| **誤検知** | 中 | 低 | 非常に低い | 非常に低い |
| **学習曲線** | 低 | 中 | 低 | 高 |

### トークンコスト比較

| ツール | 典型的なクエリ | 消費トークン | 返される結果 |
|------|---------------|-----------------|------------------|
| **rg** | "authenticate" | ~500 | 完全一致のみ |
| **grepai** | "auth flow" | ~2000 | 意図ベースの一致 |
| **Serena** | find_symbol | ~1000 | シンボル + コンテキスト |
| **ast-grep** | ASTパターン | ~1500 | 構造的一致 |

**重要な洞察**: rgは4倍トークン効率が良いが、セマンティックツールより10倍インテリジェントではない。


## デシジョンツリー

### レベル1: 何を知っているか？

```
正確なテキスト/パターンを知っているか？
│
├─ はい → rg（ripgrep）を使用
│  ├─ 既知の関数名: rg "createSession"
│  ├─ 既知のインポート: rg "import.*React"
│  └─ 既知のパターン: rg "async function"
│
└─ いいえ → レベル2へ
```

### レベル2: 何を探しているか？

```
検索の意図は何か？
│
├─ 「意味/概念で検索」
│  → grepaiを使用
│  └─ 例: grepai search "payment validation logic"
│
├─ 「関数/クラスの定義を探す」
│  → Serenaを使用
│  └─ 例: serena find_symbol --name "UserController"
│
├─ 「コード構造で探す」
│  → ast-grepを使用
│  └─ 例: エラーハンドリングのないasync
│
└─ 「依存関係を理解する」
   → grepai traceを使用
   └─ 例: grepai trace callers "validatePayment"
```

### レベル3: 最適化

```
結果が多すぎる場合？
│
├─ rg → --typeフィルターを追加またはパスを絞り込む
├─ grepai → --pathフィルターを追加またはtraceを使用
├─ Serena → シンボルタイプでフィルタリング（function/class）
└─ ast-grep → パターンに制約を追加
```


## 組み合わせワークフロー

### ワークフロー1: 未知のコードベースを探索する

**目標**: 新しいプロジェクトを素早く理解する

**ステップバイステップ**:

```bash
# 1. セマンティック発見（grepai）
# 認証に関連するファイルを見つける
grepai search "user authentication and session management"
# → 出力: auth.service.ts, session.middleware.ts, user.controller.ts

# 2. 構造的概要（Serena）
# 各ファイルの構造を理解する
serena get_symbols_overview --file auth.service.ts
# → 出力:
#   - class AuthService
#     - login(email, password)
#     - logout(sessionId)
#     - validateSession(token)

# 3. 依存関係マッピング（grepai trace）
# loginがどのように使われているかを見る
grepai trace callers "login"
# → 出力: UserController, ApiGateway, AdminPanelから呼ばれている

# 4. 正確な検索（rg）
# 具体的な実装の詳細を見つける
rg "validateSession" --type ts -A 5
# → 出力: 5行のコンテキスト付き完全な関数
```

**結果**: 4つのコマンドで完全な理解（30以上のファイル読み込みの代わりに）


### ワークフロー2: 大規模リファクタリング

**目標**: `createSession` → `initializeUserSession` に50以上のファイルで変更する

**ステップバイステップ**:

```bash
# 1. 影響分析（grepai trace）
# 完全なスコープを理解する
grepai trace callers "createSession"
# → 出力: 23ファイルにわたる47の呼び出し元
grepai trace callees "createSession"
# → 出力: validateUser, createToken, storeSessionを呼び出す

# 2. 構造的検証（ast-grep）
# 一貫した使用パターンを確認する
ast-grep "createSession($$$ARGS)"
# → 出力: すべての呼び出しとその引数パターン

# 3. シンボル対応リファクタリング（Serena）
# 正確なリネーミング
serena find_symbol --name "createSession" --include-body true
# → 完全な定義 + すべての参照を取得

serena replace_symbol_body \
  --name "createSession" \
  --new-name "initializeUserSession"
# → 構造を維持してすべてのファイルでリネーム

# 4. 検証（rg）
# 古い参照が残っていないことを確認する
rg "createSession" --type ts
# → 0件の結果を返すべき
```

**結果**: 完全な依存関係認識による安全なリファクタリング


### ワークフロー3: セキュリティ監査

**目標**: セキュリティの脆弱性を見つける

**ステップバイステップ**:

```bash
# 1. セマンティック発見（grepai）
# セキュリティに敏感なコードを見つける
grepai search "SQL query construction"
grepai search "user input validation"
grepai search "password handling"

# 2. 構造パターン（ast-grep）
# 特定の脆弱性パターンを見つける

# SQLインジェクションのリスク
ast-grep 'db.query(`${$VAR}`)'

# XSSのリスク
ast-grep 'innerHTML = $VAR'

# 欠落したエラーハンドリング
ast-grep -p 'async function $F($$$) { $$$BODY }' \
  --without 'try { $$$TRY } catch'

# 3. 依存関係トレース（grepai）
# 脆弱なコードがどこから呼ばれているかを見る
grepai trace callers "executeQuery"
# → すべてのエントリポイントを特定

# 4. 正確な検証（rg）
# 調査結果を確認する
rg "innerHTML\s*=" --type ts
rg "password" --type ts | rg -v "hashed"
```

**結果**: 数分での包括的なセキュリティ監査


## 実世界のベンチマーク

### grepai対grep（2026年1月）

**コンテキスト**: Excalidraw（15万行のTypeScript）でのベンチマーク
**著者**: YoanDev（grepaiのメンテナー — 潜在的なバイアスあり）
**方法論**: 5つの同一コードディスカバリー質問

| メトリクス | grep | grepai | 差異 |
|----------|------|--------|------------|
| ツール呼び出し | 139 | 62 | **-55%** |
| 入力トークン | 51k | 1.3k | **-97%** |

**要点**: セマンティック検索は最初の試みで関連ファイルを特定することで、反復的な探索を避けトークンを大幅に削減します。

**制限**:
- ツールのメンテナーによるベンチマーク
- 単一プロジェクトの検証（TypeScriptのみ）
- 独立した検証はまだなし

**ソース**: [yoandev.co/grepai-benchmark](https://yoandev.co/grepai-benchmark)

> **注記**: このベンチマークは2026年1月の状態を反映しています。Claude CodeとgrepaiのアップデートによりパフォーマンスはChange may occur.


### ワークフロー4: フレームワークマイグレーション

**目標**: Reactクラスコンポーネント → フックに移行する

**ステップバイステップ**:

```bash
# 1. インベントリ（ast-grep）
# すべてのクラスコンポーネントを見つける
ast-grep 'class $C extends React.Component'
# → 出力: 移行する34コンポーネント

# 2. 依存関係分析（grepai）
# コンポーネントの関係を理解する
for component in $(ast-grep 'class $C extends' --json | jq -r '.[].name'); do
  grepai trace callers "$component"
done
# → 移行順序を構築（葉コンポーネントから）

# 3. パターン検出（ast-grep）
# 使用されているライフサイクルメソッドを特定する
ast-grep 'componentDidMount() { $$$BODY }'
ast-grep 'componentWillReceiveProps($$$) { $$$BODY }'
# → 同等のフックにマッピング

# 4. インクリメンタル移行（Serena + ast-grep）
# 一度に1コンポーネントを移行
serena find_symbol --name "UserProfile" --include-body true
# → 完全なコンポーネントコードを取得

# ast-grepを使って変換
ast-grep --rewrite \
  --from 'class $C extends React.Component' \
  --to 'const $C = () => { }'

# 5. 検証（rg + grepai）
# 移行成功を確認する
rg "React.Component" --type tsx  # 減少するはず
grepai search "component lifecycle methods"  # 見逃したものを見つける
```

**結果**: 最小限の破損による体系的な移行


### ワークフロー5: パフォーマンス最適化

**目標**: パフォーマンスのボトルネックを特定して修正する

**ステップバイステップ**:

```bash
# 1. ホットスポット発見（grepai）
# パフォーマンスクリティカルなコードを見つける
grepai search "heavy computation or loops"
grepai search "database queries in loops"

# 2. パターン検出（ast-grep）
# N+1クエリパターンを見つける
ast-grep 'for ($$$) { await db.query($$$) }'

# 欠落したメモ化を見つける
ast-grep 'useMemo' --invert-match \
  --in 'const $VAR = $$$'

# 3. コールグラフ分析（grepai trace）
# ホットパスを見つける
grepai trace graph "renderUserList" --depth 3
# → 依存関係ツリーを可視化

# 4. シンボル追跡（Serena）
# 関数の変更を追跡する
serena write_memory "perf_baseline" \
  "renderUserList: 450ms avg"

# 最適化後
serena write_memory "perf_optimized" \
  "renderUserList: 45ms avg (10x improvement)"

# 5. 検証（rg）
# 最適化が適用されたことを確認する
rg "useMemo|useCallback" --type tsx
```

**結果**: データ駆動のパフォーマンス改善


## 実世界のシナリオ

### シナリオ1: 「何を探しているかわからない」

**問題**: 新しいプロジェクト、ドキュメントなし、機能を追加する必要がある

**解決策**: セマンティックファーストの発見

```bash
# まず意味で広く検索
grepai search "user profile management"
# → 関連ファイルを発見

# 次に構造で絞り込む
serena get_symbols_overview --file user-profile.service.ts
# → 利用可能な関数を理解

# 最後に詳細を正確に検索
rg "updateProfile" --type ts -C 3
```


### シナリオ2: 「この関数はあちこちから呼ばれている」

**問題**: 関数を変更する必要があるが、何かを壊すことを心配している

**解決策**: 最初に依存関係マッピング

```bash
# 1. すべての呼び出し元を見る
grepai trace callers "calculateTotal"
# → 47の呼び出し元が見つかる

# 2. 呼び出し元のコンテキストを分析する
for file in $(grepai trace callers "calculateTotal" --json | jq -r '.[].file'); do
  serena get_symbols_overview --file "$file"
done

# 3. 安全な呼び出し元と危険な呼び出し元を特定する
ast-grep 'calculateTotal($ARGS)' --json
# → 引数パターンでグループ化

# 4. 自信を持って変更する
# すべての影響ポイントを把握した上で
```


### シナリオ3: 「Xをするすべてのコードを見つける」

**問題**: コードベース全体に一貫したパターンを適用する必要がある

**解決策**: セマンティック + 構造を組み合わせる

```bash
# 例: すべてのエラーハンドリングコードを見つける

# 1. セマンティック発見
grepai search "error handling and exception management"

# 2. 構造パターン
ast-grep 'try { $$$TRY } catch ($ERR) { $$$CATCH }'
ast-grep 'throw new Error($MSG)'

# 3. 一貫性を検証する
rg "catch\s*\(" --type ts | wc -l
# ast-grepのカウントと比較して異常を見つける
```


### シナリオ4: 「このモジュールを理解する必要がある」

**問題**: 責任が不明確な複雑なモジュール

**解決策**: マルチツール分析

```bash
# 1. シンボル概要を取得する（Serena）
serena get_symbols_overview --file payment.module.ts
# → すべてのエクスポート、クラス、関数を見る

# 2. 依存関係を理解する（grepai）
grepai trace callees "PaymentModule"
# → このモジュールは何を使うか？

grepai trace callers "PaymentModule"
# → 誰がこのモジュールを使うか？

# 3. 実装パターンを見つける（ast-grep）
ast-grep 'export class $C' --file payment.module.ts
ast-grep 'async $METHOD($$$)' --file payment.module.ts

# 4. 具体的な実装を読む（rg）
rg "processPayment" --type ts -A 20
```


## パフォーマンス最適化

### 最速のツールを選ぶ

**一般的なルール**:

1. **既知の正確なテキスト** → 常にまずrgを使用
2. **正確なテキスト不明** → grepai、次に検証のためrg
3. **リファクタリング** → シンボルの安全性のためSerena
4. **大規模移行** → 構造的な精度のためast-grep

### パフォーマンスベンチマーク

**テスト**: 50万行のコードベースで認証コードを見つける

| 戦略 | 時間 | 結果の質 |
|----------|------|-----------------|
| rgのみ "auth" | 0.2s | 5000以上の誤検知 |
| grepaiのみ "auth" | 2.5s | 50の関連結果 |
| grepai → rg（組み合わせ） | 2.7s | 50の関連、検証済み |
| Serenaシンボルのみ | 1.5s | 12の認証関数 |
| ast-grepパターン | 3.0s | 8の認証フロー |

**勝者**: Serenaシンボル（最速 + 高品質）既知の関数名に対して

### 並列化戦略

**大規模コードベース（10万行以上）の場合**:

```bash
# 並列に検索を実行する

# ターミナル1: セマンティック発見
grepai search "authentication flow" > /tmp/grepai-results.json &

# ターミナル2: シンボルインデックス
serena get_symbols_overview --file src/**/*.ts > /tmp/symbols.json &

# ターミナル3: パターン検出
ast-grep 'async function $F' --json > /tmp/ast-results.json &

# すべてを待って、結果を結合する
wait
jq -s '.[0] + .[1] + .[2]' \
  /tmp/grepai-results.json \
  /tmp/symbols.json \
  /tmp/ast-results.json
```


## よくある落とし穴

### 落とし穴1: 正確な一致にセマンティック検索を使用する

❌ **間違い**:
```bash
grepai search "createSession"  # 遅い、過剰
```

✅ **正しい**:
```bash
rg "createSession" --type ts  # 速い、正確
```

**ルール**: 正確なテキストを知っている場合、セマンティック検索は使わない。


### 落とし穴2: 概念検索にrgを使用する

❌ **間違い**:
```bash
rg "auth.*login.*session" --type ts  # バリエーションを見逃す
```

✅ **正しい**:
```bash
grepai search "authentication and session management"
```

**ルール**: 正規表現は意味を理解しない。セマンティックツールを使用する。


### 落とし穴3: リファクタリング前にコールグラフを無視する

❌ **間違い**:
```bash
# 呼び出し元を確認せずに直接リファクタリング
rg "oldFunction" --type ts | sed 's/oldFunction/newFunction/g'
```

✅ **正しい**:
```bash
# 最初に影響を確認する
grepai trace callers "oldFunction"
# 23ファイルにわたる47の呼び出し元を見る
# 次にリファクタリング戦略を計画する
```

**ルール**: 共有コードを変更する前に常に依存関係をトレースする。


### 落とし穴4: ツールを組み合わせない

❌ **間違い**:
```bash
# 複雑なタスクに1つのツールだけを使用する
ast-grep 'async function $F' --json | jq '.[].file' | xargs -I {} vim {}
# コンテキストを理解せずに盲目的に編集
```

✅ **正しい**:
```bash
# 完全な理解のために組み合わせる
ast-grep 'async function $F' --json > /tmp/async.json
for file in $(jq -r '.[].file' /tmp/async.json); do
  serena get_symbols_overview --file "$file"  # コンテキスト
  grepai trace callers "$(jq -r '.[].name' /tmp/async.json)"  # 使用法
done
```

**ルール**: 複雑なタスクには複数の視点が必要。


### 落とし穴5: シンプルな検索を過剰設計する

❌ **間違い**:
```bash
# TODOコメントを見つけるだけのためにgrepai + Ollamaをセットアップする
grepai search "TODO comments in the code"
```

✅ **正しい**:
```bash
rg "TODO" --type ts
```

**ルール**: 機能する最もシンプルなツールを使用する。


## ツール選択チートシート

### クイックデシジョンマトリクス

| あなたの状況 | これを使う | これは使わない |
|----------------|----------|----------|
| 「関数`login`を見つける」 | rg "login" | grepai search "login" |
| 「loginに関連するコードを見つける」 | grepai "login flow" | rg "login.*" |
| 「関数を安全にリネームする」 | Serena find_symbol | rg + sed |
| 「誰がこの関数を呼ぶか？」 | grepai trace callers | rg + grep |
| 「ファイル構造を取得する」 | Serena overview | rg "class\|function" |
| 「try/catchなしのasyncを見つける」 | ast-grep | rg "async.*{" |
| 「Reactクラスを移行する」 | ast-grep | rg + 手動 |
| 「TODOを見つける」 | rg "TODO" | その他のツール |


## セットアップの優先順位

**推奨セットアップ順序**:

1. **開始**: rg（Grepツールで既に組み込み済み）✅
2. **次**: Serena MCP（シンボル認識、セッションメモリ）
3. **次に**: grepai（セマンティック検索 + コールグラフ）
4. **最後に**: ast-grep（構造パターン、大規模リファクタリング）

**根拠**: 検索の90%はrg + Serenaで機能します。セマンティックニーズにはgrepaiを追加。大規模なリファクタリング/移行をする場合のみast-grepを追加。


## まとめ: 4ツールのシンフォニー

```
┌─────────────────────────────────────────────────────────┐
│                   SEARCH TOOL MASTERY                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  rg（ripgrep）   →  高速、正確なテキストマッチング      │
│  ├─ 使用: 検索の90%                                     │
│  └─ 速度: ⚡ ~20ms                                      │
│                                                         │
│  grepai          →  セマンティック + コールグラフ       │
│  ├─ 使用: 概念発見、依存関係トレース                    │
│  └─ 速度: 🐢 ~500ms（でもrgが見つけられないものを見つける）│
│                                                         │
│  Serena          →  シンボル対応 + セッションメモリ     │
│  ├─ 使用: リファクタリング、構造理解                    │
│  └─ 速度: ⚡ ~100ms                                     │
│                                                         │
│  ast-grep        →  AST構造パターン                     │
│  ├─ 使用: 大規模移行、複雑なパターン                    │
│  └─ 速度: 🕐 ~200ms                                    │
│                                                         │
│  ═══════════════════════════════════════════════════   │
│                                                         │
│  個々のツールではなく、組み合わせをマスターする。        │
│  各ツールにはスイートスポットがある — 正しいものを使う。 │
│                                                         │
└─────────────────────────────────────────────────────────┘
```


## 参考資料

- [Serena MCPガイド](../ultimate-guide.md#serena-semantic-code-analysis)
- [grepaiドキュメント](../ultimate-guide.md#grepai-recommended-semantic-search)
- [ast-grepパターンスキル](../../examples/skills/ast-grep-patterns.md)
- [アーキテクチャ: Grep対RAGの歴史](../core/architecture.md#search-strategy-evolution)


**最終更新**: 2026年1月
**互換性**: Claude Code 2.1.7+
