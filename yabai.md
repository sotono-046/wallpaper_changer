# Yabai セットアップ手順（macOS + Apple Silicon）

## SIP（System Integrity Protection）の一部無効化

1. リカバリーモードに入る
   1. Mac を完全にシャットダウン
   2. 電源ボタンを長押し → 「オプション」→「続ける」を選択
2. Terminal を起動
3. `csrutil enable --without fs --without debug --without nvram` を実行して一部の SIP を無効化
4. `reboot` で再起動
5. 再起動後 `sudo nvram boot-args=-arm64e_preview_abi` を実行
6. `reboot` で再起動
7. `csrutil status` で確認

出力例：

```bash
System Integrity Protection status: unknown (Custom Configuration).

Configuration:
    Filesystem Protections: disabled
    Debugging Restrictions: disabled
    NVRAM Protections: disabled

```

## Yabai のインストールから設定

```bash
brew install yabai
sudo yabai --load-sa
echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d ' ' -f1) $(which yabai) --load-sa" | sudo tee /private/etc/sudoers.d/yabai > /dev/null
yabai --start-service

```

## 動作確認

```bash
yabai -m space --focus 2
yabai -m space --focus 3
```

何もエラーが出なければ成功！