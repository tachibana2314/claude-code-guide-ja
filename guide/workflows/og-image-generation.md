# AstroでダイナミックOGイメージを生成する

古くなった静的PNGを管理する代わりに、ビルド時にソーシャルプレビュー画像を自動生成します。Twitter/X、LinkedIn、Slackでのシェア時に、常に正確で最新の情報が表示されます。

## なぜやるべきか

静的OGイメージは古くなります。200番目のテンプレートを追加した日やGitHubスターが1kを超えた日も、ソーシャルプレビューには古い数字が表示されたままです。ダイナミック生成はこの問題を一度で解決し、永続的に正確な状態を保ちます。

以下のパターンでは、Satori（Vercel）を使ってReactライクなツリーをSVGにレンダリングし、resvgでPNGに変換します。Astroのビルド時に実行されるため、ランタイムコストゼロ、外部サービス不要です。

## スタック

| パッケージ | 役割 |
|---------|------|
| `satori` | JSXライクなオブジェクトツリーをSVGにレンダリング |
| `@resvg/resvg-js` | SVGをPNGに変換（Rust製、高速） |
| `@fontsource/inter` | ローカルフォントファイル（woff1形式が必要） |

## セットアップ

```bash
pnpm add satori @resvg/resvg-js @fontsource/inter
```

`src/pages/og-image.png.ts` にファイルを作成します。Astroは自動的に `/og-image.png` でサーブします。

レイアウトから参照します:

```html
<meta property="og:image" content="/og-image.png" />
<meta name="twitter:image" content="/og-image.png" />
```

すぐに使えるテンプレートはこちら: [`examples/scripts/og-image-astro.ts`](../../examples/scripts/og-image-astro.ts)

## パターン

```typescript
import type { APIRoute } from 'astro'
import satori from 'satori'
import { Resvg } from '@resvg/resvg-js'
import { readFileSync } from 'fs'
import { resolve, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))

export const GET: APIRoute = () => {
  const fontData = readFileSync(
    resolve(__dirname, '../../node_modules/@fontsource/inter/files/inter-latin-400-normal.woff')
  ).buffer as ArrayBuffer

  const svg = satori(
    { type: 'div', props: { style: { /* ... */ }, children: [ /* ... */ ] } },
    { width: 1200, height: 630, fonts: [{ name: 'Inter', data: fontData }] }
  )

  const png = new Resvg(svg, { fitTo: { mode: 'width', value: 1200 } }).render().asPng()

  return new Response(png.buffer as ArrayBuffer, {
    headers: { 'Content-Type': 'image/png' },
  })
}
```

## コンテンツからダイナミックな統計情報

ハードコードする代わりに、ビルド時にコンテンツファイルを数えます:

```typescript
function countQuestions(): number {
  const dir = resolve(__dirname, '../content/questions')
  let total = 0
  for (const cat of readdirSync(dir, { withFileTypes: true })) {
    if (cat.isDirectory()) {
      total += readdirSync(resolve(dir, cat.name))
        .filter(f => f.endsWith('.md')).length
    }
  }
  return total
}
```

自動カウントできる統計情報:
- コンテンツディレクトリ内のMarkdownファイル（質問、記事、ドキュメント）
- データファイル内のYAMLエントリ
- 大きなドキュメントの行数

ハードコードしておく統計情報（手動で更新）:
- GitHubスター数（動的なので `1.1k+` などの控えめなラベルを使用）
- 別リポジトリのテンプレート数
- パフォーマンスベンチマーク

## 注意点

### フォント形式が重要

Satoriは **woff1** または **TTF** を必要とします。woff2やHTMLにリダイレクトするリモートCDN URLでは、エラーなく失敗するかエラーがスローされます。

