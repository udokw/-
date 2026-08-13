import Foundation

// ============================================================
// 共享设置模块 - App 和 Widget 共用
// 通过 App Group UserDefaults 共享配置
// ============================================================

/// 呼叫转移类型
enum ForwardingType: String, CaseIterable, Codable {
    case unconditional = "**21*"      // 无条件转移
    case busy = "**67*"               // 遇忙转移
    case noAnswer = "**61*"           // 无应答转移
    case unreachable = "**62*"        // 不可达转移

    var displayName: String {
        switch self {
        case .unconditional: return "全部转移"
        case .busy: return "遇忙转移"
        case .noAnswer: return "无应答转移"
        case .unreachable: return "不可达转移"
        }
    }

    var deactivateCode: String {
        switch self {
        case .unconditional: return "##21#"
        case .busy: return "##67#"
        case .noAnswer: return "##61#"
        case .unreachable: return "##62#"
        }
    }

    var statusCheckCode: String {
        switch self {
        case .unconditional: return "*#21#"
        case .busy: return "*#67#"
        case .noAnswer: return "*#61#"
        case .unreachable: return "*#62#"
        }
    }
}

/// 共享设置管理器
class SharedSettings {
    /// App Group ID - 需要在 Xcode 中为 App 和 Widget 都启用相同的 App Group
    static let appGroupID = "group.com.callforwarder.shared"

    /// UserDefaults 键
    private enum Keys {
        static let phoneNumber = "phoneNumber"
        static let forwardingType = "forwardingType"
        static let customActivateCode = "customActivateCode"
        static let customDeactivateCode = "customDeactivateCode"
        static let useCustomCode = "useCustomCode"
        static let lastAction = "lastAction"
        static let lastActionTime = "lastActionTime"
    }

    /// 共享 UserDefaults
    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    // MARK: - 电话号码
    static var phoneNumber: String {
        get { defaults.string(forKey: Keys.phoneNumber) ?? "" }
        set { defaults.set(newValue, forKey: Keys.phoneNumber) }
    }

    // MARK: - 转移类型
    static var forwardingType: ForwardingType {
        get {
            let raw = defaults.string(forKey: Keys.forwardingType) ?? ForwardingType.unconditional.rawValue
            return ForwardingType(rawValue: raw) ?? .unconditional
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.forwardingType) }
    }

    // MARK: - 自定义代码
    static var useCustomCode: Bool {
        get { defaults.bool(forKey: Keys.useCustomCode) }
        set { defaults.set(newValue, forKey: Keys.useCustomCode) }
    }

    static var customActivateCode: String {
        get { defaults.string(forKey: Keys.customActivateCode) ?? "**21*" }
        set { defaults.set(newValue, forKey: Keys.customActivateCode) }
    }

    static var customDeactivateCode: String {
        get { defaults.string(forKey: Keys.customDeactivateCode) ?? "##21#" }
        set { defaults.set(newValue, forKey: Keys.customDeactivateCode) }
    }

    // MARK: - 生成 USSD 码

    /// 生成激活转移的完整拨号码
    static func activateUSSD() -> String {
        let number = phoneNumber.replacingOccurrences(of: " ", with: "")
        if number.isEmpty { return "" }

        if useCustomCode {
            // 自定义模式: {prefix}{number}#
            return "\(customActivateCode)\(number)#"
        } else {
            // 标准模式: {type_prefix}{number}#
            return "\(forwardingType.rawValue)\(number)#"
        }
    }

    /// 生成关闭转移的拨号码
    static func deactivateUSSD() -> String {
        if useCustomCode {
            return customDeactivateCode
        } else {
            return forwardingType.deactivateCode
        }
    }

    /// 生成查询转移状态的拨号码
    static func statusUSSD() -> String {
        if useCustomCode {
            return customActivateCode.replacingOccurrences(of: "*", with: "*#").replacingOccurrences(of: "#", with: "") + "#"
        } else {
            return forwardingType.statusCheckCode
        }
    }

    /// 生成 tel: URL
    static func telURL(for ussd: String) -> URL? {
        // tel: URL 需要编码特殊字符
        let encoded = ussd.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ussd
        return URL(string: "tel:\(encoded)")
    }

    // MARK: - 最近操作记录
    static var lastAction: String {
        get { defaults.string(forKey: Keys.lastAction) ?? "" }
        set { defaults.set(newValue, forKey: Keys.lastAction) }
    }

    static var lastActionTime: Date? {
        get { defaults.object(forKey: Keys.lastActionTime) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastActionTime) }
    }

    /// 是否已配置电话号码
    static var isConfigured: Bool {
        !phoneNumber.isEmpty
    }
}
