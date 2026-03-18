---
layout: default
title: "サンドボックスステータスコマンド"
parent: コマンド
grand_parent: テンプレート
nav_order: 23
---


# サンドボックスステータスコマンド

ネイティブ Claude Code サンドボックスの状態、アクティブな設定、セキュリティイベントを調査します。

## 使用法

```
/sandbox-status
```

## 何をするか

1. **サンドボックスの可用性を確認**
   - OS プリミティブがインストールされているか確認（Linux では bubblewrap、macOS では Seatbelt）
   - プラットフォームサポートのステータスを表示

2. **アクティブな設定を表示**
   - サンドボックスモード（自動許可 vs 通常の権限）
   - ファイルシステムポリシー（許可された書き込み、拒否された読み取り）
   - ネットワークポリシー（ドメイン許可リスト/拒否リスト）
   - 除外されたコマンド

3. **最近のサンドボックス違反を一覧表示**
   - ブロックされたファイルシステムアクセス試行
   - ブロックされたネットワーク接続
   - エスケープハッチの呼び出し（`dangerouslyDisableSandbox`）

## 実装

```bash
#!/bin/bash

echo "=== Native Sandbox Status ==="
echo

# 1. プラットフォームの確認
echo "Platform:"
case "$OSTYPE" in
  darwin*)
    echo "  ✅ macOS (Seatbelt built-in)"
    ;;
  linux*)
    if which bubblewrap >/dev/null 2>&1; then
      echo "  ✅ Linux (bubblewrap installed)"
      bubblewrap --version 2>/dev/null | head -1
    else
      echo "  ❌ Linux (bubblewrap NOT installed)"
      echo "     Install: sudo apt-get install bubblewrap socat"
    fi
    if which socat >/dev/null 2>&1; then
      echo "  ✅ socat installed"
    else
      echo "  ❌ socat NOT installed"
    fi
    ;;
  *)
    echo "  ❌ Unsupported platform: $OSTYPE"
    ;;
esac
echo

# 2. 設定
echo "Configuration (from settings.json):"
if [ -f .claude/settings.json ]; then
  CONFIG=".claude/settings.json"
elif [ -f ~/.claude/settings.json ]; then
  CONFIG="~/.claude/settings.json"
else
  echo "  ⚠️  No settings.json found"
  CONFIG=""
fi

if [ -n "$CONFIG" ]; then
  echo "  Source: $CONFIG"

  # 自動許可モード
  AUTO_ALLOW=$(jq -r '.sandbox.autoAllowMode // "not set"' "$CONFIG" 2>/dev/null)
  echo "  Auto-allow: $AUTO_ALLOW"

  # 許可された書き込みパス
  WRITE_PATHS=$(jq -r '.sandbox.filesystem.allowedWritePaths[]? // empty' "$CONFIG" 2>/dev/null | tr '\n' ', ')
  echo "  Allowed writes: ${WRITE_PATHS:-not set}"

  # 拒否された読み取りパス
  DENIED_READS=$(jq -r '.sandbox.filesystem.deniedReadPaths[]? // empty' "$CONFIG" 2>/dev/null | tr '\n' ', ')
  echo "  Denied reads: ${DENIED_READS:-not set}"

  # ネットワークポリシー
  NET_POLICY=$(jq -r '.sandbox.network.policy // "not set"' "$CONFIG" 2>/dev/null)
  echo "  Network policy: $NET_POLICY"

  # 許可されたドメイン
  DOMAINS=$(jq -r '.sandbox.network.allowedDomains[]? // empty' "$CONFIG" 2>/dev/null | head -3 | tr '\n' ', ')
  DOMAINS_COUNT=$(jq -r '.sandbox.network.allowedDomains | length' "$CONFIG" 2>/dev/null)
  if [ -n "$DOMAINS" ]; then
    echo "  Allowed domains: $DOMAINS... ($DOMAINS_COUNT total)"
  else
    echo "  Allowed domains: not set"
  fi

  # 除外されたコマンド
  EXCLUDED=$(jq -r '.sandbox.excludedCommands[]? // empty' "$CONFIG" 2>/dev/null | tr '\n' ', ')
  echo "  Excluded commands: ${EXCLUDED:-not set}"
fi
echo

# 3. 最近の違反（プレースホルダー — 実際の実装は Claude Code のログを読む）
echo "Recent sandbox violations:"
echo "  ℹ️  Log inspection not yet implemented"
echo "  Tip: Check Claude Code session logs for sandbox violation notifications"
echo

# 4. オープンソースランタイム
echo "Open-Source Runtime:"
if which npx >/dev/null 2>&1; then
  echo "  ✅ npx available - can use @anthropic-ai/sandbox-runtime"
  echo "  Usage: npx @anthropic-ai/sandbox-runtime <command>"
else
  echo "  ⚠️  npx not found (install Node.js)"
fi
echo

# 5. ドキュメント
echo "Documentation:"
echo "  Guide: guide/sandbox-native.md"
echo "  Official: https://code.claude.com/docs/en/sandboxing"
echo "  Runtime: https://github.com/anthropic-experimental/sandbox-runtime"
```

## 出力例

```
=== Native Sandbox Status ===

Platform:
  ✅ macOS (Seatbelt built-in)

Configuration (from settings.json):
  Source: .claude/settings.json
  Auto-allow: true
  Allowed writes: ${CWD}, /tmp
  Denied reads: ${HOME}/.ssh, ${HOME}/.aws, ${HOME}/.kube
  Network policy: deny
  Allowed domains: api.anthropic.com, registry.npmjs.com, github.com... (9 total)
  Excluded commands: docker, kubectl, podman

Recent sandbox violations:
  ℹ️  Log inspection not yet implemented
  Tip: Check Claude Code session logs for sandbox violation notifications

Open-Source Runtime:
  ✅ npx available - can use @anthropic-ai/sandbox-runtime
  Usage: npx @anthropic-ai/sandbox-runtime <command>

Documentation:
  Guide: guide/sandbox-native.md
  Official: https://code.claude.com/docs/en/sandboxing
  Runtime: https://github.com/anthropic-experimental/sandbox-runtime
```

## ユースケース

- **デプロイ前**: 自律ワークフローを実行する前にサンドボックス設定を確認
- **デバッグ**: 特定のコマンドがブロックされる理由を調査
- **セキュリティ監査**: 許可されたドメインとファイルシステムアクセスをレビュー
- **オンボーディング**: 新しいチームメンバーがプロジェクトのサンドボックスポリシーを理解するのを支援

## 参照

- [ネイティブサンドボックスガイド](../../guide/sandbox-native.md) — 完全な技術リファレンス
- [サンドボックス検証フック](../hooks/bash/sandbox-validation.sh) — コマンド前の検証
- [サンドボックス設定例](../config/sandbox-native.json) — 本番対応の設定
