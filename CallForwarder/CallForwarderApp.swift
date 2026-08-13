import SwiftUI

// ============================================================
// App 入口
// ============================================================

@main
struct CallForwarderApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    appState.handleIncomingURL(url)
                }
        }
    }
}

/// App 全局状态
class AppState: ObservableObject {
    @Published var phoneNumber: String = SharedSettings.phoneNumber
    @Published var forwardingType: ForwardingType = SharedSettings.forwardingType
    @Published var useCustomCode: Bool = SharedSettings.useCustomCode
    @Published var customActivateCode: String = SharedSettings.customActivateCode
    @Published var customDeactivateCode: String = SharedSettings.customDeactivateCode
    @Published var showActionAlert: Bool = false
    @Published var actionMessage: String = ""
    @Published var showCopyToast: Bool = false
    @Published var copyToastMessage: String = ""

    /// 处理从 Widget 传入的 URL
    func handleIncomingURL(_ url: URL) {
        guard url.scheme == "callforwarder" else { return }

        switch url.host {
        case "activate":
            performActivate()
        case "deactivate":
            performDeactivate()
        case "status":
            performStatusCheck()
        default:
            break
        }
    }

    /// 执行拨号 - 直接拨打，不先弹 Alert
    private func dial(_ ussd: String, actionName: String) {
        SharedSettings.lastAction = actionName
        SharedSettings.lastActionTime = Date()

        // 先复制到剪贴板作为备选
        UIPasteboard.general.string = ussd

        guard let telURL = SharedSettings.telURL(for: ussd) else {
            actionMessage = "无法创建拨号 URL，USSD 码已复制到剪贴板:\n\(ussd)\n请手动粘贴到电话App拨打"
            showActionAlert = true
            return
        }

        // 直接拨号，不延迟，不弹 Alert 阻塞
        UIApplication.shared.open(telURL, options: [:]) { success in
            DispatchQueue.main.async {
                if !success {
                    // tel: URL 打开失败，提示用户手动操作
                    self.actionMessage = "自动拨号失败，USSD 码已复制到剪贴板:\n\(ussd)\n请打开电话App粘贴拨打"
                    self.showActionAlert = true
                }
            }
        }

        // 显示一个短暂的 toast 提示
        copyToastMessage = "正在拨打 \(ussd)…\n（已复制到剪贴板备选）"
        showCopyToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showCopyToast = false
        }
    }

    /// 执行激活转移
    func performActivate() {
        let ussd = SharedSettings.activateUSSD()
        guard !ussd.isEmpty else {
            actionMessage = "请先设置电话号码"
            showActionAlert = true
            return
        }
        dial(ussd, actionName: "开启转移")
    }

    /// 执行关闭转移
    func performDeactivate() {
        let ussd = SharedSettings.deactivateUSSD()
        dial(ussd, actionName: "关闭转移")
    }

    /// 查询转移状态
    func performStatusCheck() {
        let ussd = SharedSettings.statusUSSD()
        dial(ussd, actionName: "查询状态")
    }

    /// 手动复制 USSD 码到剪贴板
    func copyUSSD(_ ussd: String) {
        UIPasteboard.general.string = ussd
        copyToastMessage = "已复制: \(ussd)"
        showCopyToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showCopyToast = false
        }
    }

    /// 保存设置
    func saveSettings() {
        SharedSettings.phoneNumber = phoneNumber
        SharedSettings.forwardingType = forwardingType
        SharedSettings.useCustomCode = useCustomCode
        SharedSettings.customActivateCode = customActivateCode
        SharedSettings.customDeactivateCode = customDeactivateCode
    }
}
