#!/bin/bash
# CK Parrot 备份：把会议记录、录音、设置、声纹、知识库打包成一个 .ckbak 文件。
# 默认不包含 API Key（保存在钥匙串里）；加 --with-keys 时用你设置的密码加密后一并备份（含多 Key 列表）。
# 用法：双击运行，或 scripts/backup.command [输出目录] [--no-models] [--no-audio] [--with-keys]
set -euo pipefail
ID="io.github.cknb6.ckparrot"
L="${CK_LIBRARY:-$HOME/Library}"
OUT_DIR="${1:-$HOME/Desktop}"; [ "${OUT_DIR#--}" != "$OUT_DIR" ] && OUT_DIR="$HOME/Desktop"
NO_MODELS=0; NO_AUDIO=0; WITH_KEYS=0
for a in "$@"; do case "$a" in --no-models) NO_MODELS=1;; --no-audio) NO_AUDIO=1;; --with-keys) WITH_KEYS=1;; esac; done
KEY_ACCOUNTS=(claude-api-key groq-api-key deepgram-api-key custom-llm-api-key)
DATA="$L/Containers/$ID/Data"
PREF="$L/Containers/$ID/Data/Library/Preferences/$ID.plist"
[ -d "$DATA" ] || { echo "没有找到 CK Parrot 的数据目录：$DATA"; exit 1; }
sha() { if command -v shasum >/dev/null; then shasum -a 256 "$1" | cut -d' ' -f1; else sha256sum "$1" | cut -d' ' -f1; fi; }
VER="$(defaults read "/Applications/CK Parrot.app/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo unknown)"
TS="$(date +%Y%m%d-%H%M%S)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/payload"
# 只复制应用自己的数据；缓存不备份
EXCL=(--exclude "Library/Caches" --exclude "Library/HTTPStorages" --exclude "Library/WebKit" --exclude "Library/Logs" --exclude "tmp")
[ $NO_MODELS = 1 ] && EXCL+=(--exclude "*/Models" --exclude "*/models" --exclude "*.mlmodelc")
[ $NO_AUDIO = 1 ] && EXCL+=(--exclude "*.m4a" --exclude "*.caf" --exclude "*.wav")
osascript -e 'tell application "CK Parrot" to quit' >/dev/null 2>&1 || true
rsync -a "${EXCL[@]}" "$DATA/" "$TMP/payload/Data/"
[ -f "$PREF" ] || defaults export "$ID" "$TMP/payload/preferences.plist" 2>/dev/null || true
# SQLite / SwiftData：若存在 sqlite3，用 VACUUM INTO 生成一致快照
if command -v sqlite3 >/dev/null; then
  while IFS= read -r -d '' db; do
    rel="${db#"$DATA/"}"; rm -f "$TMP/payload/Data/$rel-wal" "$TMP/payload/Data/$rel-shm"
    sqlite3 "$db" "VACUUM INTO '$TMP/snap.db'" 2>/dev/null && mv "$TMP/snap.db" "$TMP/payload/Data/$rel"
  done < <(find "$DATA" -name "*.store" -print0 -o -name "*.sqlite" -print0)
fi
INCLUDES_KEYS=false
if [ $WITH_KEYS = 1 ] && command -v security >/dev/null && command -v openssl >/dev/null; then
  PW="${CK_BACKUP_PASSWORD:-}"
  if [ -z "$PW" ]; then read -r -s -p "设置备份密码（恢复 API Key 时需要）：" PW; echo; fi
  [ ${#PW} -ge 6 ] || { echo "密码至少 6 位"; exit 1; }
  : > "$TMP/keys.txt"; chmod 600 "$TMP/keys.txt"
  for acct in "${KEY_ACCOUNTS[@]}"; do
    v="$(security find-generic-password -s "$ID" -a "$acct" -w 2>/dev/null || true)"
    [ -n "$v" ] && printf '%s\t%s\n' "$acct" "$(printf %s "$v" | base64 | tr -d '\n')" >> "$TMP/keys.txt"
  done
  if [ -s "$TMP/keys.txt" ]; then
    printf %s "$PW" | openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt -pass stdin -in "$TMP/keys.txt" -out "$TMP/payload/keys.enc"
    INCLUDES_KEYS=true
  fi
  rm -f "$TMP/keys.txt"
fi
cd "$TMP/payload"
{
  echo "{"
  echo "  \"app\": \"ck-parrot\", \"schemaVersion\": 1, \"appVersion\": \"$VER\","
  echo "  \"createdAt\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"includesKeys\": $INCLUDES_KEYS,"
  echo "  \"checksums\": {"
  first=1
  while IFS= read -r -d '' f; do
    f="${f#./}"; [ $first = 1 ] || echo ","; first=0
    printf '    "%s": "%s"' "$(printf %s "$f" | sed 's/\\/\\\\/g; s/"/\\"/g')" "$(sha "$f")"
  done < <(find . -type f ! -name manifest.json -print0 | sort -z)
  echo; echo "  }"; echo "}"
} > manifest.json
mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/ck-parrot-$TS.ckbak"
zip -qr -X "$OUT.part" manifest.json $(ls -A | grep -v '^manifest.json$')
mv "$OUT.part" "$OUT"
echo "备份完成：$OUT（$(du -h "$OUT" | cut -f1)）"
if [ "$INCLUDES_KEYS" = true ]; then echo "API Key 已加密包含在备份中（恢复时需要密码）。"; else echo "API Key 不在备份中，恢复后请在设置里重新填写（或加 --with-keys 加密备份）。"; fi
