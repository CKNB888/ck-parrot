# CK Parrot v1.0.1

- 内存：每路实时转写音频缓冲上限 5 分钟（约 19 MB），解码跟不上或模型加载中时不再无限增长
- 汉化补全：设置、仪表盘、会议详情、Copilot、报告等界面剩余英文全部译为简体中文（英文界面保留）
- CI：同一提交已打版本标签时跳过分支构建

## 安装
ad-hoc 签名未公证：`xattr -cr "/Applications/CK Parrot.app"`。仅支持 macOS 14+ Apple Silicon。
