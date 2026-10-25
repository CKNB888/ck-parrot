#!/bin/bash
# CK Parrot 完全卸载脚本。只删除以 io.github.cknb6.ckparrot 命名的目录和本应用。
set -u
ID="io.github.cknb6.ckparrot"
echo "将删除 CK Parrot 及其全部数据（会议记录、录音、模型、设置、钥匙串项）。"
read -r -p "输入 y 确认：" ok; [ "$ok" = "y" ] || { echo "已取消。"; exit 0; }
osascript -e 'quit app "CK Parrot"' 2>/dev/null; sleep 1
L="$HOME/Library"
for p in "$L/Containers/$ID" "$L/Application Scripts/$ID" "$L/Group Containers/$ID" \
         "$L/Caches/$ID" "$L/HTTPStorages/$ID" "$L/WebKit/$ID" "$L/Logs/$ID" \
         "$L/Saved Application State/$ID.savedState" "$L/Preferences/$ID.plist" \
         "$L/LaunchAgents/$ID.plist"; do
  [ -e "$p" ] && rm -rf "$p" && echo "已删除 $p"
done
defaults delete "$ID" 2>/dev/null
while security delete-generic-password -s "$ID" >/dev/null 2>&1; do :; done
for app in "/Applications/CK Parrot.app" "$HOME/Applications/CK Parrot.app"; do
  [ -d "$app" ] && { rm -rf "$app" 2>/dev/null || sudo rm -rf "$app"; } && echo "已删除 $app"
done
pkgutil --pkgs | grep -qx "$ID" && sudo pkgutil --forget "$ID"
echo "卸载完成。"
