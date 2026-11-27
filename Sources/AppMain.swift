import SwiftUI
import AppKit

@main
struct MacCleanerApp: App {
    @State private var model = CleanerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .frame(minWidth: 960, minHeight: 620)
                .preferredColorScheme(model.colorScheme)
                .task {
                    model.loadHistory()
                    model.applyDockPolicy()
                    MenuBarController.shared.apply(enabled: model.menuBarEnabled)
                    Task { await UpdateChecker.shared.check(silent: true) }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 700)
        .defaultPosition(.center)
        .commands {
            CommandMenu(L10n.shared.t("menu.navigate")) {
                ForEach(AppSection.allCases) { section in
                    if let key = section.shortcutKey {
                        Button(L10n.shared.t(section.titleKey)) { model.section = section }
                            .keyboardShortcut(key, modifiers: .command)
                    }
                }
                Divider()
                Button(L10n.shared.t("menu.find.search")) { model.searchFocusRequest += 1 }
                    .keyboardShortcut("f", modifiers: .command)
            }
        }
    }
}

struct ContentView: View {
    @Environment(CleanerViewModel.self) private var model
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboardingDone")

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
                .frame(width: 224)

            VStack(spacing: 0) {
                // Верхняя строка: имя тома + статус
                HStack {
                    Text("Macintosh HD")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    StatusPill()
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 6)

                detailView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .bottom) {
                        if !model.selected.isEmpty {
                            SelectionBar()
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
            }
            .background(Theme.bg)
        }
        .background(Theme.bg)
        .background(WindowAccessor())
        .overlay {
            if showOnboarding {
                DialogScrim {
                    OnboardingCard {
                        UserDefaults.standard.set(true, forKey: "onboardingDone")
                        withAnimation(.easeOut(duration: 0.2)) { showOnboarding = false }
                    }
                }
                .transition(.opacity)
            }
            if model.showTrashConfirm {
                DialogScrim {
                    ConfirmDialog(
                        icon: "trash", iconColor: Theme.accent,
                        title: L10n.shared.t("dlg.trashTitle"),
                        subtitle: L10n.shared.f("misc.filesCount", model.selected.count, Format.bytes(model.selectedSize)),
                        note: L10n.shared.t("dlg.trashNote"),
                        confirmTitle: L10n.shared.f("dlg.confirmTrash", Format.bytes(model.selectedSize)),
                        onConfirm: {
                            model.showTrashConfirm = false
                            Task { await model.trashSelected() }
                        },
                        onCancel: { model.showTrashConfirm = false })
                }
            }
            if model.showEmptyTrashConfirm {
                DialogScrim {
                    ConfirmDialog(
                        icon: "exclamationmark.triangle", iconColor: Theme.danger,
                        title: L10n.shared.t("dlg.emptyTrashTitle"),
                        subtitle: L10n.shared.f("misc.filesCount", model.trashCategory.items.count, Format.bytes(model.trashCategory.total)),
                        note: L10n.shared.t("dlg.emptyTrashNote"),
                        confirmTitle: L10n.shared.t("dlg.confirmEmpty"),
                        confirmColor: Theme.danger,
                        onConfirm: {
                            model.showEmptyTrashConfirm = false
                            Task { await model.emptyTrash() }
                        },
                        onCancel: { model.showEmptyTrashConfirm = false })
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toast = model.toast {
                ToastCard(text: toast) {
                    NSWorkspace.shared.open(URL(fileURLWithPath: Scanner.trashDir))
                    model.toast = nil
                }
                .padding(.bottom, model.selected.isEmpty ? 20 : 88)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.25), value: model.toast)
        .animation(.easeOut(duration: 0.2), value: model.selected.isEmpty)
        .animation(.easeOut(duration: 0.2), value: model.showTrashConfirm)
        .animation(.easeOut(duration: 0.2), value: model.showEmptyTrashConfirm)
    }

    @ViewBuilder
    var detailView: some View {
        switch model.section {
        case .overview: OverviewView()
        case .largeFiles: LargeFilesView()
        case .folders: FoldersView()
        case .map: MapView()
        case .duplicates: DuplicatesView()
        case .apps: AppsView()
        case .downloads: DownloadsView()
        case .junk: JunkView()
        case .startup: StartupView()
        case .extensions: ExtensionsView()
        case .trash: TrashView()
        case .history: HistoryView()
        case .monitor: MonitorView()
        case .settings: SettingsView()
        }
    }
}

// MARK: - Затемнение под диалогом

struct DialogScrim<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
            content
        }
    }
}

// MARK: - Зелёный тост об успехе

struct ToastCard: View {
    let text: String
    let openTrash: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.success)
            VStack(alignment: .leading, spacing: 1) {
                Text(text)
                    .font(.callout.weight(.semibold))
                Text(L10n.shared.t("toast.restorable"))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(L10n.shared.t("btn.openTrash"), action: openTrash)
                .buttonStyle(.plain)
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .frame(maxWidth: 560)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.success.opacity(0.35)))
        .shadow(color: .black.opacity(0.25), radius: 16, y: 6)
        .padding(.horizontal, 24)
    }
}

// MARK: - Сайдбар (кастомный, по макету)

struct SidebarView: View {
    @Environment(CleanerViewModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Логотип и имя
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("Mac Cleaner").font(.headline)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 18)

            Text("MACINTOSH HD")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 18)
                .padding(.bottom, 6)

            VStack(spacing: 2) {
                ForEach(AppSection.allCases.filter { $0 != .settings }) { section in
                    SidebarRow(section: section)
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            Divider().padding(.horizontal, 14)
            SidebarRow(section: .settings)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        }
        .background(Color.primary.opacity(0.025))
    }
}

// MARK: - Переключатель тёмной/светлой темы

struct ThemeSwitcher: View {
    @Environment(CleanerViewModel.self) private var model

    var body: some View {
        HStack(spacing: 4) {
            themeButton(value: "system", icon: "circle.lefthalf.filled", labelKey: "theme.system")
            themeButton(value: "light", icon: "sun.max", labelKey: "theme.light")
            themeButton(value: "dark", icon: "moon", labelKey: "theme.dark")
        }
        .padding(3)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.stroke))
    }

    func themeButton(value: String, icon: String, labelKey: String) -> some View {
        let active = model.theme == value
        return Button {
            withAnimation(.easeOut(duration: 0.15)) { model.theme = value }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(L10n.shared.t(labelKey))
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(active ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(active ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SidebarRow: View {
    @Environment(CleanerViewModel.self) private var model
    let section: AppSection

    var isActive: Bool { model.section == section }

    var badge: Int? {
        switch section {
        case .largeFiles:
            let n = model.disk.largeFiles.count
            return n > 0 ? n : nil
        case .duplicates:
            let n = model.dupes.groups.count
            return n > 0 ? n : nil
        default: return nil
        }
    }

    var body: some View {
        Button {
            model.section = section
        } label: {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.system(size: 13))
                    .frame(width: 20)
                    .foregroundStyle(isActive ? Theme.accent : .secondary)
                Text(L10n.shared.t(section.titleKey))
                    .font(.callout.weight(isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? .primary : .secondary)
                Spacer()
                if let badge {
                    Text("\(badge)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Theme.accent.opacity(0.18) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(section.shortcutHint ?? "")
    }
}
