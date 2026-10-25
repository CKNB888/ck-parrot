# CK Parrot

A Chinese-first macOS meeting recorder with on-device transcription and a live AI assistant.

- Repository & downloads: <https://github.com/CKNB888/ck-parrot> · [Releases](https://github.com/CKNB888/ck-parrot/releases)
- Report a bug: <https://github.com/CKNB888/ck-parrot/issues>
- Chinese README: [README.md](README.md)

## Highlights
- Records system audio + microphone and transcribes on your Mac (WhisperKit); live AI assistant during calls (Ollama / OpenAI-compatible).
- Lives in the menu bar. Live nudges drop out of the notch (Dynamic-Island style) on Macs with a notch, or appear right under the menu bar icon otherwise.
- Every Parrot window is excluded from screen sharing by default (`sharingType = none`); on macOS 15+ ScreenCaptureKit full-screen sharing may still show it, so share a single window.
- Requires macOS 14+ on Apple Silicon. Ad-hoc signed: run `xattr -cr "/Applications/CK Parrot.app"`.

## Build from source
```bash
make bundle CONFIG=release SIGN_IDENTITY=-
```

## Sponsorship & Ads
Sponsorships and advertising partnerships are welcome — add WeChat **1837620622** (please mention your purpose).

## License
GPL-3.0 (see [LICENSE](LICENSE)). Based on Parrot by turantekin; modifications © CKNB.
