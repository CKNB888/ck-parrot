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
# --with-keys：用假的 security 命令验证多 Key 加密备份与恢复
mkdir -p "$T/bin"; KS="$T/ks"; mkdir -p "$KS"
cat > "$T/bin/security" <<SH
#!/bin/bash
op=\$1; shift; acct=""; val=""
while [ \$# -gt 0 ]; do case "\$1" in -a) acct=\$2; shift;; -w) [ "\$op" = add-generic-password ] && { val=\$2; shift; };; esac; shift; done
case "\$op" in find-generic-password) [ -f "$KS/\$acct" ] && cat "$KS/\$acct" || exit 44;; add-generic-password) printf %s "\$val" > "$KS/\$acct";; esac
SH
chmod +x "$T/bin/security"; export PATH="$T/bin:$PATH"
printf 'k-one\nk-two' > "$KS/groq-api-key"
CK_BACKUP_PASSWORD=secret123 "$S/backup.command" "$T/out2" --with-keys >/dev/null; f2=$(ls "$T"/out2/*.ckbak)
unzip -l "$f2" | grep -q keys.enc || { echo "FAIL keys.enc missing"; exit 1; }
unzip -p "$f2" keys.enc | grep -q k-one && { echo "FAIL plaintext key"; exit 1; }
rm -f "$KS/groq-api-key"
CK_BACKUP_PASSWORD=secret123 "$S/restore.command" "$f2" --yes >/dev/null
[ "$(cat "$KS/groq-api-key")" = "$(printf 'k-one\nk-two')" ] || { echo "FAIL key restore"; exit 1; }
echo "backup/restore OK"
