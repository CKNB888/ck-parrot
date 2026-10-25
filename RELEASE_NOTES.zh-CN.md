# CK Parrot v1.0.0

基于 Parrot（GPL-3.0）的中文优先独立版，维护者 CKNB（github.com/CKNB888）。

## 新功能 / 改进
- 更名 CK Parrot（io.github.cknb6.ckparrot），可与上游共存
- 中文为开发语言；中文或未知系统语言下转写语言默认「中文」
- 中文转写自动繁转简
- 系统权限弹窗中文化；术语统一（转写 / 服务商）
- 关闭指向上游的自动更新

## 修复
- 数据库打开失败启动即崩 → 备份并重建，必要时内存模式运行
- 引导页步骤索引强制解包崩溃
- 缺失翻译：“Try:”“Why:”
- 更新日志链接指向本仓库 Releases

## 安装
ad-hoc 签名未公证：`xattr -cr "/Applications/CK Parrot.app"`。仅支持 macOS 14+ Apple Silicon。

## 已知限制与需真机验证
- 本 fork 的 Swift 代码未在 macOS 上编译验证，请先 `make` / Xcode 构建。
- 第二轮审计项已改代码（未在 Mac 上编译，已用 Swift 6.0.3 做语法解析）：
  - 回声消除对象加锁（OSAllocatedUnfairLock），停录时先停音源再释放；
  - ScreenCaptureKit 回调改用串行队列；
  - 模型下载源：中文系统 / 中国大陆默认 hf-mirror.com，设置里可切换，失败时自动换另一个源重试一次，并给出中文报错和“重试”按钮（WhisperKit 0.18.0 `download(endpoint:)`、FluidAudio `ModelRegistry.baseURL` 均已对照源码核实）；
  - 报告 / 教练的 max_tokens 提到 4096（原有 finish_reason=length 自动加大重试保留）；
  - 备用 Whisper 加载失败时写日志并在界面提示；
  - 音频线程读取的 isCapturing / micMuted / tapEverHadSignal 改为加锁副本；
  - 服务商请求最多 3 次指数退避（含断网、超时），断网/DNS/超时给中文提示；Ollama 列表超时 3s→30s。
- macOS 15+ 屏幕共享隐身、腾讯会议的音频采集需实测。
- 自动更新已关闭（未配置 Sparkle 源）。
