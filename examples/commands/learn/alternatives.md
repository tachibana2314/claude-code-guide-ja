---
layout: default
title: "代替案の表示"
parent: コマンド
grand_parent: テンプレート
---


# 代替案の表示

同じ問題を解決するための異なるアプローチを比較します。

## 使用法

```
/learn:alternatives              # 現在のコードのアプローチを比較
/learn:alternatives auth         # 認証方法を比較
/learn:alternatives state        # 状態管理オプションを比較
/learn:alternatives --detailed   # 各オプションのコード例を含む
```

## 手順

1. 解決しようとしている**問題を特定**（コンテキストまたは引数から）
2. **3-5つの代替アプローチ**を提示
3. 各アプローチについて説明します:
   - それが何か（1文）
   - いつ使うか
   - トレードオフ（長所/短所）
4. コンテキストに基づいた**推奨事項**を提供
5. オプションで上位の選択肢のコード例を表示

## レスポンスフォーマット

```markdown
## Problem: [解決しようとしていること]

### Approach 1: [名前]

**What**: [1文の説明]

**When to use**:
- [シナリオ 1]
- [シナリオ 2]

**Pros**: [リスト]
**Cons**: [リスト]


### Approach 2: [名前]
...


## Comparison Table

| Criteria | Approach 1 | Approach 2 | Approach 3 |
|----------|------------|------------|------------|
| Complexity | Low | Medium | High |
| Performance | ★★☆ | ★★★ | ★★☆ |
| Bundle size | Small | Medium | Large |
| Learning curve | Easy | Medium | Steep |

## Recommendation

**For your case**: [推奨アプローチ] — [コンテキストに基づいた理由]

**Consider instead if**: [代替シナリオ]
```

## 比較基準

評価する標準基準（問題に応じて調整）:

| 基準 | 説明 |
|----------|-------------|
| **複雑さ** | 実装と保守の難しさ |
| **パフォーマンス** | ランタイム速度、メモリ使用量 |
| **バンドルサイズ** | フロントエンドバンドルへの影響 |
| **学習曲線** | 正しく理解・使用するまでの時間 |
| **柔軟性** | 拡張または変更の容易さ |
| **コミュニティ** | ドキュメント、エコシステム、サポート |
| **テスト容易性** | テストのしやすさ |
| **型安全性** | TypeScript サポートの品質 |

## 深さのモード

### デフォルト
- 3-4つの代替案
- 各オプションの簡単な説明
- 比較表
- 推奨事項

### `--detailed`
- 4-5つの代替案
- 各オプションのコード例
- 詳細なトレードオフ
- マイグレーションの考慮事項
- 実際のケーススタディ

### `--quick`
- 2-3つの代替案
- 各1行
- クイック推奨事項

## セッション例

```
User: I'm using useState for form state. /learn:alternatives

Claude: ## Problem: Managing Form State in React

### Approach 1: Multiple useState

**What**: 各フィールドに個別の useState

**When to use**:
- シンプルなフォーム（5フィールド未満）
- 複雑なバリデーションなし
- フィールド間の依存関係なし

**Pros**: シンプル、依存関係なし、理解しやすい
**Cons**: 多くのフィールドでは冗長、状態が分散


### Approach 2: Single useState with Object

**What**: すべてのフィールドをオブジェクトとして保持する1つの useState

**When to use**:
- 中規模のフォーム（5-10フィールド）
- フォーム全体をリセットする必要がある
- よりきれいなコードが必要

**Pros**: グループ化された状態、簡単なリセット、クリーン
**Cons**: スプレッド演算子が必要、不要な再レンダリングが発生する可能性


### Approach 3: useReducer

**What**: 複雑な状態遷移のためのリデューサーパターン

**When to use**:
- 複雑なバリデーションロジック
- マルチステップフォーム
- undo/redo 機能

**Pros**: 予測可能な更新、複雑なロジックを処理、テスト可能
**Cons**: より多くのボイラープレート、学習曲線


### Approach 4: Form Library (React Hook Form, Formik)

**What**: 専用のフォーム状態管理ライブラリ

**When to use**:
- 大きなフォーム（10フィールド以上）
- 複雑なバリデーション（非同期、クロスフィールド）
- パフォーマンスが重要（多くのフィールド）

**Pros**: 最適化された再レンダリング、バリデーション内蔵、コードが少ない
**Cons**: 依存関係、学習曲線、バンドルサイズ


## Comparison Table

| Criteria | useState | useReducer | React Hook Form |
|----------|----------|------------|-----------------|
| Complexity | Low | Medium | Medium |
| Performance | ★★☆ | ★★☆ | ★★★ |
| Bundle size | 0kb | 0kb | ~8kb |
| Validation | Manual | Manual | Built-in |
| Best for | Simple | Complex logic | Large forms |

## Recommendation

**For your case**: シンプルなログイン/コンタクトフォームなら **useState** のままで。
マルチステップのチェックアウトや管理者フォームを構築するなら、バリデーションとパフォーマンスの利点のために **React Hook Form** を検討してください。

**Consider useReducer if**: undo/redo、複雑なステートマシン、またはリデューサースタイルのテストが必要な場合。
```

## よくある代替案の比較

| トピック | 典型的な代替案 |
|-------|---------------------|
| **状態** | useState, useReducer, Zustand, Redux, Jotai |
| **スタイリング** | CSS Modules, Tailwind, styled-components, CSS-in-JS |
| **データフェッチ** | fetch, axios, React Query, SWR |
| **フォーム** | useState, React Hook Form, Formik |
| **認証** | JWT, sessions, OAuth, magic links |
| **API デザイン** | REST, GraphQL, tRPC, gRPC |
| **テスト** | Jest, Vitest, Testing Library, Cypress |
| **データベース** | PostgreSQL, MySQL, MongoDB, SQLite |

$ARGUMENTS
