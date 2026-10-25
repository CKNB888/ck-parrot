# CK Parrot v1.0.0

基于 Parrot（GPL-3.0）的中文优先独立版，维护者 CKNB（github.com/cknb6）。

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
- 第二轮审计项（回声消除加锁、模型下载镜像、token 上限、备用模型报错、服务商超时 3s→30s）未改动代码，留待真机调试后处理。
- macOS 15+ 屏幕共享隐身、腾讯会议的音频采集需实测。
- 自动更新已关闭（未配置 Sparkle 源）。
