import SwiftUI

// ============================================================
// 主界面 - 设置转移号码和类型
// ============================================================

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 电话号码设置
                Section {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.accentColor)
                        TextField("输入转移到的电话号码", text: $appState.phoneNumber)
                            .keyboardType(.phonePad)
                            .onChange(of: appState.phoneNumber) { _, _ in
                                appState.saveSettings()
                            }
                    }

                    if !appState.phoneNumber.isEmpty {
                        HStack {
                            Text("预览拨号码")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(SharedSettings.activateUSSD())
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.accentColor)
                        }
                    }
                } header: {
                    Text("转移号码")
                } footer: {
                    Text("输入需要将来电转移到的电话号码，无需加空格或横杠")
                }

                // MARK: - 转移类型
                Section {
                    if !appState.useCustomCode {
                        Picker("转移类型", selection: $appState.forwardingType) {
                            ForEach(ForwardingType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .onChange(of: appState.forwardingType) { _, _ in
                            appState.saveSettings()
                        }

                        HStack {
                            Text("激活码")
                            Spacer()
                            Text("\(appState.forwardingType.rawValue)号码#")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("关闭码")
                            Spacer()
                            Text(appState.forwardingType.deactivateCode)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }

                    Toggle("自定义 USSD 码", isOn: $appState.useCustomCode)
                        .onChange(of: appState.useCustomCode) { _, _ in
                            appState.saveSettings()
                        }

                    if appState.useCustomCode {
                        TextField("自定义激活码前缀", text: $appState.customActivateCode)
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: appState.customActivateCode) { _, _ in
                                appState.saveSettings()
                            }
                        TextField("自定义关闭码", text: $appState.customDeactivateCode)
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: appState.customDeactivateCode) { _, _ in
                                appState.saveSettings()
                            }
                    }
                } header: {
                    Text("转移类型")
                } footer: {
                    Text("标准 GSM 码适用于大多数运营商（移动/联通/电信）。电信部分套餐可能需要自定义码，如 *72* 号码 # / *720#")
                }

                // MARK: - 快捷操作
                Section {
                    if !appState.phoneNumber.isEmpty {
                        Button {
                            appState.performActivate()
                        } label: {
                            HStack {
                                Image(systemName: "phone.arrow.up.right")
                                Text("开启呼叫转移")
                                Spacer()
                                Text(SharedSettings.activateUSSD())
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .foregroundColor(.green)
                        }

                        Button {
                            appState.performDeactivate()
                        } label: {
                            HStack {
                                Image(systemName: "phone.down.fill")
                                Text("关闭呼叫转移")
                                Spacer()
                                Text(SharedSettings.deactivateUSSD())
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .foregroundColor(.red)
                        }
                    }

                    Button {
                        appState.performStatusCheck()
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            Text("查询转移状态")
                            Spacer()
                            Text(SharedSettings.statusUSSD())
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.accentColor)
                    }

                    // 手动复制按钮 - 备选方案
                    if !appState.phoneNumber.isEmpty {
                        Divider()
                        Button {
                            appState.copyUSSD(SharedSettings.activateUSSD())
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("复制激活码到剪贴板")
                            }
                            .foregroundColor(.accentColor)
                        }
                    }
                } header: {
                    Text("快捷操作")
                } footer: {
                    Text("点击按钮直接拨号。如果拨号未弹出，可用「复制激活码」手动粘贴到电话App拨打。")
                }

                // MARK: - 使用说明
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(icon: "rectangle.3.group", title: "添加小组件",
                                desc: "主屏幕长按 → 点击 + → 搜索「呼叫转移」→ 添加。侧载App可能无法显示小组件")
                        InfoRow(icon: "lock.shield", title: "拨号确认",
                                desc: "出于安全限制，每次拨号需手动确认，无法自动拨打")
                        InfoRow(icon: "doc.on.doc", title: "手动备选",
                                desc: "如果点按钮没反应，用复制功能把USSD码复制到剪贴板，打开电话App粘贴拨打")
                        InfoRow(icon: "antenna.radiowaves.left.and.right", title: "运营商支持",
                                desc: "GSM 标准码支持移动/联通，电信部分套餐需自定义")
                    }
                } header: {
                    Text("使用说明")
                }

                // MARK: - 最近操作
                if !SharedSettings.lastAction.isEmpty,
                   let time = SharedSettings.lastActionTime {
                    Section {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            VStack(alignment: .leading) {
                                Text(SharedSettings.lastAction)
                                    .font(.body)
                                Text(time.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text("最近操作")
                    }
                }
            }
            .navigationTitle("呼叫转移")
            .alert("提示", isPresented: $appState.showActionAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(appState.actionMessage)
            }
            .overlay {
                // Toast 提示
                if appState.showCopyToast {
                    VStack {
                        Spacer()
                        Text(appState.copyToastMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.bottom, 50)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: appState.showCopyToast)
                }
            }
        }
    }
}

/// 信息行组件
struct InfoRow: View {
    let icon: String
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 预览
#Preview {
    ContentView()
        .environmentObject(AppState())
}
