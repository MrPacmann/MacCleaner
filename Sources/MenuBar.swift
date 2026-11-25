import AppKit
import SwiftUI

/// Иконка в меню-баре: свободное место на диске + меню
/// («Открыть Mac Cleaner», «Выйти»). Обновляется раз в минуту
/// и при открытии меню. Включается/выключается в настройках.
@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private var refreshTimer: Timer?

    /// Главное окно приложения (isReleasedWhenClosed = false —
    /// переоткрываем его же после закрытия крестиком)
    weak var mainWindow: NSWindow?

    func apply(enabled: Bool) {
        if enabled {
            if statusItem == nil { create() }
        } else if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }

    private func create() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "internaldrive",
                                   accessibilityDescription: "Mac Cleaner")
            button.imagePosition = .imageLeading
            button.font = NSFont.monospacedDigitSystemFont(
                ofSize: NSFont.systemFontSize, weight: .regular)
        }
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    // MARK: NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
        rebuildMenu(menu)
    }

    // MARK: Данные

    /// Размер Корзины — считается в фоне, чтобы не тормозить открытие меню.
    /// nil — ещё не посчитали или нет доступа.
    private var trashSize: UInt64?

    private func refresh() {
        let caps = Scanner.volumeCapacities()
        statusItem?.button?.title = Format.bytes(caps.free)
        Task {
            let size = await Scanner.duSize(Scanner.trashDir)
            self.trashSize = size > 0 ? size : nil
        }
    }

    private func rebuildMenu(_ menu: NSMenu) {
        menu.removeAllItems()
        let caps = Scanner.volumeCapacities()
        let info = NSMenuItem(
            title: L10n.shared.f("menubar.free", Format.bytes(caps.free), Format.bytes(caps.total)),
            action: nil, keyEquivalent: "")
        info.isEnabled = false
        menu.addItem(info)
        if let trashSize {
            let trash = NSMenuItem(
                title: L10n.shared.f("menubar.trash", Format.bytes(trashSize)),
                action: nil, keyEquivalent: "")
            trash.isEnabled = false
            menu.addItem(trash)
        }
        menu.addItem(.separator())

        let open = NSMenuItem(title: L10n.shared.t("menubar.open"),
                              action: #selector(openApp), keyEquivalent: "")
        open.target = self
        menu.addItem(open)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: L10n.shared.t("menubar.quit"),
                              action: #selector(quitApp), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
    }

    @objc private func openApp() {
        NSApp.activate(ignoringOtherApps: true)
        if let w = mainWindow ?? NSApp.windows.first(where: { $0.canBecomeMain }) {
            w.deminiaturize(nil)
            w.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
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
