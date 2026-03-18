---
layout: default
title: "パフォーマンスオプティマイザー"
parent: コマンド
grand_parent: テンプレート
nav_order: 12
---


# パフォーマンスオプティマイザー

コード、クエリ、またはシステムのパフォーマンス改善を分析・提案します。

## 目的

最適化の機会を特定します:
- ランタイムパフォーマンスのボトルネック
- メモリ使用量の問題
- データベースクエリの非効率
- バンドルサイズの問題
- アルゴリズムの複雑さ

## 手順

### ステップ 1: スコープの特定

最適化対象を決定します:
- **関数**: 単一関数のパフォーマンス
- **モジュール**: 関連する関数/クラス
- **クエリ**: データベースクエリの最適化
- **バンドル**: フロントエンドバンドルの分析
- **システム**: アーキテクチャレベルの最適化

### ステップ 2: パフォーマンス分析

#### ランタイム分析

```bash
# 潜在的に遅いパターンを検索
grep -rn "forEach\|\.map\|\.filter\|\.reduce" --include="*.{ts,js}" . | head -20

# ネストされたループを検索（O(n²) の可能性）
grep -rn "for.*for\|\.forEach.*\.forEach\|\.map.*\.map" --include="*.{ts,js}" . | head -10

# 非同期にできる同期操作を検索
grep -rn "readFileSync\|writeFileSync\|execSync" --include="*.{ts,js}" . | head -10
```

#### メモリ分析

```bash
# 大きな配列操作
grep -rn "new Array\|Array\.from\|\.concat\|spread" --include="*.{ts,js}" . | head -10

# 潜在的なメモリリーク（イベントリスナー、インターバル）
grep -rn "addEventListener\|setInterval\|setTimeout" --include="*.{ts,js}" . | head -10
```

#### データベースクエリ分析

```bash
# N+1 クエリパターン
grep -rn "await.*find\|await.*query" --include="*.{ts,js}" . | head -15

# 欠損インデックスのヒント
grep -rn "WHERE\|ORDER BY\|GROUP BY" --include="*.{ts,js,sql}" . | head -15
```

#### バンドル分析

```bash
# バンドルサイズを確認（該当する場合）
[ -f "package.json" ] && npm run build 2>/dev/null && ls -lh dist/*.js 2>/dev/null

# 大きな依存関係
[ -f "package.json" ] && cat package.json | jq '.dependencies | keys[]' | head -20
```

### ステップ 3: 優先順位付け

以下の基準で所見をランク付けします:
1. **影響**: パフォーマンスはどのくらい改善するか？
2. **工数**: 修正はどのくらい難しいか？
3. **リスク**: 何が壊れる可能性があるか？

## 出力フォーマット


### ⚡ パフォーマンス分析

**対象**: [ファイル/モジュール/システム]
**分析日時**: [タイムスタンプ]

### 📊 現在のメトリクス（計測可能な場合）

| メトリクス | 現在 | 目標 | ギャップ |
|--------|---------|--------|-----|
| レスポンスタイム | Xms | <Yms | -Z% 必要 |
| メモリ使用量 | XMB | <YMB | -Z% 必要 |
| バンドルサイズ | XKB | <YKB | -Z% 必要 |

### 🔴 クリティカルな問題

#### 1. [問題のタイトル] - [場所]

**問題**: [何が遅く、なぜか]

**現在**:
```typescript
// O(n²) - ネストされたループ
users.forEach(user => {
  permissions.forEach(perm => {
    if (user.id === perm.userId) { ... }
  });
});
```

**最適化後**:
```typescript
// O(n) - Map ルックアップ
const permMap = new Map(permissions.map(p => [p.userId, p]));
users.forEach(user => {
  const perm = permMap.get(user.id);
  if (perm) { ... }
});
```

**影響**: 1000ユーザーで約10倍高速
**工数**: 低（5分）
**リスク**: 低

### 🟠 高優先度

| 問題 | 場所 | 影響 | 工数 |
|-------|----------|--------|--------|
| [説明] | ファイル:行 | [見積もり] | [時間] |

### 🟡 中優先度

| 問題 | 場所 | 影響 | 工数 |
|-------|----------|--------|--------|
| [説明] | ファイル:行 | [見積もり] | [時間] |

### 💡 クイックウィン

1. [小さな変更で効果が大きいもの]
2. [もう一つのクイック最適化]
3. [手の届きやすい改善]

### 📈 最適化ロードマップ

```
Week 1: クリティカルな修正（項目1-3）
Week 2: 高優先度（項目4-6）
Week 3: 改善を計測・検証
```


## 一般的なパターン

### 配列操作

| パターン | 問題 | 修正 |
|---------|-------|-----|
| `arr.filter().map()` | 2回の繰り返し | 単一の `reduce()` または `flatMap()` |
| ループ内の `arr.find()` | O(n²) | 最初に Map/Set を構築 |
| `[...arr1, ...arr2]` | メモリ割り当て | `arr1.concat(arr2)` または push |

### データベース

| パターン | 問題 | 修正 |
|---------|-------|-----|
| await でのループ | N+1 クエリ | `IN` でバッチクエリ |
| `SELECT *` | 過剰フェッチ | 必要な列のみ選択 |
| WHERE インデックス欠如 | フルテーブルスキャン | 複合インデックスを追加 |

### React/フロントエンド

| パターン | 問題 | 修正 |
|---------|-------|-----|
| JSX でのインライン関数 | 再レンダリング | `useCallback` |
| 大きなリストのレンダリング | DOM スラッシング | 仮想化 |
| 最適化されていない画像 | LCP の遅延 | Next/Image、遅延ロード |

### Node.js

| パターン | 問題 | 修正 |
|---------|-------|-----|
| 同期ファイル操作 | イベントループをブロック | 非同期代替 |
| 大ファイルの JSON.parse | メモリスパイク | ストリーミングパーサー |
| コネクションプーリングなし | 接続オーバーヘッド | pg-pool などでプール |

## 使用法

**特定ファイルを分析:**
```
/optimize src/services/user.ts
```

**特定エリアにフォーカス:**
```
/optimize --queries src/repositories/
/optimize --bundle
/optimize --memory src/workers/
```

**目標メトリクス付き:**
```
/optimize --target=100ms src/api/search.ts
```

**クイックスキャン:**
```
/optimize --quick
```

## 注意事項

- 計測が仮定に勝る: 最適化の前にプロファイリングを行う
- 時期尚早な最適化はすべての悪の根本（Knuth）
- ホットパスに集中: 頻繁に実行されるものを最適化する
- トレードオフを考慮: 速度 vs 可読性 vs 保守性

$ARGUMENTS
