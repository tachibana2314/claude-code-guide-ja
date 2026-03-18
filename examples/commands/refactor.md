---
layout: default
title: "SOLID リファクタリングアシスタント"
parent: コマンド
grand_parent: テンプレート
nav_order: 19
---


# SOLID リファクタリングアシスタント

SOLID 違反を分析し、的を絞った改善を提案します。

## 目的

以下に基づいてリファクタリングの機会を特定します:
- SOLID 原則の違反
- コードの臭いとアンチパターン
- 複雑さのメトリクス
- 重複の検出

## 手順

### ステップ 1: スコープ分析

ユーザー入力からリファクタリングのスコープを決定します:
- 単一ファイル: 詳細分析
- ディレクトリ: ファイル全体のパターン検出
- 関数/クラス: 集中した抽出の提案

```bash
# ファイル/ディレクトリの統計を取得
if [ -f "$TARGET" ]; then
  wc -l "$TARGET"
  echo "Single file analysis"
elif [ -d "$TARGET" ]; then
  find "$TARGET" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) | wc -l
  echo "Directory analysis"
fi
```

### ステップ 2: SOLID 違反の検出

#### S — 単一責任

以下を確認します:
- 300行以上のファイル
- 50行以上の関数
- 10個以上のメソッドを持つクラス
- 混在した関心事（データ + UI + ビジネスロジック）

```bash
# 大きなファイルを検索
find . -name "*.{ts,js,py}" -exec wc -l {} + 2>/dev/null | sort -rn | head -10

# 行数の多い関数（概算）
grep -rn "function\|def \|fn " --include="*.{ts,js,py,rs}" . | head -20
```

#### O — 開放/閉鎖原則

以下を確認します:
- タイプに基づいた switch/case 文
- 繰り返される if/else タイプチェック
- 拡張ではなく直接変更

#### L — リスコフの置換原則

以下を確認します:
- 「not implemented」を throw するオーバーライドメソッド
- メソッド呼び出し前のタイプチェック
- 空のメソッドオーバーライド

#### I — インターフェース分離

以下を確認します:
- 大きなインターフェース（10個以上のメソッド）
- 未使用のインターフェースメソッドを実装するクラス
- 太ったサービスクラス

#### D — 依存性逆転

以下を確認します:
- 依存関係の直接インスタンス化（`new Service()`）
- ハードコードされたクラス参照
- 依存性注入の欠如

### ステップ 3: コードの臭い

```bash
# 重複パターン
grep -rn --include="*.{ts,js,py}" . 2>/dev/null | \
  awk -F: '{print $3}' | sort | uniq -c | sort -rn | head -10

# 長いパラメーターリスト（4つ以上のパラメーター）
grep -rn "function.*,.*,.*,.*," --include="*.{ts,js}" . 2>/dev/null | head -10

# 深いネスト（4層以上）
grep -rn "^\s\{16,\}" --include="*.{ts,js,py}" . 2>/dev/null | head -10
```

### ステップ 4: 複雑さの評価

発見された各問題について評価します:
- **影響**: どのくらいのコードが影響を受けるか？
- **リスク**: 何が壊れる可能性があるか？
- **工数**: 変更する行数、必要なテスト？

## 出力フォーマット


### 🔧 リファクタリング分析

**対象**: [ファイル/ディレクトリ]
**分析行数**: [カウント]

### 📊 SOLID スコアカード

| 原則 | ステータス | 発見された問題 |
|-----------|--------|--------------|
| 単一責任 | 🟡 | 大きなクラスが3つ |
| 開放/閉鎖 | 🟢 | OK |
| リスコフの置換 | 🟢 | OK |
| インターフェース分離 | 🔴 | 太ったインターフェースが2つ |
| 依存性逆転 | 🟡 | 直接インスタンス化が5つ |

### 🎯 優先リファクタリング

#### 1. [最も影響度が高い] — `UserService` からクラスを抽出

**違反**: 単一責任
**現状**: 認証 + プロフィール + 通知を処理する450行
**提案**:
```
UserService.ts (450 lines)
    ↓ Extract
AuthService.ts (~150 lines)
ProfileService.ts (~150 lines)
NotificationService.ts (~100 lines)
```
**リスク**: 中（インポートの更新が必要）
**必要なテスト**: テストの依存性注入を更新

#### 2. [次の優先度] — switch をポリモーフィズムに置き換える

**場所**: `src/handlers/payment.ts:45`
**現状**:
```typescript
switch (paymentType) {
  case 'card': // 50 lines
  case 'bank': // 50 lines
  case 'crypto': // 50 lines
}
```
**提案**: `PaymentProcessor` インターフェースを使ったストラテジーパターン
**リスク**: 低（分離された変更）

### 📝 コードの臭い

| 臭い | 場所 | 重大度 |
|-------|----------|----------|
| 長いメソッド | `api.ts:calculateTotal`（120行） | 🟠 高 |
| 重複コード | `utils/*.ts`（類似ブロックが3つ） | 🟡 中 |
| 深いネスト | `parser.ts:parse`（6層） | 🟡 中 |

### 🚀 クイックウィン（低リスク、高価値）

1. `validateEmail()` を共有 utils に抽出（4箇所で使用）
2. マジックナンバーを名前付き定数に置き換える
3. `processOrder()` のネストを減らすために早期リターンを追加

### ⚠️ 技術的負債メモ

- [将来のスプリントで追跡する項目]


## リファクタリング安全チェックリスト

提案を適用する前に:

- [ ] 影響を受けるコードにテストが存在する
- [ ] フィーチャーブランチを作成する
- [ ] 現在の状態をコミットする
- [ ] 一度に1つのリファクタリングを適用する
- [ ] 各変更後にテストを実行する
- [ ] コミット前に diff をレビューする

## 使用法

**特定のファイルを分析:**
```
/refactor src/services/user.ts
```

**ディレクトリを分析:**
```
/refactor src/api/
```

**特定の原則にフォーカス:**
```
/refactor --focus=srp src/services/
```

**複雑さのしきい値付き:**
```
/refactor --threshold=high
```

## 参考資料

- Martin Fowler のリファクタリングカタログ
- Robert C. Martin の Clean Code
- Robert C. Martin による SOLID 原則

$ARGUMENTS
