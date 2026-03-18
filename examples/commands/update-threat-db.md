---
layout: default
title: "脅威データベースの更新"
parent: コマンド
grand_parent: テンプレート
nav_order: 29
---


# 脅威データベースの更新

AI エージェントセキュリティ脅威インテリジェンスデータベースを最新の脅威、CVE、悪意あるスキル、キャンペーンで調査・更新します。

**時間**: 3-8分 | **スコープ**: `examples/commands/resources/threat-db.yaml`

> Perplexity MCP が必要（または手動 Web 検索）。毎月または主要なセキュリティアドバイザリの後に実行します。

## 手順

あなたは AI コーディングエージェントセキュリティを専門とする脅威インテリジェンスアナリストです。最新の脅威を調査して脅威データベースを更新してください。


### フェーズ 1: 現在の状態の評価

現在の脅威データベースを読み込みます:

```
Read examples/commands/resources/threat-db.yaml
```

以下をメモします:
- 現在の `version` と `updated` 日付
- 悪意あるオーサー、スキル、CVE、キャンペーンの数
- 重複を避けるための最新エントリ


### フェーズ 2: 新しい脅威の調査

**4つの的を絞った Perplexity 検索**を実行します（可能な場合は並列）:

**検索 1: 新しい悪意あるスキルとキャンペーン**
```
Query: "malicious AI agent skills ClawHub OpenClaw skills.sh 2026 new campaigns malware supply chain"
Focus: threat-db.yaml にまだない新しい悪意あるスキル名、オーサー、キャンペーン
```

**検索 2: 新しい MCP サーバー CVE**
```
Query: "MCP server CVE vulnerability 2025 2026 model context protocol security advisory"
Focus: MCP サーバーの新しい CVE、SDK の脆弱性、トランスポートレベルの欠陥
```

**検索 3: 新しい攻撃技術**
```
Query: "AI coding agent attack prompt injection Claude Code Cursor supply chain security research 2026"
Focus: 新しい攻撃ベクター、技術、研究論文
```

**検索 4: 新しい防御ツールとブロックリスト**
```
Query: "MCP security scanner tool mcp-scan alternative AI agent skills security scanning 2026"
Focus: 新しいスキャンツール、ブロックリスト、防御フレームワーク
```

Perplexity MCP が利用できない場合は、各クエリに WebSearch を使用します。


### フェーズ 3: 分析と重複排除

フェーズ 2 からの各所見について:

1. **threat-db.yaml にすでに含まれているか確認** — 重複はスキップ
2. **ソースの信頼性を確認** — 優先: CVE データベース、セキュリティベンダーブログ、査読済み研究
3. **カテゴリー分け** — どのセクションに属するか？
   - `malicious_authors` — 新しく確認された悪意あるパブリッシャー
   - `malicious_skills` — 新しく確認された悪意あるスキル/パッケージ名
   - `malicious_skill_patterns` — ワイルドカードマッチングの新しいプレフィックスパターン
   - `cve_database` — component、severity、fixed_in を含む新しい CVE
   - `minimum_safe_versions` — 新しいパッチが利用可能な場合に更新
   - `iocs` — 新しい C2 IP、漏洩 URL、マルウェアハッシュ
   - `campaigns` — 新しい協調キャンペーン
   - `attack_techniques` — 新しくドキュメント化された攻撃ベクター
   - `scanning_tools` — 新しいツールまたは主要な更新
   - `defensive_resources` — 新しいフレームワーク、ブロックリスト

4. **リスクレベルを評価**:
   - `critical` — 確認された悪意あり、積極的な悪用
   - `high` — 確認された脆弱性、エクスプロイトが利用可能
   - `medium` — 理論的リスク、既知の悪用なし
   - `low` — 情報提供のみ


### フェーズ 4: threat-db.yaml の更新

以下のルールに従って変更を適用します:

1. **バージョンをバンプ** — 新しいエントリには minor を増やす（例: 2.0.0 → 2.1.0）、スキーマ変更には major
2. **`updated` 日付を更新** — 今日に設定
3. **新しいソースを追加** — 新しい研究ソースを `sources` リストに追加
4. **YAML の有効性を維持** — バックスラッシュを含むパターンには単一引用符を使用
5. **既存のエントリを保持** — 確認された誤検知でない限り削除しない
6. **既存のフォーマットに従う** — 既存のエントリの構造と完全に一致させる

**重要**: 編集後、YAML を検証します:
```bash
python3 -c "import yaml; yaml.safe_load(open('examples/commands/resources/threat-db.yaml')); print('YAML valid')"
```


### フェーズ 5: 依存するファイルの更新（必要な場合）

新しい CVE をセキュリティハードニングガイドにも追加する必要があるか確認します:

```bash
# threat-db vs security-hardening の現在の CVE 数を比較
grep -c "id:" examples/commands/resources/threat-db.yaml
grep -c "CVE-" guide/security-hardening.md
```

新しい重大な CVE が見つかった場合（クリティカル/高い重大度）:
- `guide/security-hardening.md` の CVE テーブルへの追加を検討
- 新しいパッチがリリースされた場合は `minimum_safe_versions` を更新


### フェーズ 6: サマリーレポート

## 出力フォーマット

```
## Threat Database Update Report

**Date**: [timestamp]
**Previous version**: [old version]
**New version**: [new version]

### Changes Summary

| Category | Added | Updated | Total |
|----------|-------|---------|-------|
| Malicious authors | +X | ~X | XX |
| Malicious skills | +X | ~X | XX |
| CVEs | +X | ~X | XX |
| Campaigns | +X | ~X | XX |
| IOCs | +X | ~X | XX |
| Attack techniques | +X | ~X | XX |
| Scanning tools | +X | ~X | XX |

### New Entries

[各新しいエントリとソース、リスクレベル]

### Notable Findings

[特に重要または緊急なものをハイライト]

### No Changes Needed

[何も新しいものが見つからない場合、検索された内容と最新であることの確認]

### Next Steps

- [ ] `/security-check` を実行して更新されたデータベースに対してテスト
- [ ] 新しいクリティカルな CVE がある場合 `guide/security-hardening.md` を更新
- [ ] コミット: `docs(security): update threat-db vX.Y.Z — [summary]`
```

$ARGUMENTS
