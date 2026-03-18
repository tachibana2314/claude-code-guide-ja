---
title: "Figma MCPを使ったデザインからコードへのワークフロー"
description: "Figma MCPサーバーを使って1:1のデザインとコードの一致を実現する自動デザインシステム実装"
tags: [workflow, mcp, integration]
---

# Figma MCPを使ったデザインからコードへのワークフロー

> **信頼度**: Tier 2 — ドキュメント化された本番事例研究（Parallel HQ、builder.io）、MCPサーバーの仕様、コミュニティワークフローに基づく。

Figma MCPサーバーを使った自動デザインシステム実装により、プロダクトデザイナーが本番対応の仕様をClaude Codeに引き渡すことができ、1:1のデザインとコードの一致を維持したコンポーネントを実装します。

---

## 目次

1. [要約](#要約)
2. [ドキュメント化されたインパクト](#ドキュメント化されたインパクト)
3. [アーキテクチャ概要](#アーキテクチャ概要)
4. [3層トークン階層](#3層トークン階層)
5. [前提条件](#前提条件)
6. [コアワークフロー](#コアワークフロー)
7. [Code Connectのセットアップ](#code-connectのセットアップ)
8. [サンプルプロンプト](#サンプルプロンプト)
9. [チームへの導入パターン](#チームへの導入パターン)
10. [アンチパターン](#アンチパターン)
11. [実装ロードマップ](#実装ロードマップ)
12. [リソース](#リソース)

---

## 要約

```
デザイナー（Figma Make） → エクスポート（Figma Design） → Claude（Figma MCP） → 本番コード

重要な洞察: デザインシステム = 信頼できる情報源
ClaudeはFigmaからトークン/コンポーネントを直接消費する
実装はデザインの一致を自動的に維持する
```

---

## ドキュメント化されたインパクト

2026年1月の本番事例研究に基づく:

| 指標 | 改善率 | 出典 |
|--------|-------------|--------|
| デザインの不一致 | 62%削減 | Parallel HQ研究 |
| ワークフロー効率 | 78%改善 | builder.ioの事例研究 |
| エンジニアリング時間の節約 | 75日（6ヶ月） | Parallel HQの本番データ |
| 市場投入までの時間 | 56%削減 | マルチ組織の複合データ |
| デザイン技術的負債 | 82%削減 | 実装後の監査 |

**典型的なワークフローのタイミング**:
- 単一フレーム → 本番コンポーネント: 2〜3分
- デザインシステムのドリフト監査: 3週間 → 3分
- トークン更新の伝播: 手動での数時間 → 自動化された数秒

*出典: builder.io/blog/claude-code-figma-mcp-server、parallelhq.com/blog/automating-design-systems-with-ai、composio.dev/blog/how-to-use-figma-mcp-with-claude-code*

---

## アーキテクチャ概要

### フルスタック

```
[Figmaデザインファイル]
    ↓ （変数とスタイル）
[Tokens Studioプラグイン] （任意だが推奨）
    ↓ （JSONエクスポート）
[GitHubリポジトリ]
    ↓ （CI/CD）
[Style Dictionaryによる変換]
    ↓ （生成）
[CSSカスタムプロパティ / Tailwind設定]
    ↓ （使用）
[コンポーネントライブラリ]
    ↑ （経由で読み取り）
[Claude Code + Figma MCP]
```

### MCPインテグレーションポイント

Claude CodeはFigma MCPサーバーを通じてFigmaにアクセスします:

```
Claude Code
    ↓ （使用）
Figma MCPサーバー（mcp-server-figma）
    ↓ （認証）
Figmaパーソナルアクセストークン
    ↓ （読み取り）
Figmaファイル（Dev Modeデータ）
```

**Claudeがアクセスできるもの**:
- ファイル構造とフレーム
- カラー/テキスト/エフェクトスタイル
- コンポーネントプロパティ
- 変数（トークン）
- Dev Modeアノテーション
- Code Connectスニペット（設定済みの場合）

**Claudeがアクセスできないもの**:
- トークン権限なしのプライベートファイル
- 編集機能（読み取り専用）
- リアルタイムコラボレーションデータ
- バージョン履歴（現在の状態のみ）

---

## 3層トークン階層

最新のデザインシステムは階層的なトークン構造を使用します。Claude Codeは、Figmaデータを消費する際にこの階層を理解します。

| 層 | 定義 | Figmaでの実装 | コード出力 |
|------|------------|----------------------|-------------|
| **Base** | プリミティブ値 | Figma変数（例: `blue-600: #0066CC`、`spacing-2: 8px`） | CSSカスタムプロパティ（`--blue-600`、`--spacing-2`） |
| **Composite** | 組み合わされたプリミティブ | 変数を参照するコンポーネントの塗り | Tailwind設定またはCSSクラス |
| **Semantic** | コンテキスト上の意味 | コンテキスト変数のエイリアス（例: `color-interactive-primary` → `blue-600`） | コンポーネントのpropsまたはテーマトークン |

### 階層の例

```
Base:
  --color-blue-600: #0066CC
  --spacing-2: 8px
  --radius-md: 4px

Composite:
  --button-padding: var(--spacing-2) var(--spacing-4)
  --button-border-radius: var(--radius-md)

Semantic:
  --interactive-primary: var(--color-blue-600)
  --interactive-primary-hover: var(--color-blue-700)
```

**Claude Codeの動作**: Figmaコンポーネントが与えられると、Claudeは:
1. 参照されている変数（Base層）を抽出する
2. 複合パターン（スペーシング、サイズ）を特定する
3. トークン規約からセマンティックな命名を適用する
4. この階層に一致するコードを生成する

---

## 前提条件

### デザイナー向け

| 要件 | 詳細 |
|-------------|---------|
| **Figmaライセンス** | Dev Modeシート（変数の検査、コードスニペットを有効化） |
| **整理された変数** | トークン管理にFigma変数またはTokens Studioプラグインを使用 |
| **コンポーネント構造** | オートレイアウト、名前付きレイヤー、一貫した命名規則 |
| **フレームの命名** | 説明的なフレーム名（Claudeはこれをコンポーネント名に使用） |

### 開発者向け

| 要件 | 詳細 |
|-------------|---------|
| **Claude Code** | バージョン1.5.0以上（MCPサポート） |
| **Figma MCPサーバー** | `npm install -g @modelcontextprotocol/server-figma` |
| **パーソナルアクセストークン** | FigmaアカウントSettings → Tokensから生成 |
| **MCP設定** | Claude Codeの設定にトークンを設定 |

### MCP設定

Claude CodeのMCP設定（`.claude/mcp.json`または設定UI）に追加:

```json
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-figma"],
      "env": {
        "FIGMA_PERSONAL_ACCESS_TOKEN": "your-token-here"
      }
    }
  }
}
```

**セキュリティに関する注意**: 本番環境では環境変数を使用してください:
```json
{
  "env": {
    "FIGMA_PERSONAL_ACCESS_TOKEN": "${FIGMA_TOKEN}"
  }
}
```

シェルでエクスポートします: `export FIGMA_TOKEN="figd_..."`

---

## コアワークフロー

### ワークフローA: 単一フレーム → 本番コンポーネント

**タイミング**: コンポーネントあたり2〜3分

**ステップ**:

1. **デザイナー**: 適切な変数/スタイルでFigmaにコンポーネントを作成
2. **デザイナー**: FigmaファイルのURLをdev/Claudeと共有
3. **開発者**: Claude Codeにプロンプト:

```
FigmaファイルからButton/Primaryコンポーネントを読み取ってください:
https://www.figma.com/design/FILE_KEY

TypeScriptを使ってReactコンポーネントとして実装してください。
Figma変数を私たちのデザイントークンにマッピングして、スタイリングにはTailwindを使用してください。
FigmaのAutoLayoutの制約に一致するレスポンシブな動作を確保してください。
```

4. **Claude**:
   - Figma MCPを通じてコンポーネントを取得する
   - スタイル、寸法、スペーシングを抽出する
   - 変数をコードトークンにマッピングする
   - FigmaバリアントにマッチするpropsでコンポーネントVを生成する

5. **検証**: `npm run dev` → Figmaとの視覚的比較

**出力例**:
```tsx
// components/Button/Primary.tsx
interface ButtonProps {
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  children: React.ReactNode;
}

export function PrimaryButton({ size = 'md', disabled, children }: ButtonProps) {
  return (
    <button
      className={cn(
        'rounded-md font-medium transition-colors',
        'bg-interactive-primary text-white',
        'hover:bg-interactive-primary-hover',
        'disabled:opacity-50 disabled:cursor-not-allowed',
        {
          'px-3 py-1.5 text-sm': size === 'sm',
          'px-4 py-2 text-base': size === 'md',
          'px-6 py-3 text-lg': size === 'lg',
        }
      )}
      disabled={disabled}
    >
      {children}
    </button>
  );
}
```

---

### ワークフローB: デザインシステムのドリフト監査

**タイミング**: 手動での3週間レビュー → 自動化された3分

**問題**: 時間とともに、コードがデザインシステムから乖離する（マジックナンバー、ハードコードされた色、一貫性のないスペーシング）。

**解決策**: ClaudeがFigmaの信頼できる情報源に対してコードベースを監査する。

**プロンプト**:
```
src/componentsをデザインシステムコンプライアンスについて監査してください。
私たちのFigmaデザインシステムと比較してください:
https://www.figma.com/design/FILE_KEY

レポート:
1. デザイントークンを使っていないハードコードされた色
2. マジックナンバーのスペーシング値
3. Figmaの構造と一致しないコンポーネント
4. レスポンシブパターンの欠如

その後、トークンの置き換えを含む修正案を提案してください。
```

**Claudeの出力**:
```markdown
## デザインシステム監査結果

### 見つかった問題（23件）

#### ハードコードされた色（8件）
- `src/components/Card.tsx:45` → `#0066CC`は`var(--interactive-primary)`にすべき
- `src/components/Header.tsx:12` → `#F3F4F6`は`var(--surface-secondary)`にすべき
...

#### マジックナンバー（11件）
- `src/components/Modal.tsx:23` → `padding: 16px 24px`は`var(--spacing-4) var(--spacing-6)`にすべき
...

#### 構造的な不一致（4件）
- `src/components/Button.tsx` → Figmaに存在する`icon-left`バリアントが欠けている
...
```

---

### ワークフローC: トークン自動化パイプライン

**目標**: Figmaの変数変更がコードに自動的に伝播する。

**アーキテクチャ**:

```
Figma変数
    ↓ (Tokens StudioエクスポートまたはFigma API)
GitHubリポジトリ (tokens.json)
    ↓ (GitHub Actions CI/CD)
Style Dictionaryによる変換
    ↓ (生成)
CSS / Tailwind / プラットフォーム固有トークン
    ↓ (コミットとデプロイ)
本番環境
```

**セットアップ**（一度だけ）:

1. **Tokens Studioプラグイン**: GitHubリポジトリに接続
2. **Style Dictionary設定**: 変換ルールを定義
3. **GitHub Actions**: トークン更新時に自動実行
4. **Claudeの役割**: 生成されたトークンをレビューして検証する

**開発者プロンプト**（CI実行後）:
```
コミットabc1234からのトークン更新をレビューしてください。
新しいトークンを消費するためにコンポーネントの更新が必要かどうか確認してください。
破壊的な変更がある場合は移行ガイドを生成してください。
```

**Claudeの出力**:
```markdown
## トークン更新レビュー（v2.3.0 → v2.4.0）

### 変更点
- 追加: `--spacing-7`、`--spacing-8`（デザインから要求）
- 変更: `--interactive-secondary`の色相が5°シフト（ブランドリフレッシュ）
- 非推奨: `--legacy-blue`（Q3までに削除）

### 影響分析
- 12個のコンポーネントが`--interactive-secondary`を参照 → トークン参照経由で自動更新
- 3個のコンポーネントが非推奨の`--legacy-blue`を使用 → 移行が必要

### 移行が必要
1. `src/components/LegacyButton.tsx:34` → `--legacy-blue`を`--interactive-primary`に置き換え
2. `src/components/OldCard.tsx:67` → 新しいトークンに置き換え
3. `src/utils/theme.ts:12` → テーマのエクスポートを更新

### 移行スクリプト
[Claudeがコードmodまたはfind/replaceスクリプトを生成]
```

---

### ワークフローD: ビジュアルイテレーションループ（Figma + Playwright）

**目標**: Figmaデザインに対する自動ビジュアルリグレッションテスト。

**MCPスタック**: Figma MCP + Playwright MCP

**セットアップ**:
```
Claude Codeがアクセス:
- Figma（デザインの信頼できる情報源）
- Playwright（自動ブラウザテスト）
```

**プロンプト**:
```
Buttonコンポーネントのすべてのバリアントのスクリーンショットを撮ってください。
次のFigmaフレームと比較してください:
https://www.figma.com/design/FILE_KEY → "Button Tests"ページ

ビジュアルの違いを報告してください（色、スペーシング、タイポグラフィ）。
```

**ワークフロー**:
1. ClaudeがFigmaフレームを読み取る（期待される状態）
2. Claudeがコンポーネントのスクリーンショットを撮るためにPlaywrightを使う（実際の状態）
3. Claudeが比較する（ピクセル差分またはビジュアル検査）
4. 修正提案とともに不一致を報告する

**出力例**:
```markdown
## ビジュアルリグレッションレポート

### ✅ 一致（5/7）
- Button/Primary/Default
- Button/Primary/Hover
- Button/Secondary/Default
...

### ❌ 不一致（2/7）

#### Button/Primary/Disabled
- **問題**: コードでは透明度0.4、Figmaでは0.5
- **修正**: `disabled:opacity-50` → `disabled:opacity-40`に更新
- **ファイル**: `src/components/Button.tsx:23`

#### Button/Large
- **問題**: コードでは12px padding、Figmaでは16px
- **修正**: `py-3` → `py-4`（16px）に更新
- **ファイル**: `src/components/Button.tsx:18`
```

---

## Code Connectのセットアップ

**Code Connect**はFigmaのノーコードツールで、デザインコンポーネントをコードスニペットにリンクします。これにより、Claudeが正確なコードを生成する能力が向上します。

### 機能

- デザイナーがFigmaコンポーネントにコード例でアノテーションを付ける
- ClaudeがMCP経由でこれらのアノテーションを読む
- 生成されたコードがチームの規約に自動的に合う

### セットアップ（デザイナー向け）

1. FigmaのDev Mode → コンポーネントを選択 → Code Connectパネル
2. コンポーネントの使われ方を示すコードスニペットを追加:

```tsx
// Figmaでの例のCode Connectアノテーション
<Button variant="primary" size="lg">
  Click me
</Button>
```

3. Claudeは実装を依頼されたときにこれを見て、チームの正確なパターンを使用する

### メリット

| Code Connectなし | Code Connectあり |
|---------------------|-------------------|
| Claudeが汎用コードを生成 | Claudeがチームの規約を使用 |
| prop命名が一貫しない | propsがFigmaバリアントと正確に一致 |
| 手動修正が必要 | 初回から本番対応 |

**参考**: parallelhq.com/blog（Code Connect UIの記事）

---

## 代替: Pencil（IDE ネイティブキャンバス）

**概要**: [Pencil](https://pencil.dev)は無限のデザインキャンバスをClaude Code/Cursor/VSCodeに直接持ち込み、外部ツールへの切り替えをなくしてデザインとコードのワークフローを実現します。

### アーキテクチャ

**コアの革新**: Figma（クラウドベース）やExcalidraw（スタンドアロン）とは異なり、PencilはClaudeとコードが存在するIDEに直接デザインキャンバスを埋め込みます。

```
従来のワークフロー:
Figma（デザイン） → エクスポート → Claude Code → 実装 → 手動同期

Pencilのワークフロー:
IDEキャンバス（デザイン + AIエージェント + コード） → Gitコミット → 継続的な整合性
```

**主要機能**:
- **WebGLキャンバス**: 無限、高パフォーマンス、完全編集可能
- **AIマルチプレイヤーエージェント**: 並行エージェントがデザインを共同処理
- **Git ネイティブ**: `.pen`ファイル（JSON形式）がコードと並んでバージョン管理
- **MCP双方向**: 完全な読み書きアクセス（Figma MCPの読み取り専用ではない）
- **Figmaインポート**: ベクターとスタイルを保持してFigmaから直接コピー&ペースト

### PencilとFigma MCPの比較

| 側面 | Pencil | Figma MCP |
|--------|--------|-----------|
| **場所** | IDE ネイティブ（Cursor/VSCode/Claude Code） | 外部クラウド |
| **形式** | `.pen` JSON（オープン） | 独自バイナリ |
| **バージョン管理** | Git ネイティブ（ブランチ/マージ/履歴） | Figmaクラウドバージョン |
| **AIエージェント** | マルチプレイヤー並行 | MCP経由のシングルスレッド |
| **コラボレーション** | コードファースト（開発者 + デザイナー） | デザインファースト（デザイナー + 開発者） |
| **MCPアクセス** | 双方向（読み書き） | 読み取り専用 |
| **ワークフロー** | 同じ環境でデザイン → コミット → コード | デザイン → エクスポート → 引き渡し → コード |
| **最適な用途** | エンジニア-デザイナー、コードセントリックなチーム | 従来のデザインと開発の分離 |
| **成熟度** | 新興（2026年1月ローンチ） | 成熟（2024年〜） |
| **価格** | 現在無料、将来は未定 | フリーミアム（無料枠あり） |

### Pencilを使う場面

✅ **適している**:
- チームがメイン環境としてCursorまたはVSCode + Claude Codeを使用
- ターミナル/IDEワークフローに慣れているエンジニア-デザイナー
- デザインとコードの密接な整合性が必要なプロジェクト（design-as-codeパラダイム）
- Gitネイティブのデザインバージョン管理を望む（ブランチ保護、ロールバックなど）
- デザイン自動化のために並行AIエージェントを活用したい

⚠️ **慎重に検討する**:
- 従来のデザインチーム（非技術系） → Figmaの方が適している可能性
- エンタープライズSLA/サポートが必要 → Pencilはまだ成熟中
- 50以上のコンポーネントを持つ複雑なデザインシステム → FigmaエコシステムがよりMatured
- チームがCursor/VSCodeを使っていない → 互換性が限られる

### セットアップ

1. **Pencil拡張をインストール**:
   - [pencil.dev](https://pencil.dev)にアクセス
   - Cursor/VSCode/Claude Codeのインストール手順に従う
   - アカウントを作成（現在無料）

2. **最初のキャンバスを作成**:
   ```bash
   # IDEを開き、Pencil拡張を起動
   # リポジトリに新しい.penファイルを作成
   # 無限キャンバスでデザイン
   ```

3. **Gitワークフロー**:
   ```bash
   git add design/homepage.pen
   git commit -m "feat(design): add homepage hero section"
   git push
   ```

4. **Claudeインテグレーション**:
   - ClaudeはMCP経由で.penファイルを読める
   - プロンプト: 「design/components.penからButtonコンポーネントを実装してください」
   - Claudeがデザイン仕様を抽出してコードを生成

### プロンプト例

```
design/homepage.penから「Hero Section」を読み取ってください。

以下でReactコンポーネントとして実装してください:
- キャンバスのブレークポイントに一致するレスポンシブな動作
- デザインからのアニメーション（フェードイン、スライドアップ）
- キャンバスで指定された通りの正確なコピー
- スタイリングにはTailwindを使用

デザインの仕様と完全に一致させてください。
```

### 創業者と支援

**Tom Krcha**（CEO、Pencil）:
- Adobe XDの共同創業者（2014〜2018年）、Adobeで10年勤務
- 以前のイグジット: Alter Avatars（Googleが買収）、Around（Miroが買収）
- 14年以上の開発経験

**資金調達**: a16z Speedrun（〜$1M）+ KAYA VC

**トラクション**: ローンチ時に100万回以上の閲覧、Microsoft、Shopify、Uberの幹部を含む数千件のサインアップ。

### 成熟度に関する注意

**⚠️ ステータス**: 2026年1月ローンチ（非常に最近）。初期のシグナルは強いが、ドキュメントとエコシステムはまだ成熟中。

**推奨事項**:
- **本番プロジェクト**: まず1〜2つの重要でない機能でパイロット
- **新しいプロジェクト**: Cursor/Claude Codeを使用するチームには安全に採用可能
- **従来のワークフロー**: Pencilが成熟するまでFigma MCPを使用（3〜6ヶ月）

**モニター**: 価格発表、公開GitHubリポジトリ、成熟したドキュメントは2026年Q2を予定。

---

## サンプルプロンプト

### コンポーネント実装
```
私たちのFigmaデザインシステムから「Card/Product」コンポーネントを実装してください:
[FigmaのURL]

要件:
- tailwind.config.tsの既存のデザイントークンを使用する
- FigmaのインタラクションにマッチするHover状態を含める
- すべてのバリアント（default、featured、compact）を実装する
- すべてのpropsにTypeScriptの型を追加する
```

### デザインシステムの拡張
```
デザインチームがFigmaに新しい「Badge」コンポーネントを追加しました:
[FigmaのURL → Badgeフレーム]

以下を生成:
1. すべてのバリアントを持つReactコンポーネント
2. Storybookストーリー
3. propsの組み合わせの単体テスト
4. デザインシステムのドキュメントを更新
```

### トークンの検証
```
私たちのTailwind設定のカラートークンを
Figmaの変数と比較してください: [FigmaのURL]

不一致を報告して更新スクリプトを生成してください。
```

### レスポンシブ実装
```
Figmaから「Hero」セクションを正確なレスポンシブ動作で実装してください:
[FigmaのURL → Hero/Responsiveフレーム]

Figmaには3つのブレークポイントが設定されています。正確に一致させてください。
```

### アクセシビリティ監査
```
Figmaの仕様に対して「Modal」コンポーネントの実装をレビューしてください:
[FigmaのURL]

確認:
- フォーカス管理がFigmaのインタラクションフローと一致する
- カラーコントラストがWCAG AAを満たす（FigmaにはコントラストCheckerがある）
- キーボードナビゲーション（Figmaアノテーションでタブ順序を指定）
```

### 引き渡し前のデザインQA
```
「Checkoutフロー」フレームを実装の準備状態についてレビューしてください:
[FigmaのURL → Checkout Flowページ]

確認:
- すべてのインタラクティブ状態が定義されている（hover、focus、disabled、error）
- 変数が一貫して使用されている（マジックバリューなし）
- AutoLayout制約が実装可能
- 本番コードに必要なものが不足していないか？
```

### マルチコンポーネントのアトミック実装
```
アトミックデザインシステムのコンポーネントを順番に実装してください:

1. アトム: [FigmaのURL → Atomsページ]
   - Button、Input、Label、Badge

2. モレキュール: [FigmaのURL → Moleculesページ]
   - FormField（Label + Input + Error）
   - SearchBar（Input + Button）

3. オーガニズム: [FigmaのURL → Organismsページ]
   - LoginForm（モレキュールを使用）

各レベルが下位のレベルからのみインポートすることを確認してください。
```

---

## チームへの導入パターン

### プロダクトデザイナー向け

**新しいワークフロー**:
1. 適切な変数構造でFigmaでデザインする
2. 迅速なプロトタイピングにFigma Makeを使用する
3. Dev Modeを有効にしてFigma Designにエクスポートする
4. ファイルURLと特定のフレームをdev チームと共有する
5. Claudeがデザインを消費 → 実装を生成する
6. デザイナーがコードを読まずに視覚的に実装をレビューする

**重要な洞察**: デザイナーはコードを学ぶ必要はありません。実装はFigmaとの視覚的比較によってレビューします。

### 開発者向け

**新しいワークフロー**:
1. デザイナーからFigma URLを受け取る
2. FigmaソースからClaudeに実装を依頼する
3. アーキテクチャの適合性のために生成されたコードをレビューする
4. 視覚的比較を実行する（PlaywrightまたはManual）
5. 本番対応のコンポーネントをコミットする

**節約される時間**: 手動のピクセルパーフェクトな実装をスキップ。レイアウトのマッチングではなく、ロジックに集中する。

### プロダクトマネージャー向け

**新しい機能**: Figmaフレームに基づいてデザイン実装の見積もりを依頼する。

**PMのためのプロンプト**:
```
「ダッシュボードリデザイン」Figmaファイルをレビューしてください:
[FigmaのURL]

実装の複雑さを見積もってください:
- 新しいコンポーネントはいくつ必要か？
- 既存のコンポーネントはどれが再利用できるか？
- 技術的なブロッカーはあるか？

開発実装の大まかなタイムラインを提供してください。
```

Claudeの出力:
```markdown
## 実装分析

### スコープ
- 合計12フレーム
- 4つの新しいコンポーネント（DataTable、MetricCard、FilterPanel、DateRangePicker）
- 8つの既存コンポーネントを再利用

### 複雑さの評価
- **Low**: MetricCard（既存のCardに類似、1〜2時間）
- **Medium**: FilterPanel（マルチセレクトロジック、4〜6時間）
- **High**: DataTable（ソート、ページネーション、仮想化、2〜3日）
- **High**: DateRangePicker（サードパーティライブラリの統合、1〜2日）

### 技術的考慮事項
- DataTableはサーバーサイドページネーションのためにバックエンドAPIが必要
- DateRangePicker: date-fns vs dayjs vs nativeを評価
- FilterPanelの状態管理（ローカル vs グローバル）

### 推定タイムライン
- 開発: 5〜7日
- コードレビュー + QA: 2日
- 合計: 1.5〜2週間
```

---

## アンチパターン

| ❌ アンチパターン | なぜ失敗するか | ✅ 正しいアプローチ |
|----------------|-------------|-------------------|
| **手動デザインの転記** | エラーが出やすく、時間がかかり、ドリフトは避けられない | MCP経由でClaudeがFigmaを直接読む |
| **仕様としてのスクリーンショット** | トークンデータなし、インタラクティビティなし、曖昧 | Figma URLを共有して、Claudeが構造化データにアクセスする |
| **ハードコードされた値** | デザインシステムが更新されると壊れる | Figma変数からのデザイントークンを使用する |
| **デザイナーがコードを書く** | デザイナースキルの非効率な使用 | デザイナーがデザイン → Claudeがコード → 開発者がレビュー |
| **開発者がスペーシングを推測する** | デザインシステムとの不一致 | ClaudeがFigmaから正確な値を抽出する |
| **Code Connectアノテーションなし** | 汎用コード出力 | 一度アノテーションを付ければ → Claudeがチームの規約を使用 |
| **視覚的比較のスキップ** | 実装のドリフト | 常にFigmaのソースに対して確認する |
| **トークン命名の不一致** | Figma変数 ≠ コードトークン | 命名規則を確立し、Style Dictionaryを使用する |
| **レスポンシブ仕様の欠如** | 開発者がブレークポイントを推測する | Figmaにはレスポンシブフレームがある → Claudeが正確な仕様を読む |
| **単一層トークン** | 柔軟性なし、テーマが難しい | 3層階層を使用する（base/composite/semantic） |

---

## 実装ロードマップ

### フェーズ1: 基盤（第1〜2週）

**目標**: 基本的なFigma → Claude → Codeパイプライン

- [ ] Figma MCPサーバーをインストール
- [ ] パーソナルアクセストークンを設定
- [ ] 接続テスト: ClaudeがパブリックFigmaファイルを読む
- [ ] デザインシステムの規約を含むプロジェクトCLAUDE.mdを作成
- [ ] 3〜5つのシンプルなコンポーネントを実装（Button、Input、Badge）
- [ ] 視覚的QAプロセスを確立（手動比較）

**成功基準**:
- ClaudeがFigma URLからコンポーネントを生成する
- 出力がデザインと視覚的に一致する
- 開発チームがワークフローを理解する

---

### フェーズ2: スケーリング（第3〜4週）

**目標**: 完全なデザインシステム実装 + 自動化

- [ ] Figmaライブラリから20以上のコンポーネントを実装
- [ ] トークン自動化をセットアップ（Tokens Studio + Style Dictionary）
- [ ] コンポーネントテストスイートを作成（Storybook + ビジュアルリグレッション）
- [ ] 変数の衛生管理についてデザイナーをトレーニング
- [ ] チームの規約をCLAUDE.mdに文書化
- [ ] 最初のデザインシステムドリフト監査を実行

**成功基準**:
- UIコンポーネントの80%以上が自動生成される
- トークンの更新が自動的に伝播する
- デザイナーが引き渡しプロセスに自信を持つ

---

### フェーズ3: オーケストレーション（第5週以降）

**目標**: マルチMCPワークフロー + 継続的な同期

- [ ] 自動ビジュアルテストのためにPlaywright MCPを統合
- [ ] デザインとコードの一致チェックのためのCI/CDをセットアップ
- [ ] Figma → GitHub → 本番パイプラインを作成
- [ ] デザインシステムのガバナンスを実装（リンティング、監査）
- [ ] 非開発者がClaude実装をトリガーできるようにする（チケット、Slack）
- [ ] メトリクスを測定する（TTM、不一致率、開発者の節約時間）

**成功基準**:
- デザインの更新 → 1日以内に本番環境
- 手動デザイン転記ゼロ
- チームの速度向上が測定可能

---

## リソース

### 公式ドキュメント

- **Figma MCPサーバー**: [@modelcontextprotocol/server-figma](https://github.com/modelcontextprotocol/servers/tree/main/src/figma)（GitHub）
- **Figmaデベロッパードキュメント**: [figma.com/developers](https://www.figma.com/developers)
- **Style Dictionary**: [amzn.github.io/style-dictionary](https://amzn.github.io/style-dictionary/)
- **Tokens Studioプラグイン**: [tokens.studio](https://tokens.studio/)

### 事例研究とチュートリアル

- **builder.io**: "Claude Code + Figma MCP Server: AI Design-to-Code Workflow"（2026年1月）
  - [builder.io/blog/claude-code-figma-mcp-server](https://www.builder.io/blog/claude-code-figma-mcp-server)
  - 本番メトリクス、ワークフロー例

- **Vladimir Siedykh**: "Multi-MCP Orchestration with Claude Code"
  - [vladimirsiedykh.com/blog/claude-code-mcp-workflow](https://vladimirsiedykh.com/)
  - Figma + Playwright + Linearのインテグレーション

- **Parallel HQ**: "Automating Design Systems with AI"
  - [parallelhq.com/blog/automating-design-systems-with-ai](https://parallelhq.com/)
  - 75日の節約、Code Connect UIガイド

- **Composio**: "How to Use Figma MCP with Claude Code"
  - [composio.dev/blog/how-to-use-figma-mcp-with-claude-code](https://composio.dev/)
  - トークン階層パターン、セットアップガイド

### コミュニティリソース

- **Figmaコミュニティ**: 「Design System Tokens」でスターターテンプレートを検索
- **MCPレジストリ**: [mcp.run](https://mcp.run/) → Figmaサーバーの例
- **Discord**: AnthropicのDiscord → #mcp-serversチャンネル

### 関連するワークフロー

- [画像の操作](../ultimate-guide.md#24-working-with-images) — Claude Codeの画像分析
- [ASCIIアートとワイヤーフレーム](../ultimate-guide.md#wireframing-tools) — 低忠実度のデザインイテレーション
- [Playwright MCP](../ultimate-guide.md#playwright-mcp) — ビジュアルリグレッションテスト

---

## 関連情報

- [../ultimate-guide.md#figma-mcp](../ultimate-guide.md) — メインガイドのFigma MCPセクション
- [examples/claude-md/product-designer.md](../../examples/claude-md/product-designer.md) — プロダクトデザイナーのCLAUDE.mdテンプレート
- [../cheatsheet.md](../cheatsheet.md) — クイックリファレンス
