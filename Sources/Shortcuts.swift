import AppIntents

/// Команды для приложения «Быстрые команды» (Shortcuts) и Siri:
/// «Начать сканирование» и «Очистить корзину».
/// Интенты выполняются внутри запущенного приложения (openAppWhenRun).

/// Ждём, пока приложение поднимет модель (система могла запустить нас ради интента)
@MainActor
private func awaitModel() async -> CleanerViewModel? {
    for _ in 0..<30 { // до 3 секунд
        if let model = CleanerViewModel.shared { return model }
        try? await Task.sleep(for: .milliseconds(100))
    }
    return nil
}

// MARK: - Начать сканирование

struct StartScanIntent: AppIntent {
    static var title: LocalizedStringResource = "Начать сканирование диска"
    static var description = IntentDescription("Полное сканирование диска в Mac Cleaner")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let model = await awaitModel() else {
            return .result(dialog: "Mac Cleaner не отвечает")
        }
        await model.runDeepScan(force: true)
        let free = Format.bytes(model.disk.volumeFree)
        let msg = L10n.shared.lang == "en"
            ? "Scan complete. \(free) free."
            : "Сканирование завершено. Свободно \(free)."
        return .result(dialog: IntentDialog(stringLiteral: msg))
    }
}

// MARK: - Очистить корзину

struct EmptyTrashIntent: AppIntent {
    static var title: LocalizedStringResource = "Очистить корзину"
    static var description = IntentDescription("Очищает Корзину через Mac Cleaner")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let model = await awaitModel() else {
            return .result(dialog: "Mac Cleaner не отвечает")
        }
        await model.emptyTrash()
        return .result(dialog: IntentDialog(stringLiteral: L10n.shared.t("toast.trashEmptied")))
    }
}

// MARK: - Регистрация в Shortcuts

struct MacCleanerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartScanIntent(),
            phrases: [
                "Начать сканирование в \(.applicationName)",
                "Просканируй диск в \(.applicationName)",
                "Scan disk in \(.applicationName)"
            ],
            shortTitle: "Сканировать диск",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: EmptyTrashIntent(),
            phrases: [
                "Очисти корзину в \(.applicationName)",
                "Empty Trash in \(.applicationName)"
            ],
            shortTitle: "Очистить корзину",
            systemImageName: "trash"
        )
    }
}
