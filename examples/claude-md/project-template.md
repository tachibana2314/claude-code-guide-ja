# CLAUDE.md - プロジェクトテンプレート

## プロジェクト概要
<!-- プロジェクトの目的と技術スタックを記述 -->
- **名前**: [プロジェクト名]
- **言語**: TypeScript / Python / Go
- **フレームワーク**: Next.js / FastAPI / Gin
- **データベース**: PostgreSQL / MongoDB

## コーディング規約
- コードは日本語コメント可、変数名は英語
- 関数は単一責任原則に従う
- エラーハンドリングは明示的に（サイレントキャッチ禁止）
- テストは `*.test.ts` / `*.spec.ts` のパターンで配置

## ディレクトリ構造
```
src/
├── components/    # UIコンポーネント
├── hooks/         # カスタムフック
├── lib/           # ユーティリティ
├── pages/         # ページ/ルート
├── services/      # API/ビジネスロジック
└── types/         # 型定義
```

## テスト
- テストランナー: `npm test`
- カバレッジ: `npm run test:coverage`
- E2E: `npm run test:e2e`
- テストは実装の前に書く（TDD推奨）

## Git規約
- Conventional Commits を使用
- PRは小さく保つ（300行以下推奨）
- main/masterへの直接pushは禁止

## 重要なコンテキスト
<!-- Claudeが知っておくべき重要な情報 -->
- 認証は [方式] を使用
- APIのレートリミット: [X] req/min
- デプロイ先: [環境]

@import .claude/rules/testing.md
@import .claude/rules/api-conventions.md
