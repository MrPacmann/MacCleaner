import AppKit
import SwiftUI

/// Иконка приложения в меню-баре. По клику — popover-панель
/// с живыми метриками (CPU, память, диск, батарея, сеть)
/// и кнопками «Открыть» / «Выйти». Включается в настройках.
@MainActor
final class MenuBarController: NSObject {
    static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    /// Таймер автоскрытия панели
    private var closeTimer: Timer?
    /// Через сколько секунд панель закрывается сама
    private let autoCloseAfter: TimeInterval = 10

    // Анимация иконки: скорость зависит от загрузки CPU
    private var animTimer: Timer?
    private var animStart = Date()
    private var animTickCount = 0

    /// Выбранный стиль иконки (настраивается в Настройках)
    var iconStyle: MenuBarIconStyle =
        MenuBarIconStyle(rawValue: UserDefaults.standard.string(forKey: "menuBarIconStyle") ?? "trash") ?? .trash

    /// Общий источник метрик для панели
    let monitor = MonitorState()

    /// Главное окно приложения (isReleasedWhenClosed = false —
    /// переоткрываем его же после закрытия крестиком)
    weak var mainWindow: NSWindow?

    func apply(enabled: Bool) {
        if enabled {
            if statusItem == nil { create() }
        } else if let item = statusItem {
            closePopover()
            popover = nil
            animTimer?.invalidate()
            animTimer = nil
            monitor.stopAutoRefresh()
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    private func create() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = iconStyle.image(t: 0, cpu: 0)
            button.imagePosition = .imageOnly
            button.action = #selector(togglePopover)
            button.target = self
        }
        statusItem = item
        animStart = Date()
        animTimer?.invalidate()
        animTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.animTick() }
        }
        // Метрики — от единого таймера MonitorState (общий с окном и панелью)
        monitor.startAutoRefresh()
    }

    /// Кадр анимации: иконку рисует выбранный стиль; скорость — от загрузки CPU.
    /// Метрики здесь больше не обновляем — за это отвечает MonitorState.startAutoRefresh().
    private func animTick() {
        animTickCount += 1
        guard let button = statusItem?.button else { return }
        let t = Date().timeIntervalSince(animStart)
        button.image = iconStyle.image(t: t, cpu: monitor.cpuUsage)
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if let popover, popover.isShown {
            closePopover()
            return
        }
        let pop = NSPopover()
        pop.behavior = .transient          // закрывается по клику мимо
        pop.animates = true
        pop.contentViewController = NSHostingController(rootView: MenuBarPanelView(monitor: monitor))
        pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover = pop
        // Автоскрытие через autoCloseAfter секунд
        closeTimer?.invalidate()
        closeTimer = Timer.scheduledTimer(withTimeInterval: autoCloseAfter, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.closePopover() }
        }
    }

    private func closePopover() {
        closeTimer?.invalidate()
        closeTimer = nil
        popover?.performClose(nil)
    }

    func openApp() {
        closePopover()
        NSApp.activate(ignoringOtherApps: true)
        if let w = mainWindow ?? NSApp.windows.first(where: { $0.canBecomeMain }) {
            w.deminiaturize(nil)
            w.makeKeyAndOrderFront(nil)
        }
    }

    func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Панель метрик (popover)

struct MenuBarPanelView: View {
    let monitor: MonitorState

    var body: some View {
        VStack(spacing: 0) {
            cpuSection
            divider
            memorySection
            divider
            diskSection
            divider
            batterySection
            divider
            networkSection
            divider
            footer
        }
        .padding(.vertical, 6)
        .frame(width: 292)
        .onAppear { monitor.startAutoRefresh() }
        .onDisappear { monitor.stopAutoRefresh() }
    }

    private var divider: some View {
        Divider().padding(.vertical, 6)
    }

    // MARK: Секции

