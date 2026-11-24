import Foundation
import AppKit

/// Проверка и установка обновлений через GitHub Releases:
/// сравнивает tag_name последнего релиза с CFBundleShortVersionString,
/// умеет скачать DMG-ассет и заменить себя новой версией.
@MainActor
@Observable
final class UpdateChecker {
    enum State: Equatable {
        case idle
        case checking
        case current
        case available(version: String)
        case failed
    }

    /// Стадии установки скачанного обновления
    enum InstallState: Equatable {
        case idle
        case downloading
        case installing
        case ready          // установлено, осталось перезапустить
        case failed
    }

    static let shared = UpdateChecker()

    /// Репозиторий с релизами
    static let repoAPI = "https://api.github.com/repos/MrPacmann/MacCleaner/releases/latest"

    var state: State = .idle
    var installState: InstallState = .idle
    var releaseURL: URL? = nil
    private var dmgAssetURL: URL? = nil

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// silent — фоновая проверка при запуске: ошибки не показываем
    func check(silent: Bool = false) async {
        state = .checking
        guard let url = URL(string: Self.repoAPI) else { state = .failed; return }
        var req = URLRequest(url: url)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 10
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String else {
                state = silent ? .idle : .failed
                return
            }
            let latest = tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV \t"))
            releaseURL = (json["html_url"] as? String).flatMap(URL.init)
            // Ассет с DMG для автоустановки
            let assets = json["assets"] as? [[String: Any]] ?? []
            dmgAssetURL = assets
                .first { ($0["name"] as? String)?.hasSuffix(".dmg") == true }
                .flatMap { $0["browser_download_url"] as? String }
                .flatMap(URL.init)
            state = Self.isNewer(latest, than: currentVersion)
                ? .available(version: latest) : .current
        } catch {
            state = silent ? .idle : .failed
        }
    }

    /// Сравнение версий вида 1.2.3 (любой длины): 1.3 > 1.2.5
    static func isNewer(_ a: String, than b: String) -> Bool {
        let pa = a.split(separator: ".").compactMap { Int($0) }
        let pb = b.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(pa.count, pb.count) {
            let x = i < pa.count ? pa[i] : 0
            let y = i < pb.count ? pb[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    func openReleasePage() {
        if let releaseURL {
            NSWorkspace.shared.open(releaseURL)
        }
    }

    // MARK: - Скачивание и установка обновления

    /// Скачивает DMG из релиза, монтирует и заменяет текущий .app новым.
    /// Старое приложение уходит в резервную копию рядом (удаляется после успеха).
    func downloadAndInstall() async {
        guard let asset = dmgAssetURL else { installState = .failed; return }
        installState = .downloading
        let fm = FileManager.default
        let tmpDmg = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("MacCleaner-update.dmg")
        try? fm.removeItem(at: tmpDmg)

        do {
            // 1. Скачать (URLSession не ставит карантин — Gatekeeper не вмешается)
            let (dl, resp) = try await URLSession.shared.download(from: asset)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw UpdateError.download }
            try fm.moveItem(at: dl, to: tmpDmg)

            installState = .installing

            // 2. Смонтировать DMG
            let mount = try Self.mountDMG(at: tmpDmg)
            defer { _ = try? Self.run("/usr/bin/hdiutil", ["detach", mount, "-quiet"]) }
            let newApp = URL(fileURLWithPath: mount).appendingPathComponent("MacCleaner.app")
            guard fm.fileExists(atPath: newApp.path) else { throw UpdateError.install }

            // 3. Заменить себя (со страховкой и откатом)
            let target = Bundle.main.bundleURL
            let backup = target.deletingLastPathComponent()
                .appendingPathComponent(".MacCleaner-backup.app")
            try? fm.removeItem(at: backup)
            try fm.moveItem(at: target, to: backup)
            do {
                try fm.copyItem(at: newApp, to: target)
            } catch {
                try? fm.moveItem(at: backup, to: target)
                throw UpdateError.install
            }
            try? fm.removeItem(at: backup)

            // 4. На всякий случай снять карантин и переподписать ad-hoc
            _ = try? Self.run("/usr/bin/xattr", ["-dr", "com.apple.quarantine", target.path])

            try? fm.removeItem(at: tmpDmg)
            installState = .ready
        } catch {
            try? fm.removeItem(at: tmpDmg)
            installState = .failed
        }
    }

    /// Перезапуск из той же папки, где лежит приложение
    func relaunch() {
        let target = Bundle.main.bundleURL.path
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        p.arguments = ["-n", target]
        try? p.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            NSApp.terminate(nil)
        }
    }

    // MARK: - Утилиты

    enum UpdateError: Error { case download, install, mount }

    /// Монтирует DMG и возвращает точку монтирования
    static func mountDMG(at dmg: URL) throws -> String {
        let (out, code) = try run("/usr/bin/hdiutil",
                                  ["attach", "-nobrowse", "-readonly", "-plist", dmg.path])
        guard code == 0,
              let plist = try PropertyListSerialization.propertyList(from: out, format: nil) as? [String: Any],
              let entities = plist["system-entities"] as? [[String: Any]],
              let mount = entities.compactMap({ $0["mount-point"] as? String }).first
        else { throw UpdateError.mount }
        return mount
    }

    /// Запуск утилиты и ожидание завершения; возвращает stdout и код выхода
    @discardableResult
    static func run(_ launch: String, _ args: [String]) throws -> (Data, Int32) {
        let p = Process()
        let pipe = Pipe()
        p.executableURL = URL(fileURLWithPath: launch)
        p.arguments = args
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        try p.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (data, p.terminationStatus)
    }
}

// MARK: - Установка в «Программы»

enum AppInstaller {
    /// Приложение запущено уже из /Applications
    static var isInApplications: Bool {
        Bundle.main.bundleURL.deletingLastPathComponent().path == "/Applications"
    }

    /// Копирует себя в /Applications, запускает оттуда новую копию и завершает текущую.
    /// Старая версия в /Applications (если была) уходит в Корзину.
    static func installToApplications() async -> Bool {
        let fm = FileManager.default
        let src = Bundle.main.bundleURL
        let dst = URL(fileURLWithPath: "/Applications/MacCleaner.app")
        do {
            if fm.fileExists(atPath: dst.path) {
                var resulting: NSURL?
                try fm.trashItem(at: dst, resultingItemURL: &resulting)
            }
            try fm.copyItem(at: src, to: dst)
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            p.arguments = ["-n", dst.path]
            try p.run()
            try? await Task.sleep(for: .milliseconds(600))
            await NSApp.terminate(nil)
            return true
        } catch {
            return false
        }
    }
}
