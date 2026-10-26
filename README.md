# CK Parrot —— 中文优先的 macOS 本地会议转写与通话助手

**简体中文** | [English](README.en.md)

> 基于 Parrot（作者 turantekin / Uygar，GPL-3.0）二次开发，维护者 **CKNB**。
> 仓库：<https://github.com/CKNB888/ck-parrot> · 包标识 `io.github.cknb6.ckparrot`（可与上游 Parrot 同时安装）
> 当前版本：**v2.1.0** · 系统要求：macOS 14+，Apple Silicon

## 它能做什么
同时录制系统音频（对方）和麦克风（你），**在本机实时转写**（WhisperKit，也可选云端 Groq / OpenAI 兼容接口），通话中由助手结合你的文档给出提示卡片，会后自动生成摘要、复盘报告与评分，可导出 Markdown / TXT / SRT / PDF。

| 功能 | 说明 |
|---|---|
| 本机实时转写 | WhisperKit；中文默认、繁体自动转简体；中文幻听（「谢谢观看」等）过滤 |
| 通话助手卡片 | 建议回答、待回答问题、待办、风险等；按通话类型切换（面试、销售、会议、课堂答疑…） |
| 课堂答疑（v2.1.0） | 学生提问时，卡片标题即一句话结论，正文 ≤3 条要点；另有易错点 / 待回答 / 追问建议 |
| 我的声纹 | 录 15 秒自己的声音，转写中自己的话统一标为「我」 |
| 课堂模式标签 | 其他说话人显示为「学生1、学生2…」；会议菜单「导出提问」 |
| 菜单栏面板 | 不可共享的独立面板：开始 / 停止录音、最近通话、设置 |
| 实时提示 | 有刘海的 Mac 从刘海滑出，否则出现在菜单栏图标下方 |
| 知识库 | 让助手引用你的文档；「问问 Parrot」搜索所有历史通话 |
| 会后 | 摘要、复盘报告与评分、导出、Webhook / 笔记文件夹 / 跟进邮件 |
| 备份与恢复（v2.1.0） | `.ckbak` 单文件，带校验，恢复前自动备份、失败回滚 |
| 防共享 | 所有窗口、面板、弹出框默认不出现在腾讯会议 / 钉钉 / Zoom 的共享画面中 |

## 界面截图

以下均为 CK Parrot 在 GitHub macOS 机器上实际渲染的界面（简体中文界面，示例通话内容为英文演示数据）。英文界面截图见 [docs/screenshots/en](docs/screenshots/en)。

| | |
|---|---|
| <img src="docs/screenshots/zh/01-onboarding-path.png" width="420"><br>选择助手工作方式：私密 / 均衡 / 云端 | <img src="docs/screenshots/zh/02-onboarding-model.png" width="420"><br>下载本机语音模型，国内自动走镜像 |
| <img src="docs/screenshots/zh/03-dashboard.png" width="420"><br>首页：一键开始录音，选择通话语言 | <img src="docs/screenshots/zh/04-settings-copilot.png" width="420"><br>设置实时通话助手 |
| <img src="docs/screenshots/zh/05-live-screen.png" width="420"><br>通话中：左侧助手卡片，右侧实时转写 | <img src="docs/screenshots/zh/06-copilot.png" width="420"><br>助手悬浮窗：建议回答随时可复制 |
| <img src="docs/screenshots/zh/07-meeting-header.png" width="420"><br>会后：会议信息与参会人 | <img src="docs/screenshots/zh/08-report-scorecard.png" width="420"><br>自动生成复盘报告与评分 |
| <img src="docs/screenshots/zh/09-ask.png" width="420"><br>问问 Parrot：搜索你的所有通话 | <img src="docs/screenshots/zh/10-settings-transcription.png" width="420"><br>转写引擎与模型下载源 |
| <img src="docs/screenshots/zh/11-settings-profiles.png" width="420"><br>按通话类型配置助手 | <img src="docs/screenshots/zh/12-settings-knowledge.png" width="420"><br>知识库：让助手引用你的文档 |
| <img src="docs/screenshots/zh/13-settings-privacy.png" width="420"><br>隐私：仅限本机、隐藏个人信息 | <img src="docs/screenshots/zh/14-settings-connections.png" width="420"><br>连接：保存笔记、Webhook、跟进邮件 |
| <img src="docs/screenshots/zh/15-ai-apps.png" width="420"><br>在 Claude / Cursor 中使用你的会议 |  |

