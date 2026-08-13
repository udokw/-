# CallForwarder - 一键呼叫转移 iOS App

## 功能

- 在 Today 视图 / 主屏幕 / 控制中心(iOS 18+) 放置交互式小组件
- 点击小组件按钮一键拨打 USSD 码激活/关闭呼叫转移
- 支持四种转移类型：全部转移、遇忙转移、无应答转移、不可达转移
- 支持自定义 USSD 码（适配不同运营商）
- Siri 语音控制："开启呼叫转移"

## 工作原理

iOS 不允许第三方 App 直接修改系统呼叫转移设置，只能通过拨打 USSD 码实现：

| 操作 | GSM 码 | 说明 |
|------|--------|------|
| 全部转移 | `**21*号码#` | 所有来电立即转移 |
| 遇忙转移 | `**67*号码#` | 通话中来电转移 |
| 无应答转移 | `**61*号码#` | 无人接听时转移 |
| 不可达转移 | `**62*号码#` | 关机/无信号时转移 |
| 关闭转移 | `##21#` 等 | 取消对应类型 |
| 查询状态 | `*#21#` 等 | 查看当前状态 |

App 通过 `tel:` URL 拨打上述代码，iOS 会弹出拨号确认界面，用户按通话键即可。

**限制**：iOS 出于安全考虑不允许自动拨号，每次需手动确认。

## Xcode 搭建步骤

### 1. 创建项目

1. 打开 Xcode → New Project → iOS App
2. Product Name: `CallForwarder`
3. Interface: SwiftUI
4. Language: Swift
5. Minimum Deployments: iOS 17.0（交互式 Widget 需要）

### 2. 添加 Widget Extension

1. File → New → Target → Widget Extension
2. Product Name: `CallForwarderWidget`
3. 勾选 "Include Configuration App Intent"（可选）
4. Embed in: `CallForwarder`

### 3. 配置 App Group

两个 Target 都需要配置相同的 App Group：

1. 选中 App Target → Signing & Capabilities → + Capability → App Groups
2. 添加: `group.com.callforwarder.shared`
3. 选中 Widget Target → 同样添加相同的 App Group

### 4. 添加 URL Scheme

选中 App Target → Info → URL Types → 添加：

- URL Scheme: `callforwarder`

### 5. 添加源文件

将以下文件拖入对应 Target：

**App Target (CallForwarder)**:
- `Shared/SharedSettings.swift`（勾选 CallForwarder 和 CallForwarderWidget 两个 Target）
- `CallForwarder/CallForwarderApp.swift`
- `CallForwarder/ContentView.swift`
- `CallForwarder/ForwardingIntents.swift`

**Widget Target (CallForwarderWidget)**:
- `CallForwarderWidget/CallForwarderWidget.swift`
- (SharedSettings.swift 也需要勾选 Widget Target)

### 6. 编译运行

1. 选择真机（Widget 在模拟器上支持有限）
2. Build & Run
3. 在 App 中设置电话号码
4. 回到主屏幕 → 长按 → 添加小组件 → 搜索 "呼叫转移"

## 文件结构

```
CallForwarder/
├── Shared/
│   └── SharedSettings.swift          # 共享设置（App + Widget 共用）
├── CallForwarder/
│   ├── CallForwarderApp.swift        # App 入口 + 全局状态
│   ├── ContentView.swift             # 设置界面
│   └── ForwardingIntents.swift       # App Intent + Siri 快捷指令
├── CallForwarderWidget/
│   └── CallForwarderWidget.swift     # 交互式小组件
└── README.md
```

## 使用流程

1. 打开 App → 输入转移号码 → 选择转移类型
2. 回到主屏幕 → 添加小组件
3. 下拉 Today 视图 → 点击「开启转移」按钮
4. 系统弹出拨号界面 → 按通话键确认
5. 呼叫转移激活成功

## 运营商兼容性

| 运营商 | 标准 GSM 码 | 备注 |
|--------|------------|------|
| 中国移动 | ✅ **21*号码# | 完全支持 |
| 中国联通 | ✅ **21*号码# | 完全支持 |
| 中国电信 | ⚠️ 部分套餐 | 需自定义: *72*号码# / *720# |
| AT&T | ✅ **21*号码# | 完全支持 |
| T-Mobile | ✅ **21*号码# | 完全支持 |

电信用户请在 App 中开启「自定义 USSD 码」选项。

## 技术要点

- **App Intent** (iOS 16+): 定义可被 Widget/Siri/Shortcuts 调用的操作
- **交互式 Widget** (iOS 17+): `Button(intent:)` 在 Widget 中直接响应点击
- **App Group**: 通过共享 UserDefaults 在 App 和 Widget 间传递设置
- **tel: URL**: `tel:**21*13888888888%23`（# 需 URL 编码为 %23）
- **URL Scheme**: Widget 通过 `callforwarder://activate` 唤起 App 执行拨号

## License

MIT
