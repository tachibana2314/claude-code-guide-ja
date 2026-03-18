# Claude Code 完全ガイド（日本語版）

> Claude Code CLIツールの包括的なリファレンスガイド。コア概念からプロダクションセキュリティまで、WHYを教える実践的ガイド。

---

## サイト

**[インタラクティブガイド](https://tachibana2314.github.io/claude-code-guide-ja/)** - ブラウザで学習できるインタラクティブなHTML版

---

## コンテンツ

| セクション | 内容 |
|---|---|
| はじめに | インストール、最初のワークフロー、Permission modes |
| コア概念 | マスターループ、8つのツール、200Kトークンバジェット、サブエージェント |
| 設定 & メモリ | CLAUDE.md階層、.claude/構造、パス固有ルール |
| エージェント & スキル | カスタムエージェント、スキル、コマンド、フック |
| MCP & ツール | MCPサーバー統合、tool_choice、組み込みツール |
| ワークフロー | TDD、Spec-First、Plan Mode、CI/CD統合 |
| セキュリティ | 脅威モデル、MCPベッティング、サンドボックス、フック |
| チートシート | コマンド一覧、ショートカット、クイックリファレンス |
| クイズ | 15問の理解度チェック |

## リポジトリ構造

```
claude-code-guide-ja/
├── index.html              # インタラクティブHTMLガイド
├── README.md               # このファイル
├── guide/                  # Markdownガイド
│   ├── core/               # コア概念
│   ├── security/           # セキュリティ
│   ├── ecosystem/          # エコシステム
│   └── workflows/          # ワークフロー
├── examples/               # テンプレート集
│   ├── agents/             # カスタムエージェント
│   ├── commands/           # スラッシュコマンド
│   ├── hooks/              # イベントフック
│   ├── skills/             # ナレッジモジュール
│   ├── config/             # 設定ファイル
│   ├── rules/              # ルールファイル
│   └── claude-md/          # CLAUDE.mdテンプレート
├── quiz/                   # クイズデータ
│   └── questions/          # 質問YAML
└── assets/                 # アセット
```

## テンプレート

### エージェント例

| エージェント | 用途 |
|---|---|
| code-reviewer | コードレビュー（品質、セキュリティ、パフォーマンス） |
| test-writer | テスト生成（TDD対応） |
| security-auditor | セキュリティ監査 |
| refactoring-specialist | リファクタリング提案 |

### コマンド例

| コマンド | 用途 |
|---|---|
| /commit | Conventional Commitメッセージ生成 |
| /pr | PR作成 |
| /review | コードレビュー実行 |
| /generate-tests | テスト自動生成 |

## 参考

- [Claude Code Ultimate Guide (English)](https://github.com/FlorianBruniaux/claude-code-ultimate-guide) by Florian BRUNIAUX
- [Claude Code 公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)
- [Anthropic Engineering Blog](https://www.anthropic.com/engineering)

## ライセンス

CC BY-SA 4.0 - 原著作者: Florian BRUNIAUX, 日本語版: tachibana2314