## 安装
1. 在 [Releases](https://github.com/CKNB888/ck-parrot/releases) 下载 `ck-parrot_*_macOS_arm64.dmg`（或 `.pkg`）。
2. 拖到「应用程序」。构建为 ad-hoc 签名、未公证：首次右键 → 打开，或执行
   `xattr -cr "/Applications/CK Parrot.app"`。
3. 按引导授予麦克风、「屏幕与系统录音」权限（日历可选）。
4. 选择助手方式：私密（本机 Ollama）/ 均衡（音频留本机，文字发给云端模型）/ 云端。
5. 下载语音模型：应用会按电脑配置推荐并检查磁盘空间；中文建议 Large V3 Turbo，`base` 对中文效果差。中国大陆自动走 hf-mirror.com 镜像。

## 使用
1. 首页点「开始录音」（⌘R），选择通话语言；腾讯会议、钉钉等开会时会自动检测到通话。
2. 右侧实时转写，左侧助手卡片，一键复制；在设置 → 通话类型 里选「课堂答疑」等预设。
3. 停止录音（⌘.）后查看摘要、复盘报告，导出或用「问问 Parrot」（⌘K）搜索。

## 升级
下载新版 dmg 覆盖安装即可，数据保存在沙盒容器中不会丢失。升级前建议先运行一次备份（见下）。v2.1.1 新增的提示词预设同样自动出现，原有 Key 会作为第一个 Key 继续使用。v2.1.0 新增的「课堂答疑」预设会自动出现在通话类型列表里，不影响你修改过的其他预设。

## 备份与恢复
```bash
# 备份到桌面（含会议、录音、设置、声纹、知识库；不含缓存与 API Key）
scripts/backup.command                  # 可加 --no-models 跳过语音模型，--no-audio 跳过录音
# 恢复：先校验与预览，确认后自动备份当前数据，再整体替换；失败自动回滚
scripts/restore.command ~/Desktop/ck-parrot-YYYYMMDD-HHMMSS.ckbak
scripts/restore.command 备份.ckbak --dry-run   # 只预览
```
`.ckbak` 是 zip，内含 `manifest.json`（版本、时间、逐文件 SHA-256）。脚本会先退出 CK Parrot。API Key 保存在钥匙串中，默认不备份；加 `--with-keys` 时用你设置的密码加密后一并备份（含多 Key 列表），恢复时输入密码即可写回钥匙串。

## 卸载
设置 → 完全卸载（删除录音、转写、模型、声纹与钥匙串密钥），或运行 [`scripts/uninstall.command`](scripts/uninstall.command)；最后把 CK Parrot 拖到废纸篓。

## 隐私
| 数据 | 私密模式 | 均衡模式 | 云端模式 |
|---|---|---|---|
| 音频 | 仅本机 | 仅本机 | 选云端转写时发给你配置的服务商 |
| 转写文字 | 仅本机 | 发给你配置的模型服务商 | 发给你配置的服务商 |
| 声纹 | 仅本机（voiceprint.json） | 仅本机 | 仅本机 |
| API Key | — | 钥匙串 | 钥匙串 |
| 屏幕共享 | 所有窗口默认隐藏 | 同左 | 同左 |
| 自动更新 / 统计 | 无（已移除上游 Sparkle） | 无 | 无 |

macOS 15+ 整屏共享存在系统限制，建议只共享单个窗口。可开启「隐藏个人信息」在发送前脱敏。

## 快捷键
| 快捷键 | 作用 | 范围 |
|---|---|---|
| ⌘R | 开始录音 | 应用内 |
| ⌘. | 停止录音 | 应用内 / 菜单栏面板 |
| ⌃⌥M | 标记时刻 | 全局，录音中 |
| ⌃⌥⇧M | 静音麦克风 | 全局，录音中 |
| ⌘K | 问问 Parrot | 应用内 |
| ⌘F | 查找会议 | 应用内 |
| ⌘E | 导出转写（TXT） | 应用内 |
| ⌘O | 导入音频 | 应用内 |

全局快捷键与腾讯会议、钉钉、飞书、微信、QQ、Zoom 默认快捷键不冲突。

## 更新记录
详见 [CHANGELOG.zh-CN.md](CHANGELOG.zh-CN.md)。
- **v2.1.1** 同一服务商多个 Key 自动轮换（429 / 额度 / 鉴权失败冷却后换下一个）；内置中文提示词库（会议、面试、翻译、课堂·理科 / 语言），可编辑、可恢复默认；菜单栏隐身面板可直接切换服务商、模型和转写引擎；国内会议应用中文名、浏览器网页会议识别；备份可加密包含 Key；静态检查全量扫描
- **v2.1.0** 课堂答疑通话类型（结论优先、≤3 要点、易错点 / 待回答 / 追问建议）；`.ckbak` 备份与恢复脚本（校验、预览、恢复前自动备份、失败回滚），CI 自测；README 重写
- **v2.0.0** 我的声纹；课堂模式标签；导出提问；菜单栏面板与新图标；按配置推荐模型、下载前检查磁盘、停止后释放模型内存；完全卸载；去掉 emoji
- **v1.0.6** 刘海 / 菜单栏实时提示；防共享加固（新面板、PDF 离屏窗口）；只保留本仓库链接；赞助信息
- **v1.0.5** 睡眠唤醒后自动恢复系统音频采集，ScreenCaptureKit 中止自动重连
- **v1.0.4** 权限说明更准确；文案统一；快捷键复核
- **v1.0.3** Groq whisper 实测后补充中文幻听过滤，「自动」语言也繁转简
- **v1.0.2** 代码审查（强制解包、定时器与观察者生命周期）
- **v1.0.1** 实时音频缓冲上限 5 分钟；共享屏幕隐私；汉化补全
- **v1.0.0** 更名 CK Parrot、新包标识；中文优先与繁转简；中文权限弹窗；关闭上游自动更新；启动崩溃修复

## 从源码构建
```bash
brew install xcodegen && xcodegen generate
make bundle CONFIG=release SIGN_IDENTITY=-
scripts/test_backup.sh        # 备份 / 恢复自测
```

## 赞助与广告合作
欢迎赞助本项目或洽谈广告合作，请添加微信 **1837620622**（请备注来意）。

## 许可证
GPL-3.0（见 [LICENSE](LICENSE)）。上游版权归 Parrot 原作者所有；修改部分 © CKNB。
