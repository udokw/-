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
                    // 处理从 Widget 触发的 URL
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
    @Published var pendingAction: PendingAction = .none

    enum PendingAction {
        case none
        case activate
        case deactivate
        case status
    }

    /// 处理从 Widget 传入的 URL
    /// Widget 通过 callforwarder://activate 等自定义 URL Scheme 唤起 App
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

    /// 执行激活转移
    func performActivate() {
        let ussd = SharedSettings.activateUSSD()
        guard !ussd.isEmpty else {
            actionMessage = "请先设置电话号码"
            showActionAlert = true
            return
        }

        SharedSettings.lastAction = "开启转移"
        SharedSettings.lastActionTime = Date()

        if let telURL = SharedSettings.telURL(for: ussd) {
            actionMessage = "正在拨打: \(ussd)\n请按通话键确认"
            showActionAlert = true

            // 延迟执行，让 Alert 先显示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                UIApplication.shared.open(telURL, options: [:], completionHandler: nil)
            }
        }
    }

    /// 执行关闭转移
    func performDeactivate() {
        let ussd = SharedSettings.deactivateUSSD()

        SharedSettings.lastAction = "关闭转移"
        SharedSettings.lastActionTime = Date()

        if let telURL = SharedSettings.telURL(for: ussd) {
            actionMessage = "正在拨打: \(ussd)\n请按通话键确认"
            showActionAlert = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                UIApplication.shared.open(telURL, options: [:], completionHandler: nil)
            }
        }
    }

    /// 查询转移状态
    func performStatusCheck() {
        let ussd = SharedSettings.statusUSSD()

        SharedSettings.lastAction = "查询状态"
        SharedSettings.lastActionTime = Date()

        if let telURL = SharedSettings.telURL(for: ussd) {
            actionMessage = "正在拨打: \(ussd)\n请按通话键确认"
            showActionAlert = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                UIApplication.shared.open(telURL, options: [:], completionHandler: nil)
            }
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
