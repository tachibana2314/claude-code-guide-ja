---
title: "TTSセットアップワークフロー - Agent Vibesのインストール"
description: "macOSでClaude Codeにテキスト読み上げナレーションを追加する"
tags: [workflow, tts, tutorial]
---

# TTSセットアップワークフロー - Agent Vibesのインストール

**目標**: Claude Codeにテキスト読み上げナレーションを追加する
**所要時間**: 18分
**難易度**: 中級
**システム**: macOS（Homebrewが必要）

---

## 判断ポイント: TTSをインストールすべきか

以下の簡単な評価を使ってください:

| 質問 | 回答 | スコア |
|----------|--------|-------|
| 長いコードレビューをすることがある？ | はい | +2 |
| デバッグ中にマルチタスクをする？ | はい | +2 |
| 音声通知を好む？ | はい | +1 |
| オフラインTTS（クラウド不使用）が必要？ | はい | +2 |
| レイテンシが重要（100ms以下が必要）？ | はい | -2 |
| 公共の場所で作業する（音声が出せない）？ | はい | -3 |
| 静かな環境を好む？ | はい | -2 |

**スコア**:
- **3以上**: TTSをインストール（良い適合）
- **0〜2**: 任意（試してみて、アンインストール可能）
- **0未満**: TTSをスキップ（適合しない）

---

## ワークフロー概要

```
フェーズ1: 前提条件（5分）
    ↓
フェーズ2: Agent Vibesのインストール（5分）
    ↓
フェーズ3: Piper TTS + ボイス（5分）
    ↓
フェーズ4: テスト＆設定（3分）
    ↓
フェーズ5: 確認（1分）
```

---

## フェーズ1: 前提条件（5分）

### チェックポイント1.1: システム要件

```bash
# macOSバージョンを確認
sw_vers
# 必要: macOS 10.15以上

# Homebrewを確認
brew --version
# 未インストールの場合: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Node.jsを確認
node --version
# 必要: 16.0.0以上
```

### チェックポイント1.2: Bash 5.xのインストール

```bash
# インストール
brew install bash

# 確認
/opt/homebrew/bin/bash --version
# 期待値: GNU bash, version 5.x

# ✅ チェックポイント: Bash 5.xインストール済み
```

### チェックポイント1.3: 依存関係のインストール

```bash
# 音声ツールのインストール
brew install sox ffmpeg util-linux espeak-ng

# すべてインストール済みか確認
command -v sox && command -v ffmpeg && command -v espeak-ng && echo "✅ 依存関係OK"

# ✅ チェックポイント: 依存関係インストール済み
```

**フェーズ1の合計時間**: 約5分

---

## フェーズ2: Agent Vibesのインストール（5分）

### ステップ2.1: インストーラーの起動

```bash
# プロジェクトに移動
cd /path/to/your/claude-project

# インタラクティブインストーラーを起動
npx agentvibes install
```

**期待値**: ASCIIバナー + 4ページのインタラクティブインストーラー

### ステップ2.2: ページのナビゲート

**ページ1/4 - 依存関係**:
- 確認: すべて✓の緑チェックマークが表示されているはず
- 操作: 「Next →」をクリック

**ページ2/4 - プロバイダー**:
- **選択**: `Piper TTS`（最高品質、オフライン）
- 操作: 「Next →」をクリック

**ページ3/4 - ボイス**:
- **フランス語**: `fr_FR-tom-medium`を選択（男性、プロフェッショナル）
- **英語**: `en_US-ryan-high`を選択（最高品質）
- 操作: 「Next →」をクリック

**ページ4/4 - 設定**:
- **リバーブ**: `Light`（推奨）
- **バックグラウンドミュージック**: `Disabled`（気が散るのを避けるため）
- **冗長性**: `Low`（おしゃべりを減らす）
- 操作: 「Start Installation」をクリック

### チェックポイント2.3: インストールの確認

```bash
# インストールされたファイルを確認
ls .claude/hooks/play-tts.sh
ls .claude/commands/agent-vibes/
cat .claude/tts-provider.txt
# 期待値: ファイルが存在し、プロバイダーが「macos」または「piper」を表示

# ✅ チェックポイント: Agent Vibesインストール済み
```

**フェーズ2の合計時間**: 約5分

---

## フェーズ3: Piper TTS + フランス語ボイス（5分）

### ステップ3.1: pipxでPiperをインストール

```bash
# Piper TTSをインストール
pipx install piper-tts

# 確認
piper --help
# 期待値: Piperの使用方法の説明

# ✅ チェックポイント: Piperインストール済み
```

### ステップ3.2: フランス語ボイスのダウンロード