```typescript
// 正しい — @fontsourceからのローカルwoff1
readFileSync('node_modules/@fontsource/inter/files/inter-latin-400-normal.woff')

// 失敗 — woff2はresvgでサポートされていない
readFileSync('node_modules/@fontsource/inter/files/inter-latin-400-normal.woff2')

// 失敗 — CDNがHTMLを返す可能性がある（リダイレクト、認証ウォール）
await fetch('https://fonts.gstatic.com/s/inter/...')
```

### 静的ファイルがAPIルートを上書きする

AstroのdevサーバーはAPIルートより**先に** `public/` の静的ファイルをサーブします。`public/og-image.png` がある場合、ダイナミックエンドポイントの代わりに常にそれがサーブされます。

**削除してください:**
```bash
rm public/og-image.png
```

プロジェクトルートと `dist/` も確認してください — そこにあるファイルもルートを上書きする可能性があります。`curl -I http://localhost:4321/og-image.png` で診断できます: レスポンスに `Last-Modified` ヘッダーがある場合は、APIルートではなく静的ファイルにアクセスしています。

### ブラウザキャッシュ

静的ファイルを削除した後、ハードリフレッシュ（`Cmd+Shift+R`）するか、プライベートウィンドウでテストしてください。ブラウザが古いPNGを積極的にキャッシュしている可能性があります。

### `satori` の新しいバージョンでは同期の扱いが変わった

satoriのバージョンによって `Promise<string>` を返すものと `string` を返すものがあります。`[object Promise]` というPNGが生成される場合は `await` を追加してください:

```typescript
const svg = await satori(tree, options)
```

## テスト

**ローカルプレビュー** — ブラウザで直接アクセス:
```
http://localhost:4321/og-image.png
```

**ソーシャルプレビューシミュレーション** — 本番URLを以下に貼り付け:
- [opengraph.xyz](https://www.opengraph.xyz) — 汎用OGデバッガー
- LinkedIn Post Inspector（`linkedin.com/post-inspector/`） — LinkedInのキャッシュを強制的にリフレッシュ
- Twitter Card Validator（`cards-dev.twitter.com/validator`）

**CIチェック** — リグレッションを検出するために、生成されたPNGファイルサイズが閾値を超えているか確認するビルドステップを追加できます:

```bash
# ビルド後のCI
SIZE=$(wc -c < dist/og-image.png)
if [ "$SIZE" -lt 10000 ]; then
  echo "og-image.png looks too small ($SIZE bytes) — generation may have failed"
  exit 1
fi
```

## バリアント

### パーソナルブランディング（統計グリッドなし）

```typescript
children: [
  { type: 'span', props: { style: { fontSize: '48px', color: '#c0522a' }, children: 'FB.' } },
  { type: 'span', props: { style: { fontSize: '80px', fontWeight: 800, color: '#f5f5f5' }, children: 'Your Name' } },
  { type: 'span', props: { style: { fontSize: '24px', color: '#8b949e' }, children: 'Your tagline here' } },
]
```

### プロジェクトリストバッジ

```typescript
['project-a.com', 'project-b.com', 'project-c.com'].map(label => ({
  type: 'div',
  props: {
    style: { background: '#161b22', border: '1px solid #30363d', borderRadius: '8px', padding: '8px 16px' },
    children: [{ type: 'span', props: { style: { color: '#c0522a' }, children: label } }],
  },
}))
```

### ターミナルスタイルバッジ（CLIツール向け）

```typescript
{
  type: 'div',
  props: {
    style: { background: '#21262d', border: '1px solid #30363d', borderRadius: '20px', padding: '6px 16px', color: '#3fb950', fontFamily: 'monospace' },
    children: '>_ your-cli-tool',
  },
}
```

## 統計情報を同期させる

信頼できる唯一のソースを維持します。OGイメージの統計情報を更新するときは、同じコミットでランディングページのバッジ、READMEなど全ての箇所を更新します。

複数のランディングページを持つプロジェクトでは、各リポジトリを巡回して各統計情報を確認するよう促すスラッシュコマンド `/update-stats-image-landings` を作成します。これによってサイト間のドリフトを防ぎます。
