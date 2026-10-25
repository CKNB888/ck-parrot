# 更新记录（中文版）

## v1.0.0 — CK Parrot 首个独立版本
- 更名、包标识 io.github.cknb6.ckparrot、开发区域 zh-Hans
- 中文转写默认 + 繁转简
- 中文权限弹窗（InfoPlist.strings）
- 关闭上游 Sparkle 自动更新
- 启动崩溃与引导页崩溃修复，补齐 Try:/Why: 翻译，转录→转写术语统一
- CI 产物命名 ck-parrot_*

## 2026-10-25
- 新增：简体中文本地化（en + zh-Hans），应用跟随系统语言
- 修复：#146 OpenAI 兼容接口（OpenRouter）响应被截断时自动扩大 token 预算重试
- 修复：语言不匹配横幅未本地化、按钮在中文下被截断
- 新增：关于面板贡献者信息、README.zh-CN.md、CI 本地化校验
