# Parrot（简体中文说明）

[English](README.md)

Parrot 是一款 macOS 原生会议录音工具：同时录制系统音频和你的麦克风，在本机实时转录，并提供一个能结合你自己的文档、在通话中实时给出建议的 AI 助手。

- **平台**：macOS 14 及以上，Apple Silicon（原生 SwiftUI 应用，不支持 Windows / Linux）
- **隐私**：默认在本机转录（WhisperKit / Parakeet），音频不离开你的 Mac；云端引擎为可选项
- **界面语言**：英文、简体中文（跟随系统语言自动切换）

## 快速开始

1. 从 [Releases](https://github.com/turantekin/Parrot/releases) 下载最新版本，拖入“应用程序”。
2. 首次启动按引导授予麦克风和系统音频权限。
3. 在“设置 → 助手”中选择 AI（本机 Ollama、Claude、或 OpenAI 兼容接口如 OpenRouter / DeepSeek）。
4. 开始录音。

## 从源码构建

```bash
make app            # 需要 Xcode 16 / Swift 5.10
```

CI（GitHub Actions，macOS runner）会自动构建、运行测试并产出可下载的 `.app` 测试包。

## 切换语言

应用跟随 macOS 系统语言。只想让 Parrot 用中文：系统设置 → 通用 → 语言与地区 → 应用程序 → 添加 Parrot → 简体中文。

## 贡献者

- [CKNB (@cknb6)](https://github.com/CKNB888)：简体中文本地化与问题修复

## 许可证

GPL-3.0，详见 [LICENSE](LICENSE)。
