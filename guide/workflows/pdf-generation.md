---
layout: default
title: "Claude CodeによるPDF生成"
parent: ワークフロー
grand_parent: ガイド
nav_order: 13
---


# Claude CodeによるPDF生成

> **信頼度**: Tier 2 — Quarto/Typstスタックを使った本番テスト済みのワークフローに基づく。

Claude Codeを使って、モダンなタイポグラフィとデザインでプロフェッショナルなPDF（ドキュメント、ホワイトペーパー、レポート）を生成します。


## 目次

1. [要約](#要約)
2. [使う場面](#使う場面)
3. [スタックの概要](#スタックの概要)
4. [セットアップ](#セットアップ)
5. [ワークフロー](#ワークフロー)
6. [Claude Codeとの統合](#claude-codeとの統合)
7. [カスタマイズ](#カスタマイズ)
8. [トラブルシューティング](#トラブルシューティング)
9. [関連情報](#関連情報)


## 要約

```bash
# インストール
brew install quarto  # macOS

# 生成
quarto render document.qmd  # → document.pdf

# プレビュー
quarto preview document.qmd  # ホットリロード
```

**スタック**: Quarto（オーケストレーション）+ Typst（タイポグラフィ）+ Pandoc（Markdown）


## 使う場面

| ユースケース | 適合 | 代替 |
|----------|----------|-------------|
| 技術ドキュメント | ✅ | — |
| ホワイトペーパー/レポート | ✅ | — |
| APIドキュメント | ⚠️ | OpenAPI + Redoc |
| スライド/プレゼンテーション | ⚠️ | Quarto Revealjs |
| クイックメモ | ❌ | プレーンMarkdown |
| 共同編集 | ❌ | Google Docs、Notion |

**最適な用途**: プロフェッショナルなレイアウト、バージョン管理、再現性が必要な長文の技術コンテンツ。


## スタックの概要

```
┌─────────────────────────────────────────────────┐
│                  Your .qmd File                 │
│         (Markdown + YAML frontmatter)           │
└─────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────┐
│                    Quarto                       │
│           (Document rendering engine)           │
│         • Processes YAML metadata               │
│         • Handles extensions                    │
│         • Manages output formats                │
└─────────────────────────────────────────────────┘
                        │
          ┌─────────────┴─────────────┐
          ▼                           ▼
┌─────────────────────┐    ┌─────────────────────┐
│       Pandoc        │    │       Typst         │
│   (MD → AST → ?)    │    │  (Typography/PDF)   │
│  • Markdown parser  │    │  • Modern engine    │
│  • AST transforms   │    │  • Fast compilation │
│  • Format bridges   │    │  • No LaTeX needed  │
└─────────────────────┘    └─────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────┐
│                  document.pdf                   │
│        (Professional typography output)         │
└─────────────────────────────────────────────────┘
```

### 出力フォーマットとコマンド

```
  FORMAT                COMMANDE                      SORTIE
  ──────                ────────                      ──────

  PDF standard    →  quarto render doc.qmd            doc.pdf
                     --to typst                       (sans template custom)

  PDF stylé ✅    →  quarto render doc.qmd            doc.pdf
                     --to whitepaper-typst            (~270K–1.7M, Bold Guy)
                     (format custom via _extensions/)

  EPUB            →  quarto render doc.qmd            doc.epub
                     --to epub

  Preview         →  quarto preview doc.qmd           hot-reload navigateur
```

### 拡張機能の構造

```
  _extensions/
  └── whitepaper/
      ├── _extension.yml       ← "whitepaper-typst"フォーマットを宣言
      ├── typst-template.typ   ← デザインシステム（カラー、タイポ、callout）
      └── typst-show.typ       ← Quarto → Typstのブリッジ

  ⚠️  fr/ en/ とルートで複数コピーを維持する場合:
      3つの typst-template.typ ファイルを同期させておく
```

### クイックトラブルシューティング

```
  症状                              原因                     修正
  ────────                          ─────                    ───
  小さいPDF（~80-190K）、スタイルなし  --to typst を使用        --to whitepaper-typst を使用
                                     --to whitepaper-typst の代わりに

  "bibliography"エラー               calloutタイトルに@ref     タイトルから@を削除
                                     → 引用として解釈される

  テーブルがコードとして表示          バッククォート``` が閉じていない  ``` の数を確認（偶数である必要あり）

  "Extension not found"              ディレクトリが違う          _extensions/ パスを確認
```

| コンポーネント | バージョン | 役割 |
|-----------|---------|------|
| **Quarto** | ≥1.4.0 | オーケストレーション、拡張機能、マルチフォーマット |
| **Typst** | 0.13.0 | モダンタイポグラフィ（LaTeXの代替） |
| **Pandoc** | 3.x | Markdownパース（Quartoにバンドル） |


## セットアップ

### インストール

**macOS**:
```bash
brew install quarto
```

**Linux (Debian/Ubuntu)**:
```bash
wget https://github.com/quarto-dev/quarto-cli/releases/download/v1.4.555/quarto-1.4.555-linux-amd64.deb
sudo dpkg -i quarto-1.4.555-linux-amd64.deb
```

**Windows**:
```powershell
winget install Posit.Quarto
```

**確認**:
```bash
quarto --version  # ≥1.4.0 であること
```

### プロジェクト構造

```
project/
├── _extensions/           # Quarto拡張機能（テンプレート）
│   └── custom-template/
│       ├── _extension.yml
│       ├── typst-template.typ
│       └── typst-show.typ
├── documents/
│   ├── guide.qmd          # ソースファイル
│   └── guide.pdf          # 生成された出力
└── assets/
    └── logo.png           # 共有アセット
```

### 最小限のドキュメント

`document.qmd` を作成:

```yaml
title: "My Document"
author: "Author Name"
date: 2026-01-17
format:
  typst:
    toc: true
lang: en

# Introduction

Your content here...

## Section 1

More content with **bold** and `code`.

```bash
echo "Code blocks work!"
```

## Section 2

| Column A | Column B |
|----------|----------|
| Data 1   | Data 2   |
```

生成:
```bash
quarto render document.qmd  # document.pdf を作成
```


## ワークフロー

### 1. コンテンツファーストアプローチ

```
1. Markdownでコンテンツを書く（.qmd）
2. メタデータのYAML frontmatterを追加
3. ホットリロードでプレビュー
4. 最終PDFを生成
5. ソースとPDFの両方をバージョン管理
```

### 2. 利用可能なYAMLパラメータ

| パラメータ | 型 | 説明 | 例 |
|-----------|------|-------------|---------|
| `title` | string | メインタイトル | `"Technical Guide"` |
| `subtitle` | string | サブタイトル | `"v2.0 Edition"` |
| `author` | string/array | 著者 | `"John Doe"` |
| `date` | date | ドキュメント日付 | `2026-01-17` |
| `date-format` | string | 表示フォーマット | `"MMMM YYYY"` |
| `toc` | boolean | 目次 | `true` |
| `toc-depth` | number | TOCのレベル（1-3） | `2` |
| `lang` | string | 言語 | `fr` または `en` |
| `section-numbering` | string | 番号フォーマット | `"1.1"` |

### 3. Markdownの機能

**改ページ**:
```markdown
{{< pagebreak >}}
```

**コードブロック**（シンタックスハイライト付き）:
````markdown
```typescript
function hello(): string {
  return "world";
}
```
````

**テーブル**:
```markdown
| Feature | Supported |
|---------|-----------|
| Tables  | ✅        |
| Images  | ✅        |
| Links   | ✅        |
```

**画像**:
```markdown
![Alt text](path/to/image.png){width=50%}
```


## Claude Codeとの統合

### pdf-generatorスキルの使用

スキルを呼び出してガイド付きのPDF生成を行います:

```
/pdf-generator
```

スキルが提供するもの:
- YAML frontmatterを含むテンプレート
- デザインシステムの設定
- よくあるトラブルシューティングの修正
- 生成コマンド

### プロンプト例

**ドキュメントを生成**:
```
Create a technical guide for our API as a Quarto document.
Use the Typst format with a table of contents.
Include sections for: Authentication, Endpoints, Error Codes.
```

**既存のMarkdownを変換**:
```
Convert README.md to a professional PDF.
Add a cover page with title and date.
Use Quarto/Typst format.
```

**テンプレートを作成**:
```
Create a Quarto extension for our company's document style:
- Logo in header
- Custom colors: primary #0f172a, accent #6366f1
- Inter font for body, JetBrains Mono for code
```

### プランモードとの組み合わせ

複雑なドキュメントの場合:
```
[Shift+Tabを押してプランモードに入る]

I need to create a series of 5 technical whitepapers.
Plan the structure:
1. Common template/extension
2. Shared assets
3. Build automation
4. Version management
```

### フックとの組み合わせ

PostToolUseフックを使って編集後に自動でPDFを生成:

```json
// .claude/settings.json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "if echo \"$TOOL_INPUT\" | grep -q '.qmd'; then quarto render \"$FILE\"; fi"
      }
    ]
  }
}
```


## カスタマイズ

### カスタムテンプレート拡張機能

`_extensions/mytemplate/_extension.yml` を作成:

```yaml
title: My Template
author: Your Name
version: 1.0.0
contributes:
  formats:
    typst:
      template: typst-template.typ
      template-partials:
        - typst-show.typ
```

### Typstテンプレート変数

`typst-template.typ` 内:

```typst
// カラー
#let primary = rgb("#0f172a")      // ダークテキスト
#let secondary = rgb("#334155")    // ライトテキスト
#let accent = rgb("#6366f1")       // ハイライト

// タイポグラフィ
#set text(
  font: ("Inter", "Helvetica Neue", "Arial"),
  size: 11pt,
)

#set par(
  leading: 0.75em,  // 行間
  justify: true,
)

// コードブロック
#show raw.where(block: true): it => {
  block(
    fill: rgb("#f8fafc"),
    stroke: (left: 3pt + accent),
    inset: 10pt,
    radius: 4pt,
    it,
  )
}
```

### calloutボックス

テンプレートで定義:

```typst
#let info(title: "Note", body) = {
  block(
    fill: rgb("#E0F2FE"),
    stroke: (left: 3pt + rgb("#0284C7")),
    inset: 12pt,
    radius: 4pt,
    [*#title*: #body]
  )
}

#let warning(title: "Warning", body) = { ... }
#let success(title: "Success", body) = { ... }
#let danger(title: "Danger", body) = { ... }
```

ドキュメントで使用:
```typst
#info[This is an informational note.]
#warning(title: "Attention")[Check your configuration.]
```


## トラブルシューティング

### クイックチェック

```bash
# Quartoを確認
quarto --version

# 拡張機能が存在するか確認
ls _extensions/*/

# コードブロックのペアを検証（偶数である必要あり）
grep -c '^```' document.qmd

# エンコーディングを確認
file -i document.qmd  # utf-8 と表示されるべき
```

### よくある問題

| 問題 | 症状 | 修正 |
|-------|---------|-----|
| ネストされたコードブロック | コンテンツがブロックから出る | 外側のブロックに4つ以上のバッククォートを使用 |
| テーブルがコードになる | グレーの背景 | 上の ` ``` ` が一致していないか確認 |
| 拡張機能が見つからない | "Extension not found" | `_extensions/` パスを確認 |
| フォント警告 | "unknown font family" | 正常；フォールバックを使用 |
| 特殊文字が壊れる | `?` または文字化け | UTF-8に変換 |

### ネストされたコードブロック

**問題**: 内側のコードブロックが外側のブロックを早期に閉じてしまう。

**解決策**: 外側のブロックにより多くのバッククォートを使用:

`````markdown
````markdown
# 4つのバッククォートの外側ブロック

```bash
echo "3つのバッククォートの内側ブロック"
```

外側のブロックが続く...
````
`````

### 検証スクリプト

```bash
#!/bin/bash
# validate-qmd.sh

for f in *.qmd; do
  count=$(grep -c '^```' "$f")
  if [ $((count % 2)) -ne 0 ]; then
    echo "ERROR: $f has odd code block count ($count)"
  fi
done
```


## 関連情報

- [Quartoドキュメント](https://quarto.org/docs/guide/)
- [Typstドキュメント](https://typst.app/docs/)
- [Quarto + Typstガイド](https://quarto.org/docs/output-formats/typst.html)
- [examples/skills/pdf-generator.md](../../examples/skills/pdf-generator.md) — スキルテンプレート
- [whitepapers/README.md](../../whitepapers/README.md) — 本番例
