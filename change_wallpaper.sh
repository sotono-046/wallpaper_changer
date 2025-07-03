#!/usr/bin/env bash

# 使用方法:
# ./change_wallpaper.sh                          # ディスプレイ一覧を表示
# ./change_wallpaper.sh <display_id> <image_path> # 指定ディスプレイに壁紙を設定

# 必須: yabai, jq

# ディスプレイ一覧表示機能
show_display_list() {
  echo "🖥️  利用可能なディスプレイ"
  echo "========================="

  # m-cliとyabaiの情報を組み合わせて表示
  yabai -m query --displays | jq -r 'sort_by(.id) | .[] | 
    "ディスプレイID: \(.id)
    解像度: \(.frame.w | floor)x\(.frame.h | floor)
    スペース: \(.spaces | join(", "))
    位置: (\(.frame.x | floor), \(.frame.y | floor))
    ========================="'

}

# 指定ディスプレイの全スペースに壁紙を設定
set_wallpaper_by_display() {
  local display_id="$1"
  local wallpaper_path="$2"

  echo "🖼️  ディスプレイ$display_id に壁紙を設定: $(basename "$wallpaper_path")"

  # ディスプレイからスペース一覧を取得
  local display_info=$(yabai -m query --displays | jq --argjson target_id "$display_id" '.[] | select(.id == $target_id)')
  local space_indexes=$(echo "$display_info" | jq -r '.spaces[]?')

  if [ -z "$space_indexes" ]; then
    echo "❌ エラー: ディスプレイID $display_id が見つかりません"
    echo "   利用可能なディスプレイを確認してください: $0"
    exit 1
  fi

  local space_count=$(echo "$space_indexes" | wc -w)
  local space_list=$(echo "$space_indexes" | tr '\n' ' ' | xargs)
  echo "📋 処理対象: $space_count 個のスペース ($space_list)"

  # ディスプレイにフォーカス
  yabai -m display --focus "$display_id" >/dev/null 2>&1
  sleep 0.3

  # ディスプレイIDとAppleScriptのdesktop番号のマッピング
  local applescript_desktop_number
  case "$display_id" in
  1) applescript_desktop_number=2 ;; # Color LCD (内蔵画面)
  2) applescript_desktop_number=1 ;; # EV2780 (メインディスプレイ)
  3) applescript_desktop_number=3 ;; # 27E1Q (縦画面)
  *)
    echo "❌ エラー: 不明なディスプレイID: $display_id"
    exit 1
    ;;
  esac

  # 各スペースで壁紙設定
  local success_count=0

  for space_index in $space_indexes; do
    echo "⚡ スペース$space_index を処理中..."

    # スペースにフォーカス
    yabai -m space --focus "$space_index" >/dev/null 2>&1
    sleep 0.3

    # AppleScriptで壁紙設定
    local result=$(
      osascript 2>&1 <<EOF
try
    tell application "System Events"
        tell desktop $applescript_desktop_number
            set picture to POSIX file "$wallpaper_path"
        end tell
        return "成功"
    end tell
on error errMsg
    return "エラー: " & errMsg
end try
EOF
    )

    if [[ "$result" == *"成功"* ]]; then
      echo "   ✅ 完了"
      success_count=$((success_count + 1))
    else
      echo "   ❌ 失敗: $result"
    fi
  done

  echo ""
  echo "🎉 ディスプレイID $display_id の壁紙設定完了"
  echo "   成功: $success_count/$space_count スペース"

  if [ "$success_count" -ne "$space_count" ]; then
    echo "   ⚠️ 一部のスペースで設定に失敗しました"
    return 1
  fi
}

# 引数チェック
if [ $# -eq 0 ]; then
  show_display_list
  exit 0
elif [ $# -eq 2 ]; then
  DISPLAY_ID="$1"
  WALLPAPER_PATH="$2"
else
  echo "使用方法:"
  echo "  $0                      # ディスプレイ一覧を表示"
  echo "  $0 <ディスプレイID> <画像パス>  # 指定ディスプレイに壁紙設定"
  exit 1
fi

# 必要なコマンドのチェック
if ! command -v yabai &>/dev/null; then
  echo "エラー: yabai コマンドが見つかりません（インストールしてください）" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "エラー: jq コマンドが見つかりません（インストールしてください）" >&2
  exit 1
fi

# 壁紙ファイルのチェック
if [ ! -f "$WALLPAPER_PATH" ]; then
  echo "エラー: 壁紙ファイルが見つかりません: $WALLPAPER_PATH" >&2
  exit 1
fi

set_wallpaper_by_display "$DISPLAY_ID" "$WALLPAPER_PATH"
