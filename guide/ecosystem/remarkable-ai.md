---
title: "reMarkable 2 + AI：ハック、ツール、ワークフロー"
description: "reMarkable 2 の AI 統合完全マップ — MCP サーバー、OCR、Obsidian/Notion パイプライン、自動化"
tags: [mcp, integration, hardware, workflow, remarkable]
---

# reMarkable 2 + AI：ハック、ツール、ワークフロー完全マップ

> **最終確認**: 2026年2月

reMarkable 2 はフルルートアクセス可能な Linux e-ink タブレットです。その「ゼロ気散らし」の哲学は思考ツールとして優れていますが、ネイティブ統合は最小限です。このページでは、AI で機能拡張するために存在するすべてのものを、シンプルなものから技術的なものまで網羅します。

## 目次

1. [remarkable-mcp：ゲームチェンジャー](#1-remarkable-mcp-ゲームチェンジャー)
2. [Ghostwriter：Vision-LLM インターフェース](#2-ghostwriter-vision-llm-インターフェース)
3. [reMarkable → Obsidian 同期](#3-remarkable--obsidian-同期)
4. [カスタム OCR + AI パイプライン](#4-カスタム-ocr--ai-パイプライン)
5. [SSH アクセスとコミュニティツール](#5-ssh-アクセスとコミュニティツール)
6. [活用しきれていないネイティブ機能](#6-活用しきれていないネイティブ機能)
7. [API と公式デベロッパーポータル](#7-api-と公式デベロッパーポータル)
8. [Zapier 自動化](#8-zapier-自動化)
9. [Read-it-later：Web → reMarkable](#9-read-it-later-web--remarkable)
10. [会議メモ → AI サマリー](#10-会議メモ--ai-サマリー)
11. [Zotero → reMarkable（研究）](#11-zotero--remarkable-研究)
12. [AI アシストホワイトボードとしてのスクリーン共有](#12-ai-アシストホワイトボードとしてのスクリーン共有)
13. [カスタムアプリと楽しいハック](#13-カスタムアプリと楽しいハック)
14. [構築すべき AI 拡張ワークフロー](#14-構築すべき-ai-拡張ワークフロー)
15. [どこから始めるか](#15-どこから始めるか)

---

## 1. remarkable-mcp：ゲームチェンジャー

**ROI：最大 | 労力：中程度 | 接続：USB 経由の SSH（クラウド不要）**

Sam Morrow が、reMarkable を Claude Code、VS Code Copilot、MCP 対応のあらゆる AI アシスタントに直接接続する **MCP サーバー**を作成しました。

| 属性 | 詳細 |
|---------|---------|
| **リポジトリ** | https://github.com/SamMorrowDrums/remarkable-mcp |
| **ブログ** | https://sam-morrow.com/blog/building-an-mcp-server-for-remarkable |
| **接続** | USB 経由の SSH — クラウドなし、サブスクリプションなし |
| **言語** | Python（FastMCP） |

### できること

- **タイプされたテキストのネイティブ抽出**（Type Folio / 仮想キーボード）— OCR なしで即時
- **手書き OCR** — Google Cloud Vision 経由（月 1000 リクエスト無料）
- **ライブラリ全体のスマート検索**
- **PDF と EPUB からのテキスト抽出** + アノテーション
- **ドキュメントの完全トラバース**

### なぜ第1位なのか

「1月15日の会議でXについて何をメモしたか？」と Claude に聞くと、手書きのメモを検索してくれます。reMarkable が**クエリ可能なセカンドブレイン**になります。

### 技術スタック

```
FastMCP + rmscene（ネイティブ .rm パース）+ PyMuPDF（PDF）
+ Google Cloud Vision（OCR）+ Paramiko（SSH）
```

### クイックインストール

```bash
# 1. reMarkable で SSH を有効にする
# Settings → Help → Copyrights and licenses → IP + root パスワード

# 2. リポジトリをクローン
git clone https://github.com/SamMorrowDrums/remarkable-mcp
cd remarkable-mcp && pip install -e .

# 3. Claude Code に追加
# ~/.claude.json または "claude mcp add" 経由
```

### Claude Code での設定

```json
{
  "mcpServers": {
    "remarkable": {
      "command": "python",
      "args": ["-m", "remarkable_mcp"],
      "env": {
        "REMARKABLE_HOST": "10.11.99.1",
        "REMARKABLE_PASSWORD": "<root-password>"
      }
    }
  }
}
```

---

## 2. Ghostwriter：Vision-LLM インターフェース

**ROI：実験的 | 労力：低（コピーする Rust バイナリ1つ）**

| 属性 | 詳細 |
|---------|---------|
| **リポジトリ** | https://github.com/awwaiid/ghostwriter |
| **モデル** | GPT-4o Vision |
| **HN ディスカッション** | https://news.ycombinator.com/item?id=42979986 |

### コンセプト

reMarkable にプロンプトを手書きします。Vision-LLM（GPT-4o）が書いた内容とスケッチを読み取り、**タブレット上に直接**返答します。

### インストール

```bash
# 1. コンパイル済み Rust バイナリをダウンロード
scp ghostwriter root@10.11.99.1:/home/root/

# 2. SSH + 起動
ssh root@10.11.99.1
chmod +x ghostwriter && ./ghostwriter
```

### サポートされているインタラクション

- 手書き認識
- スケッチ分析（ワイヤーフレーム、図表）
- 小さなアイコン言語
- ジェスチャー

### 具体的なユースケース

アーキテクチャ図を描いて「これを最適化して」と書くと、LLM がビジュアルで分析して応答します。ペンによる人間-AI インタラクションの魅力的なプロトタイプです。

**正直な限界**：reMarkable のネイティブ描画アプリは最小限です（返答にテキストを自由に配置できない）。

---

## 3. reMarkable → Obsidian 同期

**ROI：Obsidian ユーザーには高い | 労力：低〜中程度**

### オプション A：Scrybble（最も機能が充実）

| 属性 | 詳細 |
|---------|---------|
| **サイト** | scrybble.ink |
| **Obsidian プラグイン** | コミュニティプラグイン（Vault 設定） |
| **ホスティング** | セルフホストまたは Scrybble サーバー |
| **ディスカッション** | https://forum.obsidian.md/t/scrybble-sync-plugin/103194 |

**できること：**

- ノートブック、PDF、ePub → Obsidian Vault に同期
- PDF/ePub ハイライトを Markdown として抽出
- タイプされたテキストを Markdown として抽出
- ノートブックを Vault 内で PDF として完全レンダリング
- タグ付きのページ単位整理

**ユースケース**：学術研究、Obsidian 検索をバックエンドに持つ会議でのメモ取り。

### オプション B：カスタムクラウド同期プラグイン

- **デモ**：https://www.youtube.com/watch?v=EsRdi8J9Cnc
- コマンド "remarkable insert" → reMarkable クラウドからファイルをプル
- `rm/` フォルダ内の PDF → Obsidian ノートに埋め込み
- タブレットで変更すると自動的に再取得

---

## 4. カスタム OCR + AI パイプライン

**ROI：カスタムワークフロー向けに高い | 労力：中〜高**

### rmirror + Claude API（推奨パターン）

ソース：https://news.ycombinator.com/item?id=47110872（2026年2月）

**コンセプト**：macOS バックグラウンドエージェントが：
1. reMarkable からノートブックを同期
2. Claude API で OCR（コンテキスト付き手書き認識に Tesseract より優れる）
3. 転写されたメモを検索可能なページとして Notion にプッシュ

**Claude が OCR で Tesseract より優れる理由**：Claude はコンテキストを理解し、歪んだ文字を修正し、リストや表を自動的に構造化します。

### DIY パイプライン

```
reMarkable → SSH/USB
  → .rm ファイルを抽出
  → rmscene パース（Type Folio の場合はネイティブテキスト）
  → Claude Vision API（手書きページのスクリーンショット）
  → 構造化テキスト + 自動タグ
  → API 経由で Notion/Obsidian/GitHub へ
```

### パースツール

| ツール | 用途 | リンク |
|-------|-------|------|
| **rmscene** | .rm ファイルのネイティブパース | https://github.com/ricklupton/rmscene |
| **rmc** | .rm → SVG/PNG に変換 | https://github.com/ricklupton/rmc |
| **rmapi** | Go 製のクラウド API インターフェース | https://github.com/juruen/rmapi |

---

## 5. SSH アクセスとコミュニティツール

**他のすべての不可欠な基盤**

### SSH を有効にする

```bash
# タブレットのインターフェース経由：
# Settings → Help → Copyrights and licenses
# → 表示される：IP + root パスワード

# USB（直接接続）
ssh root@10.11.99.1

# WiFi（有効化後）
rm-ssh-over-wlan on
# または "Simply Customize It" 経由
```

### 必須ツール

| ツール | 用途 | リンク |
|-------|-------|------|
| **RMHacks/xovi** | rM1/2/Paper Pro 向け MOD フレームワーク | https://www.nilorea.net/2025/08/11/latest-rmhacks-with-xovi-for-remarkable-1-2-paper-pro/ |
| **Simply Customize It** | 機能の切り替え GUI（WLAN SSH など） | サードパーティアプリ |
| **ReMy** | SSH 経由のドキュメントのブラウズ/プレビュー/エクスポート GUI（クラウド不要） | https://github.com/bordaigorl/remy |
| **rmirro** | タブレット ↔ ローカルフォルダの双方向 PDF 同期 | https://github.com/hersle/rmirro |
| **reStream** | Mac/PC に reMarkable の画面をストリーミング | https://github.com/rien/reStream |
| **KOReader** | 代替リーダー（より多くのフォーマット、カスタマイズ可能） | SSH 経由 |
| **reGitable** | git 経由の自動バックアップ | awesome-reMarkable |

### カスタムテンプレート

```bash
# SVG テンプレートを作成 → SSH でコピー
scp mon-template.svg root@10.11.99.1:/usr/share/remarkable/templates/

# templates.json を編集して登録
ssh root@10.11.99.1 'vi /usr/share/remarkable/templates/templates.json'
```

**生成ツール**：ReCalendar.me、Remarkable Grid Generator、Remarkably Planner Builder

---

## 6. 活用しきれていないネイティブ機能

**労力：ゼロ | Connect に含まれる（約月6ユーロ）**

| 機能 | 用途 |
|---------|-------|
| **手書き変換** | 選択 → 変換 → 任意のアプリにコピー＆ペースト |
| **クラウド同期** | Google Drive、Dropbox、OneDrive |
| **Slack に送信** | 会議メモを直接チャンネルに共有 |
| **手書き検索**（ベータ AI） | 過去の手書きメモを検索 |
| **スクリーン共有** | PC で画面を共有（プレゼンテーション、会議） |
| **メールに送信** | PDF または PNG として送信 |

**ヒント**：手書き → テキスト変換は孤立した単語には良く機能しますが、密な筆記体の文章には劣ります。変換には印刷体を優先してください。

---

## 7. API と公式デベロッパーポータル

| リソース | リンク |
|-----------|------|
| **デベロッパーポータル** | https://developer.remarkable.com |
| **クラウド API ドキュメント** | https://github.com/splitbrain/ReMarkableAPI |
| **コミュニティガイド** | https://remarkable.guide/ |
| **rmfakecloud** | セルフホストクラウド（Connect サブスクリプション不要） |

**OS**：Linux（Codex）、フルSSHルートアクセス、GPL準拠。クロスコンパイラツールチェーンによりネイティブカスタムアプリのデプロイが可能。

**rmfakecloud**：reMarkable クラウドのオープンソース代替で、同期をセルフホストして Connect サブスクリプションを不要にします。

---

## 8. Zapier 自動化

**ROI：中程度 | 労力：低 | コード不要**

**メカニズム**：reMarkable → メール（my@remarkable.com）→ Zapier が傍受 → 自動アクション

### 送信先として可能なもの

Google Drive、Asana、ClickUp、Trello、Slack、WordPress、Evernote、Notion

### 無料プラン

- 月 100 タスク
- 2ステップ Zap
- 15分ごとにチェック

### 具体的なワークフロー

```
会議メモ → Google Drive に自動アップロードされた PDF
スケッチ → Slack チャンネルに送信されたファイル
アクションアイテム → Asana/ClickUp で作成されたタスク
```

**ソース**：https://myremarkable.substack.com/p/integrating-remarkable

---

## 9. Read-it-later：Web → reMarkable

**ROI：読書には高い | 労力：ほぼゼロ**

| ツール | 説明 |
|-------|-------------|
| **Chrome 拡張「Read on reMarkable」** | 任意の Web ページを保存 → タブレットに EPUB/PDF（広告除去） |
| **Goosepaper** | RSS フィード + ニュース + 日刊 Wikipedia → e-ink フォーマット |
| **remarkable_news** | 日々のニュース/漫画/画像をスクリーンセーバーとして |
| **Instapaper 回避策** | 記事を EPUB としてダウンロード → デスクトップアプリでインポート |

**PDF オプション**：拡張機能を右クリック → "Read on reMarkable as PDF"（アノテーション用に余白調整可能）。

---

## 10. 会議メモ → AI サマリー

**ROI：高い | 労力：非常に低い**

### 手動ワークフロー（MCP なし）

```
1. 会議中に手書きでメモ
2. reMarkable モバイルアプリでスクリーンショット（またはクラウド同期）
3. Claude/ChatGPT に画像をアップロード
4. プロンプト：「このメモを要約し、締め切りと担当者を含むアクションアイテムを抽出して」
```

### MCP ワークフロー（remarkable-mcp インストール済み）

```
Claude、今日の会議のメモを要約して
→ Claude が SSH でファイルを取得
→ 必要に応じて OCR
→ 直接、構造化サマリーを生成
```

**MCP の利点**：スクリーンショットとアップロードのステップをスキップ。Connect サブスクリプションなしでも動作します。

### 推奨テンプレート

Paper Pro Move Meeting Notebook：60 回の会議分、会議ごとに5ページがリンク（概要 + メモ + アクションアイテム + フォローアップ）。

---

## 11. Zotero → reMarkable（研究）

**ROI：論文を読む場合に高い | 労力：中程度**

| ツール | 用途 |
|-------|-------|
| **Zotero2reMarkable Bridge** | ハイライトサポート付きで Zotero から PDF を同期 |
| **KOReader + Toltec + Zotero プラグイン** | 2段組 PDF のより良い読書、双方向同期 |
| **sync_zotero_remarkable** | より軽量な代替手段 |

**正直な限界**：reMarkable はクローズドシステムです。Zotero 統合には回避策が必要です。ネイティブ Zotero を持つ Android e-reader ほどスムーズではありません。機能しますが、摩擦があります。

---

## 12. AI アシストホワイトボードとしてのスクリーン共有

**ROI：プレゼンテーション/ファシリテーション | 労力：ゼロ（Connect のネイティブ機能）**

- **スクリーン共有**：ライブの書き込みが外部画面/バーチャル会議に表示される
- **レーザーポインター**：画面上部近くにスタイラスを近づけるとレーザーポインターが有効に
- **コンボワークフロー**：スクリーン共有 + 同僚がメモをリアルタイムで ChatGPT に送信 = 拡張ホワイトボード

**価格**：Connect に含まれる（米国 約年30ドル、EU 約月6ユーロ）。

---

## 13. カスタムアプリと楽しいハック

| アプリ/ハック | 説明 |
|----------|-------------|
| **Ephemeris** | カレンダーから生成される日次アジェンダ（Python） |
| **Remarcal** | Google/Outlook/Apple カレンダー → reMarkable に同期 |
| **reMarkable keywriter** | 気散らしゼロのキーボードメモアプリ |
| **remarkable-wikipedia** | オフライン Wikipedia リーダー |
| **whiteboard-hypercard** | ライブコラボレーション、共有描画 |
| **NetSurf** | 最小限のウェブブラウザ（SSH 経由） |
| **pdf2remarkable** | コマンドラインからクラウドに PDF をアップロード |
| **send-to-remarkable** | メールでドキュメントをアップロード（send-to-Kindle スタイル） |
| **libreMarkable** | ネイティブアプリ開発フレームワーク |
| **oxide/remux/draft** | マルチタスク用ランチャー |
| **latex-yearly-planner** | LaTeX で生成される年間プランナー |

**完全なカタログ**：https://github.com/reHackable/awesome-reMarkable

---

## 14. 構築すべき AI 拡張ワークフロー

まだパッケージ化されていませんが、利用可能なブロックで実現可能なワークフローです。

### A. AI 分析付きジャーナル

```
毎晩 → reMarkable に1ページの振り返りを書く
→ remarkable-mcp + Claude → パターン、感情、意思決定の週次分析
→ 出力：接続グラフ付きの Obsidian へのインサイト
```

### B. アシスト付き受信トレイ処理

```
reMarkable で読み、アノテーションした論文/記事
→ Claude Vision 経由の OCR → 構造化サマリー
→ 自動タグ + Obsidian/Notion への分類
```

### C. スケッチ→コード

```
reMarkable に UI ワイヤーフレームを描く
→ スクリーンショット → Claude Vision → HTML/React コード
```

### D. 自動フラッシュカード

```
reMarkable での講義/読書メモ
→ remarkable-mcp → Claude がキーコンセプトを抽出
→ Anki フラッシュカードを自動生成
```

### E. 自動デイリースタンドアップ

```
毎朝書いた TODO（カスタムテンプレート）
→ OCR → 自動フォーマットされた Slack/メール
→ 一日の終わりに：アイテムをチェック、差分を送信
```

### F. ブレインストーム → マインドマップ

```
自由にアイデアを走り書き
→ Claude Vision が空間レイアウト + テキストを分析
→ 構造化マインドマップを生成（Mermaid/Markmap）
```

---

## 15. どこから始めるか

### フェーズ1 — 今週末（2時間）

1. Settings → Help → Copyrights and licenses 経由で SSH を有効にする
2. **remarkable-mcp** をインストールして Claude Code に接続
3. テスト：Claude にメモを検索するよう依頼

### フェーズ2 — 翌週

4. Obsidian を使っているなら → Scrybble をインストール
5. **Ghostwriter** をテスト（インストール10分、楽しさ保証）

### フェーズ3 — さらに深く進みたいとき

6. Claude Vision API でカスタム OCR パイプラインを構築
7. Connect サブスクリプション不要のために rmfakecloud を探る

---

## ソース

**GitHub プロジェクト**

- https://github.com/SamMorrowDrums/remarkable-mcp（MCP サーバー、2025年11月）
- https://github.com/awwaiid/ghostwriter（Vision-LLM インターフェース）
- https://github.com/reHackable/awesome-reMarkable（コミュニティカタログ）
- https://github.com/hersle/rmirro（クラウドなし同期）
- https://github.com/bordaigorl/remy（SSH GUI）
- https://github.com/rien/reStream（スクリーンストリーミング）
- https://github.com/splitbrain/ReMarkableAPI（クラウド API ドキュメント）
- https://github.com/ricklupton/rmscene（ネイティブ .rm パース）

**記事とディスカッション**

- https://sam-morrow.com/blog/building-an-mcp-server-for-remarkable
- https://news.ycombinator.com/item?id=47110872（rmirror + Claude OCR、2026年2月）
- https://news.ycombinator.com/item?id=42979986（Ghostwriter HN）
- https://news.ycombinator.com/item?id=46099997（Hacking reMarkable 2、HN 2025）
- https://sgt.hootr.club/blog/hacking-on-the-remarkable-2/（SSH ハッキングガイド）
- https://myremarkable.substack.com/p/integrating-remarkable（Zapier 統合）

**Obsidian**

- https://forum.obsidian.md/t/scrybble-sync-plugin/103194
- https://www.youtube.com/watch?v=EsRdi8J9Cnc（クラウド同期デモ）

**公式**

- https://developer.remarkable.com（デベロッパーポータル、SDK、API）
- https://remarkable.guide/（コミュニティガイド）