```bash
# ボイスディレクトリの作成
mkdir -p ~/.claude/piper-voices
cd ~/.claude/piper-voices

# フランス語男性ボイスのダウンロード（推奨）
curl -L -o fr_FR-tom-medium.onnx \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/fr/fr_FR/tom/medium/fr_FR-tom-medium.onnx"
curl -L -o fr_FR-tom-medium.onnx.json \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/fr/fr_FR/tom/medium/fr_FR-tom-medium.onnx.json"

# フランス語女性ボイスのダウンロード（任意）
curl -L -o fr_FR-siwis-medium.onnx \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/fr/fr_FR/siwis/medium/fr_FR-siwis-medium.onnx"
curl -L -o fr_FR-siwis-medium.onnx.json \
  "https://huggingface.co/rhasspy/piper-voices/resolve/main/fr/fr_FR/siwis/medium/fr_FR-siwis-medium.onnx.json"

# ✅ チェックポイント: ボイスダウンロード済み（約120MB）
```

**フェーズ3の合計時間**: 約5分

---

## フェーズ4: 設定とテスト（3分）

### ステップ4.1: プロバイダーとボイスの設定

```bash
# Piperをプロバイダーとして設定
echo "piper" > .claude/tts-provider.txt

# フランス語男性ボイスを設定
echo "fr_FR-tom-medium" > .claude/tts-voice.txt

# 設定を確認
cat .claude/tts-provider.txt  # 期待値: piper
cat .claude/tts-voice.txt     # 期待値: fr_FR-tom-medium

# ✅ チェックポイント: 設定完了
```

### ステップ4.2: 音声パイプラインのテスト

```bash
# Piperを直接テスト
echo "Bonjour, je suis Claude et je parle français" | \
  piper -m ~/.claude/piper-voices/fr_FR-tom-medium.onnx \
  --output-file /tmp/test-fr.wav && afplay /tmp/test-fr.wav

# TTSフックのテスト
~/.claude/hooks/play-tts.sh "Ceci est un test audio"

# ✅ チェックポイント: 音声が動作
```

**期待値**: フランス語男性の音声が聞こえるはずです。

**フェーズ4の合計時間**: 約3分

---

## フェーズ5: Claude Codeでの検証（1分）

### ステップ5.1: 起動とテスト

```bash
# Claude Codeを起動
claude

# Claudeで次を実行:
/agent-vibes:whoami
# 期待値: プロバイダー「piper」とボイス「fr_FR-tom-medium」を表示

# 簡単なリクエストをテスト
> "Dis-moi bonjour en français"
# 期待値: フランス語男性の音声でレスポンス

# ✅ チェックポイント: Claude CodeでTTSが有効
```

### ステップ5.2: 設定の調整

```bash
# 冗長性を減らす（推奨）
/agent-vibes:verbosity low

# 混雑している場合は34のコマンドを非表示にする
/agent-vibes:hide

# ✅ チェックポイント: 設定完了
```

**フェーズ5の合計時間**: 約1分

---

## 合計時間: 約18分 ✅

---

## セットアップ後の推奨事項

### ワークフローへの最適化

**コードレビューの場合**:
```bash
/agent-vibes:verbosity low
/agent-vibes:effects off
```

**集中作業の場合**:
```bash
/agent-vibes:mute  # 一時的にミュート
# 音声なしで作業
/agent-vibes:unmute  # 完了したら再有効化
```

**バッテリー最適化の場合**:
```bash
# macOS Sayに切り替え（即時、CPUバーストなし）
/agent-vibes:provider switch macos
```

### .gitignoreへの追加

```bash
# 大きな音声ファイルのコミットを防ぐ
echo ".claude/audio/" >> .gitignore
echo ".claude/piper-voices/" >> .gitignore
echo "*.wav" >> .gitignore
echo "*.onnx" >> .gitignore
```

---

## トラブルシューティングクイックリファレンス

| 問題 | 簡単な解決策 |
|-------|-----------|
| 音声が出ない | `cat .claude/tts-provider.txt`を確認 |
| 違うボイス | `/agent-vibes:switch fr_FR-tom-medium`を実行 |
| おしゃべりすぎる | `/agent-vibes:verbosity low`を実行 |
| コマンドが多すぎる | `/agent-vibes:hide`を実行 |

**完全なトラブルシューティング**: [Agent Vibesトラブルシューティング](../../examples/integrations/agent-vibes/troubleshooting.md)

---

## 次のステップ

- **[ボイスカタログ](../../examples/integrations/agent-vibes/voice-catalog.md)** - 15のボイスを探索
- **[インテグレーションガイド](../../examples/integrations/agent-vibes/README.md)** - コマンドを学ぶ
- **[インストール詳細](../../examples/integrations/agent-vibes/installation.md)** - 詳細解説

---

## アンインストール手順

Agent Vibesを完全に削除するには:

```bash
# 自動アンインストール
npx agentvibes uninstall --yes

# 手動クリーンアップ（必要な場合）
rm -rf .claude/hooks/*vibes*
rm -rf .claude/commands/agent-vibes/
rm -rf .claude/audio/
rm -rf ~/.claude/piper-voices/
pipx uninstall piper-tts
```

---

*ワークフローガイドは[Claude Code Ultimate Guide](https://github.com/FlorianBruniaux/claude-code-ultimate-guide)によって管理されています*
*最終更新: 2026-01-22 | Agent Vibes v3.0.0*
