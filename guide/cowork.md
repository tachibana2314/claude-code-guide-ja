---
title: "Claude Cowork: ナレッジワークのためのエージェント型デスクトップ"
description: "非技術系ナレッジワーカー向けClaudeエージェント型デスクトップ機能の概要"
tags: [guide, agents, workflows]
---

# Claude Cowork: ナレッジワークのためのエージェント型デスクトップ

> **📦 完全なドキュメントは専用リポジトリに移行済み**
> このファイルは概要です。完全なドキュメントは以下をご覧ください:
> **https://github.com/FlorianBruniaux/claude-cowork-guide**

---

## クイック概要

**Cowork** は、Claude Desktopアプリを通じて非技術系ユーザーに自律的なAI機能を提供する、Claudeのエージェント型デスクトップ機能です。ターミナルコマンドの代わりに、Coworkはローカルフォルダやファイルに直接アクセスします。

### 主要情報

| 項目 | 詳細 |
|--------|---------|
| **ステータス** | リサーチプレビュー（2026年1月） |
| **アクセス** | Pro（月$20）またはMax（月$100〜200）サブスクリプション、macOSのみ |
| **特徴** | ファイル操作、ドキュメント生成、整理整頓 |
| **Codeとの違い** | コード実行なし — ファイルのみ |

---

## 3つのClaudeツール：どれを使うべきか

3つのツール、1つのサブスクリプション（Proで月$20）。競合ではなく、補完関係にあります。

| | Claude AI | Claude Code | Cowork |
|---|-----------|-------------|--------|
| **インターフェース** | Web / モバイル | ターミナル（CLI） | デスクトップアプリ |
| **タグライン** | 書く・考える・調べる | コードを大規模に扱う | コードなしで自動化する |
| **定義** | 汎用的な会話アシスタント | コードベース全体を扱う自律エージェント | 非エンジニア向けエージェント型ファイルワークフロー |
| **主な用途** | ライティング、ブレインストーミング、リサーチ | デバッグ、リファクタリング、テスト | ファイル整理、PDF抽出、クロスアプリワークフロー |
| **コード実行** | なし | あり | なし |
| **ファイルシステムアクセス** | アップロードのみ | フルアクセス | フォルダサンドボックス |
| **セットアップ** | 不要 | npm install -g @anthropic-ai/claude-code | macOSアプリのインストール |
| **成熟度** | 本番運用 | 本番運用 | リサーチプレビュー |
| **理想的なユーザー** | ライター・コンサルタント・学生 | 開発者・エンジニア・テックリード | 事務職・アシスタント・非技術系SMB |
| **主なトレードオフ** | システムアクセスなし | 大規模プロジェクトでのトークンコスト | macOSのみ、設定が限られる |

→ [CoworkとCodeの詳細比較](https://github.com/FlorianBruniaux/claude-cowork-guide/blob/main/reference/comparison.md)

### 選択ガイド

- **ドキュメントを書く、リサーチをする？** → Claude AI
- **コーディング：リファクタリング、デバッグ、テスト？** → Claude Code（今まさにいる場所）
- **ファイルの整理、PDFの抽出、コード不要？** → Cowork

---

## ユースケース

- **ファイル整理** — 散らかったフォルダ → 整理された構造
- **経費管理** — 領収書 → Excelレポート
- **レポート統合** — 複数ドキュメント → 統合レポート
- **ミーティング準備** → リサーチ → ブリーフィングドキュメント

→ [詳細なワークフロー](https://github.com/FlorianBruniaux/claude-cowork-guide/tree/main/workflows)

---

## セキュリティの概要

現時点では公式のセキュリティドキュメントは存在しません。必須の実践事項:

1. **専用ワークスペース** — Documents/Desktopへのアクセスを許可しない
2. **プランのレビュー** — 承認前にすべてのアクションを確認する
3. **認証情報なし** — 機密データをワークスペースに置かない
4. **先にバックアップ** — 破壊的な操作の前にバックアップを取る

→ [完全なセキュリティガイド](https://github.com/FlorianBruniaux/claude-cowork-guide/blob/main/guide/03-security.md)

---

## ドキュメント

| リソース | 説明 |
|----------|-------------|
| **[完全なドキュメント](https://github.com/FlorianBruniaux/claude-cowork-guide/blob/main/README.md)** | Coworkガイドハブ |
| **[はじめに](https://github.com/FlorianBruniaux/claude-cowork-guide/blob/main/guide/01-getting-started.md)** | セットアップと最初のワークフロー |
| **[機能](https://github.com/FlorianBruniaux/claude-cowork-guide/blob/main/guide/02-capabilities.md)** | Coworkでできること/できないこと |
| **[プロンプトライブラリ](https://github.com/FlorianBruniaux/claude-cowork-guide/tree/main/prompts)** | 50以上のすぐに使えるプロンプト |
| **[チートシート](https://github.com/FlorianBruniaux/claude-cowork-guide/blob/main/reference/cheatsheet.md)** | 1ページのクイックリファレンス |
| **[FAQ](https://github.com/FlorianBruniaux/claude-cowork-guide/blob/main/reference/faq.md)** | よくある質問 |

---

*[AIエコシステムガイド](./ai-ecosystem.md) | [アルティメットガイド](./ultimate-guide.md) | [メインREADME](../README.md) に戻る*
