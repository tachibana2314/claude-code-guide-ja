---
layout: default
title: "テスト生成"
parent: コマンド
grand_parent: テンプレート
nav_order: 7
---


# テスト生成

指定されたコードに対して包括的なテストを生成します。

## 手順

1. 対象ファイルを読み込む
2. テスト可能な単位（関数、クラス、メソッド）を特定する
3. プロジェクトの規約に従ってテストを生成する
4. エッジケースのカバレッジを高くする

## テスト生成プロセス

### 1. 対象の分析
- パブリックインターフェースの特定
- 依存関係の理解
- エッジケースと境界値の把握

### 2. テストフレームワークの検出
以下を確認します:
- `jest.config.js` → Jest
- `vitest.config.ts` → Vitest
- `pytest.ini` → pytest
- `mocha` in package.json → Mocha

### 3. テストの生成
検出されたフレームワークの規約に従います。

## テストカテゴリー

### ハッピーパス
有効な入力での通常の期待される動作。

### エッジケース
- 空の入力
- null/undefined 値
- 境界値（0、-1、MAX_INT）
- 単一アイテム vs 複数アイテム

### エラーケース
- 無効な入力タイプ
- 必須パラメーターの欠如
- ネットワーク/IO 障害
- タイムアウトシナリオ

### 統合ポイント
- データベースのやり取り
- 外部 API 呼び出し
- ファイルシステム操作

## 出力フォーマット

```typescript
describe('[ComponentName]', () => {
  describe('[methodName]', () => {
    // ハッピーパス
    it('should [expected behavior] when [condition]', () => {
      // Arrange
      // Act
      // Assert
    });

    // エッジケース
    it('should handle empty input', () => {});
    it('should handle null values', () => {});

    // エラーケース
    it('should throw when [invalid condition]', () => {});
  });
});
```

## 規約

- テストごとに1つのアサーション（実用的な範囲で）
- 説明的なテスト名
- AAA パターン（Arrange-Act-Assert）
- テストの相互依存なし
- 外部依存関係のモック

## 使用法

```
/generate-tests src/utils/calculator.ts
/generate-tests src/services/
```

$ARGUMENTS
