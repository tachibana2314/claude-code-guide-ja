#!/bin/bash
# 危険なアクション（rm -rf, DROP TABLE等）をブロックするPreToolUseフック
#
# 設定方法: .claude/settings.json に追加
# {
#   "hooks": {
#     "PreToolUse": [{
#       "matcher": "Bash",
#       "command": ".claude/hooks/dangerous-actions-blocker.sh"
#     }]
#   }
# }

# ツール入力をstdinから読み取り
INPUT=$(cat)

# コマンドを抽出
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# 危険なパターンのチェック
DANGEROUS_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "rm -rf \."
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE"
  "DELETE FROM .* WHERE 1"
  "git push.*--force.*main"
  "git push.*--force.*master"
  "git reset --hard"
  "chmod -R 777"
  "mkfs\."
  "> /dev/sd"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "BLOCKED: 危険なコマンドを検出: $pattern" >&2
    echo '{"decision": "block", "reason": "危険なコマンドパターンを検出しました"}'
    exit 0
  fi
done

# 安全 - 実行を許可
exit 0
