# Parrot 中文版

[English README](README.en.md) · 上游项目：[turantekin/Parrot](https://github.com/turantekin/Parrot)

## 项目简介

Parrot 是 macOS 原生（SwiftUI）会议录音工具：同时录制系统音频和麦克风，在本机实时转录，并在通话中由 AI 助手结合你的文档给出提示。本仓库是 **简体中文本地化 + Bug 修复** 版本，改动以 PR 形式回馈上游。

- 平台：macOS 14+，Apple Silicon（原生 Mac 应用，不支持 Windows / Linux）
- 界面：英文 / 简体中文，跟随系统语言

## 修复的 bug

- [#146](https://github.com/turantekin/Parrot/issues/146) OpenRouter 等推理模型把 token 预算耗在思考上导致“Response truncated”：截断时自动以更大预算重试一次。
- 语言不匹配横幅文字未本地化，中文下按钮被截断：已本地化并防止截断。

## 新增功能

- 简体中文界面（`Localization/zh-Hans.lproj`，400+ 条界面文字）
- 关于面板显示本地化贡献者
- CI 增加本地化文件校验
- 中文 README

开发分支：[`feat/i18n-zh-bugfixes`](https://github.com/cknb6/Parrot/tree/feat/i18n-zh-bugfixes)

## 下载 / 构建

- 测试包：在本仓库 [Actions](https://github.com/cknb6/Parrot/actions) 中打开最新一次 CI 运行，下载 `Parrot-test-build`（ad-hoc 签名，首次打开需右键 → 打开）。
- 正式版：[上游 Releases](https://github.com/turantekin/Parrot/releases)
- 源码构建：`make app`（需要 Xcode 16）

## 贡献者

- [CKNB](https://github.com/cknb6)：简体中文本地化与 Bug 修复

更新记录见 [CHANGELOG.zh-CN.md](CHANGELOG.zh-CN.md)。许可证：GPL-3.0。
