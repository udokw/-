import WidgetKit
import SwiftUI

// ============================================================
// 呼叫转移小组件
// 使用 Link 打开 App 的 URL Scheme 来触发操作
// 兼容 iOS 16+，不需要 AppIntent
// ============================================================

/// 小组件配置
struct CallForwarderWidget: Widget {
    let kind: String = "CallForwarderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CallForwarderWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("呼叫转移")
        .description("一键开启或关闭呼叫转移")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
        ])
    }
}

/// 时间线提供者
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), isConfigured: true, phoneNumber: "138****8888")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let number = SharedSettings.phoneNumber
        let masked = Self.maskPhoneNumber(number)
        completion(SimpleEntry(date: Date(), isConfigured: !number.isEmpty, phoneNumber: masked))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let number = SharedSettings.phoneNumber
        let masked = Self.maskPhoneNumber(number)
        let entry = SimpleEntry(date: Date(), isConfigured: !number.isEmpty, phoneNumber: masked)
        completion(Timeline(entries: [entry], policy: .never))
    }

    private static func maskPhoneNumber(_ number: String) -> String {
        guard number.count >= 7 else { return number }
        let start = number.prefix(3)
        let end = number.suffix(4)
        return "\(start)****\(end)"
    }
}

/// Timeline Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let isConfigured: Bool
    let phoneNumber: String
}

// MARK: - 小组件视图

struct CallForwarderWidgetView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - 小尺寸小组件

struct SmallWidgetView: View {
    let entry: SimpleEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "phone.arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                Text("呼叫转移")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)

            Spacer()

            if entry.isConfigured {
                HStack(spacing: 8) {
                    // 开启按钮 - 用 Link 打开 URL Scheme
                    Link(destination: URL(string: "callforwarder://activate")!) {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.up.right.circle.fill")
                                .font(.system(size: 20))
                            Text("开启")
                                .font(.system(size: 10, weight: .medium))
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.green.opacity(0.9))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // 关闭按钮
                    Link(destination: URL(string: "callforwarder://deactivate")!) {
                        VStack(spacing: 2) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                            Text("关闭")
                                .font(.system(size: 10, weight: .medium))
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                Link(destination: URL(string: "callforwarder://open")!) {
                    VStack(spacing: 4) {
                        Image(systemName: "gear")
                            .font(.system(size: 24))
                        Text("未配置号码")
                            .font(.system(size: 11))
                        Text("打开 App 设置")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
            }

            Spacer()

            if entry.isConfigured {
                Text("→ \(entry.phoneNumber)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(10)
    }
}

// MARK: - 中尺寸小组件

struct MediumWidgetView: View {
    let entry: SimpleEntry

    var body: some View {
        HStack(spacing: 12) {
            // 左侧：信息区
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "phone.arrow.up.right")
                        .font(.system(size: 14, weight: .semibold))
                    Text("呼叫转移")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)

                if entry.isConfigured {
                    Text("转移至")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                    Text(entry.phoneNumber)
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)

                    if let time = SharedSettings.lastActionTime,
                       !SharedSettings.lastAction.isEmpty {
                        Text("\(SharedSettings.lastAction) · \(time.formatted(.relative(presentation: .named)))")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    Text("未配置")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    Text("打开 App 设置号码")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()
            }

            Spacer()

            // 右侧：按钮区
            VStack(spacing: 8) {
                Link(destination: URL(string: "callforwarder://activate")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 16))
                        Text("开启转移")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .frame(width: 100, height: 36)
                .background(Color.green.opacity(0.9))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Link(destination: URL(string: "callforwarder://deactivate")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                        Text("关闭转移")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .frame(width: 100, height: 36)
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Link(destination: URL(string: "callforwarder://status")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 14))
                        Text("查询状态")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .frame(width: 100, height: 30)
                .background(Color.white.opacity(0.2))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxHeight: .infinity)
        }
        .padding(12)
    }
}

// MARK: - 预览
#Preview(as: .systemSmall) {
    CallForwarderWidget()
} timeline: {
    SimpleEntry(date: Date(), isConfigured: true, phoneNumber: "138****8888")
    SimpleEntry(date: Date(), isConfigured: false, phoneNumber: "")
}

#Preview(as: .systemMedium) {
    CallForwarderWidget()
} timeline: {
    SimpleEntry(date: Date(), isConfigured: true, phoneNumber: "138****8888")
}
