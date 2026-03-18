---
layout: default
title: "コード説明"
parent: コマンド
grand_parent: テンプレート
nav_order: 6
---


# コード説明

コード、概念、またはシステムの動作を調整可能な詳細レベルで説明します。

## 目的

以下を明確に説明します:
- 特定のコードの動作
- 特定のパターンが使用される理由
- システム/モジュールの役割
- アーキテクチャの意思決定とトレードオフ

## 手順

### ステップ 1: スコープの特定

何を説明する必要があるかを特定します:
- **ファイル**: ファイル構造全体と目的
- **関数/メソッド**: 具体的な実装の詳細
- **概念**: アーキテクチャパターンや設計の意思決定
- **フロー**: データや制御がシステムを通じてどのように移動するか

### ステップ 2: 複雑さの評価

```
シンプル（1-2分読了）   → クイックサマリー、要点のみ
標準（3-5分読了）       → 目的、動作方法、重要な意思決定
詳細（10分以上読了）    → 完全な分解、代替案、トレードオフ
```

### ステップ 3: コンテキストの収集

```bash
# ファイルの説明のために
head -50 "$FILE"  # インポートと構造を確認

# 関数の説明のために
grep -A 30 "function $NAME\|def $NAME\|fn $NAME" "$FILE"

# モジュールの説明のために
ls -la "$DIR"
cat "$DIR/index.ts" 2>/dev/null || cat "$DIR/__init__.py" 2>/dev/null
```

### ステップ 4: 説明を構造化する

## 出力フォーマット


### 📖 説明: [対象]

**スコープ**: [ファイル/関数/概念/フロー]
**詳細レベル**: [シンプル/標準/詳細]

### 何をするか

[目的を1-3文で説明]

### どのように動作するか

[詳細レベルに応じたステップごとの分解]

### 重要な意思決定

| 意思決定 | 理由 | 代替案 |
|---------|------|--------|
| [選択された方法] | [根拠] | [他に有効なもの] |

### 使用例

```typescript
// 正しい使い方
```

### 関連コード

- `path/to/related.ts` - [関係]
- `path/to/dependency.ts` - [関係]

### 💡 学習メモ（--learn フラグ使用時）

[より広いパターンを理解するための追加コンテキスト]


## 詳細レベル

### シンプル（`/explain --simple`）

```markdown
**validateUser()** はユーザーオブジェクトが必須フィールド
（email、password）を持っているかチェックし、boolean を返す。メール形式には正規表現を使用。
```

### 標準（`/explain` — デフォルト）

```markdown
**validateUser(user: User): ValidationResult**

**目的**: データベース操作前にユーザー入力を検証。

**フロー**:
1. 必須フィールドの存在を確認（email、password）
2. 正規表現でメール形式を検証
3. パスワードが要件を満たすか確認（8文字以上、特殊文字）
4. { valid: boolean, errors: string[] } を返す

**使用場所**: signup()、updateProfile()
```

### 詳細（`/explain --deep`）

```markdown
[標準の内容すべて、プラス:]

**設計の意思決定**:
- バッチ検証を可能にするため、throw ではなく ValidationResult を返す
- 依存関係ゼロのために Zod より正規表現を選択
- パスワードルールは config.ts で設定可能

**トレードオフ**:
- Pro: 高速、依存関係なし
- Con: 正規表現のメール検証は RFC 準拠ではない

**検討された代替案**:
- Zod スキーマ: より強力だが 50KB 追加
- class-validator: デコレーターには最適だが OOP 重視
```

## 使用例

**ファイルを説明:**
```
/explain src/auth/middleware.ts
```

**関数を説明:**
```
/explain the handleWebhook function in payments.ts
```

**概念を説明:**
```
/explain how our event sourcing works
```

**特定の詳細レベルで説明:**
```
/explain --deep the authentication flow
/explain --simple what useCallback does
```

**学習のために説明:**
```
/explain --learn the repository pattern used here
```

## ヒント

1. **具体的に**: 「行45-60を説明して」 > 「このファイルを説明して」
2. **レベルを伝える**: 「TypeScript 初心者です」と伝えると説明を調整できる
3. **フォローアップを求める**: 「代わりに X を使わないのはなぜ？」で理解が深まる
4. **類比を求める**: 「Python は知っているが TS は初めて」のように説明を求める

$ARGUMENTS
