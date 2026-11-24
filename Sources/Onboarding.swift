import SwiftUI
import AppKit

/// Экран первого запуска: что умеет приложение + выдача
/// Полного доступа к диску. Показывается один раз (UserDefaults).
struct OnboardingCard: View {
    let close: () -> Void

    @State private var granted = Permissions.fullDiskAccess == .granted

    var body: some View {
        VStack(spacing: 0) {
            // Иконка и приветствие
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 17))
                .shadow(color: Theme.accent.opacity(0.35), radius: 16, y: 6)

            Text(L10n.shared.t("ob.welcome"))
                .font(.title2.weight(.bold))
                .padding(.top, 14)
            Text(L10n.shared.t("ob.subtitle"))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)

            // Возможности
            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "chart.pie", color: Theme.accent, key: "ob.f1")
                featureRow(icon: "doc.magnifyingglass", color: Theme.success, key: "ob.f2")
                featureRow(icon: "arrow.uturn.backward", color: Color(red: 0.96, green: 0.72, blue: 0.45), key: "ob.f3")
            }
            .padding(.top, 20)

            Divider().padding(.vertical, 18)

            // Полный доступ к диску
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(L10n.shared.t("ob.perm"))
                        .font(.callout.weight(.semibold))
                    if granted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.success)
                            .font(.callout)
                    }
                }
                Text(L10n.shared.t("ob.permDesc"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Кнопки
            HStack(spacing: 10) {
                if !granted {
                    GhostButton(title: L10n.shared.t("ob.grant")) {
                        Permissions.openSettings(pane: "Privacy_AllFiles")
                    }
                }
                Spacer()
                Button(action: close) {
                    Text(L10n.shared.t("ob.start"))
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24).padding(.vertical, 9)
                        .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 10))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 18)
        }
        .padding(26)
        .frame(width: 440)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.stroke))
        .shadow(color: .black.opacity(0.35), radius: 30, y: 12)
        .onReceive(NotificationCenter.default.publisher(
            for: NSApplication.didBecomeActiveNotification)) { _ in
            granted = Permissions.fullDiskAccess == .granted
        }
    }

    func featureRow(icon: String, color: Color, key: String) -> some View {
        HStack(spacing: 12) {
            IconTile(symbol: icon, color: color, size: 34)
            Text(L10n.shared.t(key))
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
