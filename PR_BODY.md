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
