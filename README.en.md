# CK Parrot — Chinese-first local meeting transcription & call copilot for macOS

[简体中文](README.md) | **English**

Fork of Parrot by turantekin (GPL-3.0), maintained by **CKNB** — <https://github.com/CKNB888/ck-parrot>. Bundle id `io.github.cknb6.ckparrot` (installs alongside upstream). Current version **v2.1.0**, macOS 14+, Apple Silicon.

## Features
On-device live transcription (WhisperKit; Chinese default with Traditional→Simplified), copilot cards per call profile (interview, sales, meeting, **Classroom Q&A** new in 2.1.0: conclusion-first answers, ≤3 points, misconceptions, unanswered questions), "My voice" voiceprint, classroom speaker labels, export questions, menu-bar panel, notch nudges, knowledge base and "Ask Parrot", post-call reports, all windows hidden from screen sharing by default.

## Install / upgrade
Download the `.dmg` from Releases, drag to Applications, run `xattr -cr "/Applications/CK Parrot.app"` (ad-hoc signed). Upgrading = install over the old app; data lives in the sandbox container.

## Backup / restore / uninstall
`scripts/backup.command` writes a `.ckbak` (zip + manifest with SHA-256 per file, consistent SQLite snapshot, no caches, no API keys). `scripts/restore.command file.ckbak` verifies, previews, backs up current data, replaces, and rolls back on failure (`--dry-run` to preview). Uninstall: Settings → Remove everything, or `scripts/uninstall.command`.

## Privacy
Audio stays on the Mac unless you pick cloud transcription; transcript text goes only to the model provider you configure; voiceprint stays local; keys in Keychain; no auto-update or analytics.

## Shortcuts
⌘R start · ⌘. stop · ⌃⌥M mark moment (global) · ⌃⌥⇧M mute (global) · ⌘K Ask Parrot · ⌘F find · ⌘E export TXT · ⌘O import audio.

## Changelog
v2.1.0 Classroom Q&A profile, backup/restore · v2.0.0 voiceprint, classroom labels, menu-bar panel · v1.0.6 notch nudges · v1.0.5 audio recovery after sleep · v1.0.4 polish · v1.0.3 hallucination filter · v1.0.2 review · v1.0.1 memory cap, share privacy · v1.0.0 first CK release. Details (Chinese): [CHANGELOG.zh-CN.md](CHANGELOG.zh-CN.md).

## Sponsorship & Ads
WeChat **1837620622**.

## License
GPL-3.0.
