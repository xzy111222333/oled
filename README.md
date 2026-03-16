# OLEDGuard

原生 iOS OLED 护眼工具工程骨架，按 `final_plan.md` 的完整方案搭建。

## 已落地内容

- SwiftUI 主 App 结构
- 单页总控台首页
- 过滤度 / 模式 / 亮度 / 恢复 的统一状态模型
- OLED 护眼算法引擎
- 自动化规则与生物钟阶段计算
- App Intents 快捷动作
- Widget 快速入口
- 共享状态存储
- 需求对照文档 `coverage_audit.md`
- 安卓页面对照文档 `android_parity.md`

## 当前限制

本仓库当前在 Windows 环境创建，未包含 `.xcodeproj` 成品，也未在 Xcode 上编译验证。工程采用 `XcodeGen` 描述，需在云 Mac 或本地 Mac 生成工程后编译。

需要你在 Mac 环境补齐的东西：

- Apple 开发者账号与签名
- 真实 `Bundle Identifier`
- App Group 标识
- App Icon 资源
- Widget / App Intent 的真机调试
- 审核文案与隐私信息

## 在云 Mac 上启动

1. 安装 Xcode 16 或更新版本
2. 安装 XcodeGen
3. 进入仓库目录
4. 运行 `xcodegen generate`
5. 打开 `OLEDGuard.xcodeproj`
6. 修改 `project.yml` 中的 `PRODUCT_BUNDLE_IDENTIFIER` 和 Team
7. 配置 App Group：`group.com.example.OLEDGuard`
8. 编译到真机
