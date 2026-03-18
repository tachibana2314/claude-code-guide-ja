---
layout: home
title: ホーム
nav_order: 1
---

# Claude Code 完全ガイド（日本語版）

Claude Code CLIツールの包括的なリファレンスガイド。コア概念からプロダクションセキュリティまで。

> [FlorianBruniaux/claude-code-ultimate-guide](https://github.com/FlorianBruniaux/claude-code-ultimate-guide) の日本語翻訳版です。

---

## クイックスタート

- **[チートシート](guide/cheatsheet)** — 1ページで確認できるデイリーエッセンシャル
- **[インタラクティブ版](site/)** — ブラウザで学べるHTML版ガイド
- **[アーキテクチャ](guide/core/architecture)** — Claude Codeの内部動作を理解する

---

## ガイド構成

| セクション | 内容 |
|---|---|
| [コア概念](guide/core/architecture) | マスターループ、8つのツール、200Kトークン、サブエージェント |
| [コンテキストエンジニアリング](guide/core/context-engineering) | トークン予算、モジュラーアーキテクチャ、チーム構成 |
| [開発手法](guide/core/methodologies) | TDD、SDD、BDD with AI |
| [セキュリティ](guide/security/security-hardening) | 脅威モデル、MCPベッティング、サンドボックス |
| [エコシステム](guide/ecosystem/ai-ecosystem) | 補完AIツール、MCPサーバー、サードパーティ |
| [ワークフロー](guide/workflows/) | TDD、Spec-First、Plan Mode、CI/CD、エージェントチーム |

---

## テンプレート

| カテゴリ | 内容 | 数 |
|---|---|---|
| [エージェント](examples/agents/code-reviewer) | カスタムAIペルソナ | 14 |
| [コマンド](examples/commands/commit) | スラッシュコマンド | 33 |
| [ルール](examples/rules/testing) | パス固有ルール | 1 |
| [CLAUDE.md](examples/claude-md/project-template) | プロジェクトテンプレート | 1 |

---

## クイズ

271問のクイズデータ（15カテゴリ）が `quiz/questions/` にYAML形式で格納されています。

---

## 参考

- [Claude Code Ultimate Guide (English)](https://github.com/FlorianBruniaux/claude-code-ultimate-guide) by Florian BRUNIAUX
- [Claude Code 公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)
- [Anthropic Engineering Blog](https://www.anthropic.com/engineering)
