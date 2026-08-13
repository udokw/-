import AppIntents
import UIKit

// ============================================================
// App Intents - Siri 和快捷指令支持
// Widget 通过 Link + URL Scheme 触发，不依赖这些 Intent
// ============================================================

/// 激活呼叫转移 Intent
struct ActivateForwardingIntent: AppIntent {
    static var title: LocalizedStringResource = "开启呼叫转移"
    static var description = IntentDescription("一键拨打 USSD 码激活呼叫转移")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        let ussd = SharedSettings.activateUSSD()
        guard !ussd.isEmpty else {
            return .result(dialog: "请先在 App 中设置电话号码")
        }

        SharedSettings.lastAction = "开启转移"
        SharedSettings.lastActionTime = Date()

        if let telURL = SharedSettings.telURL(for: ussd) {
            _ = await UIApplication.shared.open(telURL)
        }

        return .result(dialog: "正在拨打 \(ussd)，请确认")
    }
}

/// 关闭呼叫转移 Intent
struct DeactivateForwardingIntent: AppIntent {
    static var title: LocalizedStringResource = "关闭呼叫转移"
    static var description = IntentDescription("一键拨打 USSD 码关闭呼叫转移")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        let ussd = SharedSettings.deactivateUSSD()

        SharedSettings.lastAction = "关闭转移"
        SharedSettings.lastActionTime = Date()

        if let telURL = SharedSettings.telURL(for: ussd) {
            _ = await UIApplication.shared.open(telURL)
        }

        return .result(dialog: "正在拨打 \(ussd)，请确认")
    }
}

/// 查询转移状态 Intent
struct CheckStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "查询转移状态"
    static var description = IntentDescription("查询当前呼叫转移状态")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        let ussd = SharedSettings.statusUSSD()

        SharedSettings.lastAction = "查询状态"
        SharedSettings.lastActionTime = Date()

        if let telURL = SharedSettings.telURL(for: ussd) {
            _ = await UIApplication.shared.open(telURL)
        }

        return .result(dialog: "正在拨打 \(ussd)，请确认")
    }
}

// ============================================================
// App Shortcuts - Siri 语音支持
// ============================================================

struct CallForwarderShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ActivateForwardingIntent(),
            phrases: [
                "激活呼叫转移 \(.applicationName)",
                "开启呼叫转移",
                "转移来电"
            ],
            shortTitle: "开启呼叫转移",
            systemImageName: "phone.arrow.up.right"
        )
        AppShortcut(
            intent: DeactivateForwardingIntent(),
            phrases: [
                "取消呼叫转移 \(.applicationName)",
                "关闭呼叫转移"
            ],
            shortTitle: "关闭呼叫转移",
            systemImageName: "phone.down.fill"
        )
    }
}
