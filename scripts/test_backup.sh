#!/bin/bash
# 在临时目录里自测 backup.command / restore.command（macOS 与 Linux 均可运行）
set -euo pipefail
S="$(cd "$(dirname "$0")" && pwd)"; T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export HOME="$T/home" CK_LIBRARY="$T/L"; mkdir -p "$HOME/Desktop"
D="$T/L/Containers/io.github.cknb6.ckparrot/Data/Library"; mkdir -p "$D/Application Support/Parrot/Memory" "$D/Caches"
echo '{"v":1}' > "$D/Application Support/Parrot/voiceprint.json"; echo m > "$D/Application Support/Parrot/Memory/a b.json"; echo junk > "$D/Caches/x"
"$S/backup.command" "$T/out" >/dev/null; f=$(ls "$T"/out/*.ckbak)
unzip -l "$f" | grep -q Caches && { echo "FAIL caches included"; exit 1; }
echo changed > "$D/Application Support/Parrot/voiceprint.json"
"$S/restore.command" "$f" --yes >/dev/null
grep -q '"v":1' "$D/Application Support/Parrot/voiceprint.json" || { echo "FAIL restore"; exit 1; }
ls "$HOME/Desktop"/*.ckbak >/dev/null || { echo "FAIL pre-restore backup"; exit 1; }
mkdir "$T/z"; (cd "$T/z" && unzip -q "$f" && echo x >> "Data/Library/Application Support/Parrot/voiceprint.json" && zip -qr "$T/bad.ckbak" .)
if "$S/restore.command" "$T/bad.ckbak" --yes >/dev/null; then echo "FAIL tamper accepted"; exit 1; fi
grep -q '"v":1' "$D/Application Support/Parrot/voiceprint.json" || { echo "FAIL data touched"; exit 1; }
echo "backup/restore OK"