    private var cpuSection: some View {
        PanelSection(icon: "cpu", iconColor: Color(red: 0.55, green: 0.72, blue: 0.95),
                     title: "\(L10n.shared.t("mon.cpu")): \(Int(monitor.cpuUsage * 100))%") {
            Text(L10n.shared.f("mon.loadAvg",
                               String(format: "%.2f", monitor.loadAvg.0),
                               String(format: "%.2f", monitor.loadAvg.1),
                               String(format: "%.2f", monitor.loadAvg.2)))
            Text(L10n.shared.f("mon.cores", monitor.coreCount))
            MiniBar(value: monitor.cpuUsage, color: Color(red: 0.55, green: 0.72, blue: 0.95))
                .padding(.top, 2)
        }
    }

    private var memorySection: some View {
        let pct = monitor.memTotal > 0 ? Int(Double(monitor.memUsed) / Double(monitor.memTotal) * 100) : 0
        return PanelSection(icon: "memorychip", iconColor: Color(red: 0.42, green: 0.84, blue: 0.72),
                            title: "\(L10n.shared.t("mon.memory")): \(pct)%") {
            Text(L10n.shared.f("mon.usedOf", Format.bytes(monitor.memUsed), Format.bytes(monitor.memTotal)))
            Text(L10n.shared.f("mon.swap", Format.bytes(monitor.swapUsed)))
            MiniBar(value: Double(pct) / 100, color: Color(red: 0.42, green: 0.84, blue: 0.72))
                .padding(.top, 2)
        }
    }

    private var diskSection: some View {
        let usedPct = monitor.diskTotal > 0
            ? Int((1.0 - Double(monitor.diskFree) / Double(monitor.diskTotal)) * 100) : 0
        return PanelSection(icon: "internaldrive", iconColor: Theme.accent,
                            title: "\(L10n.shared.t("mon.disk")): \(usedPct)%") {
            Text(L10n.shared.f("mon.freeOf", Format.bytes(monitor.diskFree), Format.bytes(monitor.diskTotal)))
            MiniBar(value: Double(usedPct) / 100, color: Theme.accent)
                .padding(.top, 2)
            if let trash = monitor.trashSize {
                Text(L10n.shared.f("menubar.trash", Format.bytes(trash)))
            }
        }
    }

    private var batterySection: some View {
        PanelSection(icon: monitor.hasBattery
                     ? (monitor.batteryCharging ? "battery.100percent.bolt" : "battery.75percent")
                     : "bolt.fill",
                     iconColor: Color(red: 0.86, green: 0.89, blue: 0.45),
                     title: monitor.hasBattery
                        ? "\(L10n.shared.t("mon.battery")): \(monitor.batteryLevel)%"
                        : L10n.shared.t("mon.battery")) {
            if monitor.hasBattery {
                Text(L10n.shared.t(monitor.batteryCharging ? "mon.charging" : "mon.discharging"))
                MiniBar(value: Double(monitor.batteryLevel) / 100,
                        color: Color(red: 0.86, green: 0.89, blue: 0.45))
                    .padding(.top, 2)
            } else {
                Text(L10n.shared.t("mon.noBattery"))
            }
            Text("\(L10n.shared.t("mon.thermal")): \(monitor.thermalTitle)")
        }
    }

    private var networkSection: some View {
        PanelSection(icon: "network", iconColor: Color(red: 0.60, green: 0.55, blue: 0.97),
                     title: L10n.shared.t("mb.network")) {
            if let ip = monitor.localIP {
                Text(L10n.shared.f("mb.ip", ip))
                Text(L10n.shared.f("mb.down", Format.bytes(monitor.netDown)))
                Text(L10n.shared.f("mb.up", Format.bytes(monitor.netUp)))
            } else {
                Text(L10n.shared.t("mb.offline"))
            }
        }
    }

    // MARK: Кнопки

    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                MenuBarController.shared.openApp()
            } label: {
                Text(L10n.shared.t("menubar.open"))
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 9))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Button {
                MenuBarController.shared.quitApp()
            } label: {
                Text(L10n.shared.t("menubar.quit"))
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, 2)
        .padding(.bottom, 6)
    }
}

/// Одна секция панели: иконка слева, заголовок и строки деталей
struct PanelSection<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 34, alignment: .center)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .monospacedDigit()
                content
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
    }
}

// MARK: - Захват главного окна (чтобы меню-бар мог его переоткрыть)

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isReleasedWhenClosed = false
            MenuBarController.shared.mainWindow = window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
