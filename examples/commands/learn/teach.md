---
layout: default
title: "教える"
parent: コマンド
grand_parent: テンプレート
---


# 教える

概念を段階的な深さで進めるステップバイステップの説明。

## 使用法

```
/learn:teach React hooks         # React hooks について学ぶ
/learn:teach async/await         # 非同期パターンを理解する
/learn:teach SOLID principles    # 設計原則を学ぶ
/learn:teach --deep SQL joins    # 詳細な説明
```

## 手順

1. 概念の**1文の定義**から始める
2. **なぜ重要か**を説明する（解決する実際の問題）
3. **最小限の例**を示す（可能な限りシンプルなコード）
4. 例の**各部分**をコメントで分解する
5. **実践的な例**を示す（実際のユースケース）
6. 初心者がよくやる**一般的なミス**をハイライト
7. **次に学ぶべき概念**を提案する

## レスポンスフォーマット

```markdown
## [Concept Name]

**In one sentence**: [明確でシンプルな定義]

### Why It Matters

[この概念が解決する問題を1-2文で]

### Minimal Example

\`\`\`[language]
// 最もシンプルなデモンストレーション
[code]
\`\`\`

**Line by line**:
- Line 1: [説明]
- Line 2: [説明]
...

### Practical Example

\`\`\`[language]
// 実際のシナリオ
[code]
\`\`\`

### Common Mistakes

1. **[ミス]**: [なぜ間違っていて、代わりに何をすべきか]
2. **[ミス]**: [なぜ間違っていて、代わりに何をすべきか]

### Key Takeaways

- [要点 1]
- [要点 2]
- [要点 3]

### Learn Next

- [関連概念 1] — [なぜ繋がるか]
- [関連概念 2] — [なぜ繋がるか]


**Practice challenge**: [概念を強化するための小さな練習問題]
```

## 深さのモード

### デフォルト
- 1文の定義
- 1つの最小限の例
- 1つの実践的な例
- 2-3つの一般的なミス

### `--deep`
- 歴史/コンテキストを含む詳細な説明
- 複雑さが増す複数の例
- エッジケースとハマりポイント
- パフォーマンスの考慮事項
- 代替案との比較
- 面接に関連する詳細

### `--quick`
- 定義のみ
- 1つの例
- 追加情報なし

## 適応ルール

### 初心者向け
- 日常生活からのアナロジーを使用する
- 専門用語を避ける（またはすぐに説明する）
- コードにより多くのコメント
- より小さなコード例

### 中級者向け
- 基本的な構文の知識を前提とする
- 「何を」より「なぜ」に焦点を当てる
- トレードオフを含める
- イディオマティックなパターンを示す

### 高度なトピック向け
- 公式ドキュメントを参照する
- 関連する場合は内部実装を議論する
- パフォーマンスへの影響を含める
- 関連パターンに言及する

## セッション例

```
User: /learn:teach useEffect

Claude: ## useEffect

**In one sentence**: useEffect はコンポーネントのレンダリング後にサイドエフェクト（データフェッチ、サブスクリプション、DOM 変更）を実行できます。

### Why It Matters

React コンポーネントは UI をレンダリングする純粋な関数です。しかし実際のアプリは外部世界 — API、ブラウザイベント、タイマー — とやり取りする必要があります。useEffect は React の宣言的な世界と命令的なサイドエフェクトをつなぐ橋です。

### Minimal Example

\`\`\`jsx
import { useEffect, useState } from 'react';

function Timer() {
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    const id = setInterval(() => {
      setSeconds(s => s + 1);
    }, 1000);

    return () => clearInterval(id);  // クリーンアップ
  }, []);  // 空の配列 = 一度だけ実行

  return <div>{seconds}s</div>;
}
\`\`\`

**Line by line**:
- `useEffect(() => {...}, [])`: 最初のレンダリング後にこの関数を実行
- `setInterval(...)`: タイマーを開始（サイドエフェクト）
- `return () => clearInterval(id)`: コンポーネントのアンマウント時にクリーンアップ
- `[]`: 空の依存配列 = マウント時のみ実行

### Common Mistakes

1. **依存配列の欠如**: `[]` なしでは、エフェクトは毎回のレンダリングで実行される
2. **クリーンアップの忘れ**: return 関数なしではインターバル/サブスクリプションがリークする
3. **古いクロージャ**: 関数型更新の代わりに古い状態値を使用する


**Practice challenge**: タイマーを停止・再開するポーズボタンを追加してみてください。
```

## /learn:teach に適したトピック

| カテゴリー | 例 |
|----------|----------|
| **React** | hooks, context, suspense, server components |
| **JavaScript** | closures, promises, event loop, prototypes |
| **TypeScript** | generics, mapped types, utility types |
| **パターン** | SOLID, DI, composition, factories |
| **バックエンド** | REST, GraphQL, authentication, caching |
| **データベース** | indexes, joins, transactions, normalization |
| **DevOps** | containers, CI/CD, infrastructure as code |

$ARGUMENTS
