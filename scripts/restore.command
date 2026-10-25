#!/bin/bash
# CK Parrot 恢复：校验 .ckbak → 预览 → 确认 → 先自动备份当前数据 → 整体替换；失败自动回滚。
# 用法：scripts/restore.command 备份文件.ckbak [--yes] [--dry-run]
set -euo pipefail
ID="io.github.cknb6.ckparrot"
L="${CK_LIBRARY:-$HOME/Library}"
SRC="${1:-}"; [ -f "$SRC" ] || { echo "用法：restore.command 备份文件.ckbak"; exit 1; }
YES=0; DRY=0; for a in "$@"; do case "$a" in --yes) YES=1;; --dry-run) DRY=1;; esac; done
sha() { if command -v shasum >/dev/null; then shasum -a 256 "$1" | cut -d' ' -f1; else sha256sum "$1" | cut -d' ' -f1; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
unzip -q "$SRC" -d "$TMP/x"
M="$TMP/x/manifest.json"
[ -f "$M" ] || { echo "不是有效的 CK Parrot 备份（缺少 manifest.json）"; exit 2; }
grep -q '"app": "ck-parrot"' "$M" || { echo "这不是 CK Parrot 的备份"; exit 2; }
SV="$(sed -n 's/.*"schemaVersion": \([0-9]*\).*/\1/p' "$M")"
[ "${SV:-0}" -le 1 ] || { echo "备份格式版本 $SV 比本脚本新，请先更新 CK Parrot"; exit 2; }
# 路径安全 + 校验和
bad=0; n=0
while IFS= read -r line; do
  f="$(printf %s "$line" | sed -n 's/^ *"\(.*\)": "\([0-9a-f]\{64\}\)".*/\1/p')"; h="$(printf %s "$line" | sed -n 's/.*": "\([0-9a-f]\{64\}\)".*/\1/p')"
  [ -n "$f" ] || continue
  case "$f" in /*|*../*) echo "不安全的路径：$f"; exit 2;; esac
  n=$((n+1))
  [ -f "$TMP/x/$f" ] && [ "$(sha "$TMP/x/$f")" = "$h" ] || { echo "校验失败：$f"; bad=1; }
done < <(sed -n '/"checksums"/,/}/p' "$M")
[ $bad = 0 ] || { echo "备份文件已损坏，未做任何修改。"; exit 3; }
echo "备份校验通过：$n 个文件"
sed -n 's/.*"appVersion": "\([^"]*\)".*/  来自版本：\1/p; s/.*"createdAt": "\([^"]*\)".*/  创建时间：\1/p' "$M"
echo "  会议 / 数据库文件：$(find "$TMP/x/Data" -name '*.store' -o -name '*.sqlite' 2>/dev/null | wc -l | tr -d ' ')"
echo "  录音文件：$(find "$TMP/x/Data" \( -name '*.m4a' -o -name '*.caf' -o -name '*.wav' \) 2>/dev/null | wc -l | tr -d ' ')"
echo "  声纹：$( [ -n "$(find "$TMP/x/Data" -name voiceprint.json 2>/dev/null)" ] && echo 有 || echo 无)"
echo "  总大小：$(du -sh "$TMP/x/Data" | cut -f1)"
[ $DRY = 1 ] && { echo "（仅预览，未修改）"; exit 0; }
if [ $YES = 0 ]; then read -r -p "将用此备份替换当前全部 CK Parrot 数据，输入 y 继续：" ok; [ "$ok" = "y" ] || { echo "已取消。"; exit 0; }; fi
osascript -e 'tell application "CK Parrot" to quit' >/dev/null 2>&1 || true; sleep 1
DATA="$L/Containers/$ID/Data"
if [ -d "$DATA" ]; then
  SAFE_DIR="$HOME/Desktop"; [ -d "$SAFE_DIR" ] || SAFE_DIR="$HOME"
  echo "先备份当前数据…"; "$(dirname "$0")/backup.command" "$SAFE_DIR" --no-models >/dev/null && echo "  已保存到 $SAFE_DIR"
fi
OLD="$DATA.ck-restore-old"
rm -rf "$OLD"; mkdir -p "$(dirname "$DATA")"
rollback() { echo "恢复失败，正在回滚…"; rm -rf "$DATA"; [ -d "$OLD" ] && mv "$OLD" "$DATA"; exit 4; }
[ -d "$DATA" ] && mv "$DATA" "$OLD"
trap 'rollback' ERR
cp -R "$TMP/x/Data" "$DATA"
[ -f "$TMP/x/preferences.plist" ] && command -v defaults >/dev/null && defaults import "$ID" "$TMP/x/preferences.plist"
trap - ERR
rm -rf "$OLD"
echo "恢复完成。请在设置里重新填写 API Key。"
