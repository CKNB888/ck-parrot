# Add Simplified Chinese localization + fix truncated OpenRouter reports (#146)

## Summary
- **Localization (en + zh-Hans).** Adds `Localization/{en,zh-Hans}.lproj/Localizable.strings` (~425 UI strings) keyed by the existing English SwiftUI literals, so no view code had to change for `Text`/`Button`/`Label`/`Toggle`/`.help` etc. `make bundle` and `scripts/release.sh` copy the `.lproj` folders into `Contents/Resources` and set `CFBundleLocalizations`, so the app follows the system language (or the per-app language in System Settings).
- **Bug fix #146** — reasoning models via OpenRouter could spend the entire `max_tokens` budget on hidden thinking and return `finish_reason: "length"`. `OpenAICompatibleProvider.send` now retries once with a 4× budget (capped at 8192) before surfacing the truncation error. Fixes #146.
- **UI polish.** The wrong-language banner text is now localizable, and its Keep/Switch buttons use `.fixedSize()` so longer translations don't truncate.
- **About panel** credits text is localized and adds a small credit line for the Chinese localization.
- **Docs/CI.** `README.zh-CN.md` linked from the README; CI lints the `.strings` files with `plutil -lint`.

## Notes
- No secrets or upstream-only settings required; CI passed on the fork.
- Strings built at runtime as `String` (not literals) and interpolated literals are still English; they can be migrated incrementally.
- `project.yml` (xcodegen) users: add `Localization` as a resource folder if you build through Xcode.

## Credit
If you're happy with this, I'd be grateful to be listed as a contributor: **CKNB** — https://github.com/cknb6. Thanks for Parrot!

---
### 中文摘要
本 PR 为 Parrot 增加简体中文界面（跟随系统语言），修复 #146（OpenRouter 推理模型报告被截断，自动扩大预算重试一次），本地化语言不匹配横幅并防止中文按钮截断，新增中文 README 和 CI 本地化校验。恳请将 CKNB（https://github.com/cknb6）列为贡献者。

## Round 2 additions
- ~70 more runtime / interpolated strings localized via `String(localized:)` (settings tab titles, nudges, error messages, menu-bar call counts, word/percent labels; zh uses positional `%1$@/%2$@` where order differs). en/zh key sets: 502/502, format specifiers verified identical.
- `project.yml`: `Localization` added as a resources source and `CFBundleLocalizations: [en, zh-Hans]`; `Parrot/Info.plist` declares the same.
- Simplified Chinese help book: all 18 pages translated in `docs/help/zh-Hans/` (shares `help.css`/`img`), and `scripts/assemble-help.sh` now builds and indexes a `zh-Hans.lproj` inside `Parrot.help`.
- Not yet verified on macOS CI for this round (build, `--profile-test`, `hiutil`, zh-Hans screenshots) — please run CI before merging.

### 第二轮（中文摘要）
新增约 70 条运行时字符串本地化、project.yml/Info.plist 声明 zh-Hans、完整中文帮助文档（18 页）并集成进帮助书。贡献者：CKNB（https://github.com/cknb6）。本轮尚未经 macOS CI 验证。

## Round 3 additions
- Localized the idle-recording reminder notification (title + body, with `%lld` minute count) and the "Couldn't start recording" alert in the menu bar and app menu (4 new keys, en/zh parity 502/502).
- Static check: `.strings` files parse cleanly, no missing/extra keys, format specifiers match (positional where reordered).

### 第三轮（中文摘要）
本地化“仍在录音”空闲提醒通知和“无法开始录音”弹窗。
