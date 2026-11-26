import Foundation
import AppKit
import CryptoKit
import UniformTypeIdentifiers

struct ScanResult {
    var items: [CleanItem]
    var denied: Bool
}

struct DeepScanResult: Codable {
    var byCategory: [FileCategory: UInt64]
    var large: [LargeFile]
    var dupeCandidates: [LargeFile]
    var topByCategory: [FileCategory: [LargeFile]]
    /// Самые тяжёлые папки (агрегировано по директориям глубиной 2–3)
    var topFolders: [LargeFile]
    /// Размеры папок глубиной 1 от домашней (корень карты диска)
    var topLevel: [String: UInt64]
    /// Размеры папок глубиной 2–3 (детализация карты диска)
    var folderSizes: [String: UInt64]
}

enum ScanError: LocalizedError {
    case unknownCategory
    var errorDescription: String? {
        switch self { case .unknownCategory: return "Неизвестная категория" }
    }
}

enum Scanner {
    static let home = FileManager.default.homeDirectoryForCurrentUser.path
    static let trashDir = home + "/.Trash"

    // MARK: - Категории мусора (как в первой версии)

    static func scan(id: String) async throws -> ScanResult {
        switch id {
        case "caches":
            return ScanResult(items: await scanChildren(of: home + "/Library/Caches", note: nil), denied: false)
        case "logs":
            return ScanResult(items: await scanChildren(of: home + "/Library/Logs", note: nil), denied: false)
        case "xcode":
            let dd = await scanChildren(of: home + "/Library/Developer/Xcode/DerivedData",
                                        note: "DerivedData — пересоздаётся при сборке")
            let sim = await scanChildren(of: home + "/Library/Developer/CoreSimulator/Caches",
                                         note: "Кэш симулятора")
            return ScanResult(items: (dd + sim).sorted { $0.size > $1.size }, denied: false)
        case "pkgman":
            return ScanResult(items: await scanPackageCaches(), denied: false)
        case "node_modules":
            return ScanResult(items: await scanNodeModules(), denied: false)
        case "downloads":
            return ScanResult(items: await scanOldDownloads(), denied: false)
        case "trash":
            return await scanTrash()
        case "mobilesync":
            return ScanResult(items: await scanMobileBackups(), denied: false)
        case "mail":
            return await scanMailAttachments()
        case "projjunk":
            return ScanResult(items: await scanProjectJunk(), denied: false)
        case "docker":
            return ScanResult(items: await scanDockerData(), denied: false)
        case "crashlogs":
            return ScanResult(items: await scanChildren(of: home + "/Library/Logs/DiagnosticReports",
                                                        note: nil, minSize: 4 * 1024), denied: false)
        case "partial":
            return ScanResult(items: await scanPartialDownloads(), denied: false)
        case "plist":
            return ScanResult(items: await scanBrokenPlists(), denied: false)
        case "privacy":
            return ScanResult(items: await scanPrivacy(), denied: false)
        default:
            throw ScanError.unknownCategory
        }
    }

    /// Бэкапы iPhone/iPad: ~/Library/Application Support/MobileSync/Backup/*
    static func scanMobileBackups() async -> [CleanItem] {
        let root = home + "/Library/Application Support/MobileSync/Backup"
        let keys: [URLResourceKey] = [.isDirectoryKey, .contentModificationDateKey]
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: root), includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]) else { return [] }
        var items: [CleanItem] = []
        for url in urls {
            guard let vals = try? url.resourceValues(forKeys: Set(keys)),
                  vals.isDirectory == true else { continue }
            let p = url.path
            let size = await duSize(p)
            if size < 64 * 1024 { continue }
            // Имя устройства и дата — из Info.plist внутри бэкапа
            var device: String? = nil
            var mtime: Date? = nil
            if let plist = NSDictionary(contentsOfFile: (p as NSString).appendingPathComponent("Info.plist")) {
                device = plist["Device Name"] as? String
                mtime = plist["Last Backup Date"] as? Date
            }
            if mtime == nil { mtime = vals.contentModificationDate }
            items.append(CleanItem(path: p,
                                   name: device ?? "Бэкап \(url.lastPathComponent.prefix(8))…",
                                   size: size, mtime: mtime, isDir: true,
                                   note: L10n.shared.t("backups.note")))
        }
        return items.sorted { $0.size > $1.size }
    }

    static func scanChildren(of root: String, note: String?, minSize: UInt64 = 64 * 1024) async -> [CleanItem] {
        // Тип и дата прилетают одной пачкой вместе с листингом — без лишних stat на файл
        let keys: [URLResourceKey] = [.isDirectoryKey, .contentModificationDateKey,
                                      .fileSizeKey, .totalFileAllocatedSizeKey]
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: root), includingPropertiesForKeys: keys) else { return [] }
        let items = await mapLimit(urls, 8) { url -> CleanItem? in
            guard let vals = try? url.resourceValues(forKeys: Set(keys)) else { return nil }
            let isDir = vals.isDirectory ?? false
            let size = isDir
                ? await duSize(url.path)
                : UInt64(vals.totalFileAllocatedSize ?? vals.fileSize ?? 0)
            if size < minSize { return nil }
            return CleanItem(path: url.path, name: url.lastPathComponent, size: size,
                             mtime: vals.contentModificationDate, isDir: isDir, note: note)
        }
        return items.sorted { $0.size > $1.size }
    }

    static func scanPackageCaches() async -> [CleanItem] {
        let candidates: [(String, String, String?)] = [
            (home + "/.npm/_cacache", "npm cache", "Перекачается при npm install"),
            (home + "/.cache", "~/.cache", "Кэши CLI-утилит"),
            (home + "/.bun/install/cache", "bun cache", nil),
            (home + "/Library/Caches/Homebrew", "Homebrew downloads", nil),
            (home + "/Library/Caches/pip", "pip cache", nil),
            (home + "/.yarn/cache", "yarn cache", nil),
            (home + "/.gradle/caches", "Gradle caches", "Перекачается при сборке"),
            (home + "/.cocoapods", "CocoaPods cache", "Перекачается при pod install"),
        ]
        var items: [CleanItem] = []
        for (path, name, note) in candidates {
            guard FileManager.default.fileExists(atPath: path) else { continue }
            let size = await duSize(path)
            if size >= 64 * 1024 {
                items.append(CleanItem(path: path, name: name, size: size, mtime: nil, isDir: true, note: note))
            }
        }
        return items.sorted { $0.size > $1.size }
    }

    static func scanNodeModules() async -> [CleanItem] {
        let roots = ["Documents", "Desktop", "Developer", "Projects", "dev", "work", "Kimi", "Sites"]
            .map { home + "/" + $0 }
            .filter { FileManager.default.fileExists(atPath: $0) }
        var found = Set<String>()
        for root in roots {
            guard let out = await runProc("/usr/bin/find",
                                          [root, "-maxdepth", "4", "-type", "d", "-name", "node_modules", "-prune"])
            else { continue }
            for line in out.split(separator: "\n") {
                let p = String(line).trimmingCharacters(in: .whitespaces)
                if !p.isEmpty && !p.dropFirst(p.count > root.count ? root.count : 0).contains("/node_modules/") {
                    found.insert(p)
                }
            }
        }
        let items = await mapLimit(Array(found), 6) { p -> CleanItem? in
            let size = await duSize(p)
            return CleanItem(path: p, name: p.replacingOccurrences(of: home, with: "~"),
                             size: size, mtime: nil, isDir: true,
                             note: "Восстанавливается командой npm install")
        }
        return items.sorted { $0.size > $1.size }
    }

    /// Вложения, которые Apple Mail сохранил при открытии (~/Library/Containers/com.apple.mail/.../Mail Downloads).
    /// Безопасно: это копии, оригиналы остаются в письмах и перекачаются при открытии.
    static func scanMailAttachments() async -> ScanResult {
        let dir = home + "/Library/Containers/com.apple.mail/Data/Library/Mail Downloads"
        guard FileManager.default.fileExists(atPath: dir) else {
            return ScanResult(items: [], denied: false)
        }
        guard (try? FileManager.default.contentsOfDirectory(atPath: dir)) != nil else {
            return ScanResult(items: [], denied: true)
        }
        return ScanResult(items: await scanChildren(of: dir, note: nil), denied: false)
    }

    /// Проектный мусор: dist, .next, target, build, Pods, venv/.venv.
    /// Папка считается мусором, только если рядом лежит файл-маркер проекта.
    static func scanProjectJunk() async -> [CleanItem] {
        let roots = ["Documents", "Desktop", "Developer", "Projects", "dev", "work", "Kimi", "Sites"]
            .map { home + "/" + $0 }
            .filter { FileManager.default.fileExists(atPath: $0) }
        // (имя папки, файл-маркер в родителе, пояснение)
        let rules: [(dir: String, marker: String, note: String)] = [
            ("dist", "package.json", "Пересоздаётся командой npm run build"),
            (".next", "package.json", "Пересоздаётся командой next build"),
            ("target", "Cargo.toml", "Пересоздаётся командой cargo build"),
            ("build", "build.gradle", "Пересоздаётся при сборке Gradle"),
            ("build", "pom.xml", "Пересоздаётся при сборке Maven"),
            ("Pods", "Podfile", "Восстанавливается командой pod install"),
            ("venv", "requirements.txt", "Пересоздаётся: python -m venv venv"),
            (".venv", "pyproject.toml", "Пересоздаётся: python -m venv .venv"),
            (".venv", "requirements.txt", "Пересоздаётся: python -m venv .venv"),
        ]
        var found: [String: String] = [:]  // path → note
        for root in roots {
            var args = [root, "-maxdepth", "5", "-type", "d", "("]
            for (i, r) in rules.enumerated() {
                if i > 0 { args.append("-o") }
                args += ["-name", r.dir]
            }
            args += [")", "-prune"]
            guard let out = await runProc("/usr/bin/find", args) else { continue }
            for line in out.split(separator: "\n") {
                let p = String(line).trimmingCharacters(in: .whitespaces)
                if p.isEmpty || p.contains("/node_modules/") { continue }
                let dirName = (p as NSString).lastPathComponent
                let parent = (p as NSString).deletingLastPathComponent
                for r in rules where r.dir == dirName {
                    if FileManager.default.fileExists(atPath: parent + "/" + r.marker) {
                        if found[p] == nil { found[p] = r.note }
                        break
                    }
                }
            }
        }
        let notes = found
        let items = await mapLimit(Array(found.keys), 6) { p -> CleanItem? in
            let size = await duSize(p)
            if size < 64 * 1024 { return nil }
            return CleanItem(path: p, name: p.replacingOccurrences(of: home, with: "~"),
                             size: size, mtime: nil, isDir: true,
                             note: notes[p])
        }
        return items.sorted { $0.size > $1.size }
    }

    /// Данные Docker Desktop: виртуальный диск и кэши. Перед удалением Docker должен быть закрыт.
    static func scanDockerData() async -> [CleanItem] {
        var items: [CleanItem] = []
        let container = home + "/Library/Containers/com.docker.docker/Data"
        if FileManager.default.fileExists(atPath: container) {
            // Главный кандидат — сырой диск VM, остальное по мелочи
            let vms = container + "/vms"
            if let urls = try? FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: vms), includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]) {
                for url in urls {
                    let size = await duSize(url.path)
                    if size >= 64 * 1024 {
                        items.append(CleanItem(path: url.path,
                                               name: "Виртуальный диск Docker (\(url.lastPathComponent))",
                                               size: size, mtime: nil, isDir: true,
                                               note: "Образы и кэши — перекачаются. Закрой Docker перед удалением"))
                    }
                }
            }
        }
        let group = home + "/Library/Group Containers/group.com.docker"
        if FileManager.default.fileExists(atPath: group) {
            let size = await duSize(group)
            if size >= 64 * 1024 {
                items.append(CleanItem(path: group, name: "Group Containers Docker",
                                       size: size, mtime: nil, isDir: true,
                                       note: "Настройки и кэши Docker Desktop"))
            }
        }
        return items.sorted { $0.size > $1.size }
    }

    /// Недокачки (.download, .crdownload, .part, .partial) и виндовый мусор
    /// (Thumbs.db, desktop.ini) в Загрузках, на Рабочем столе и в Документах.
    static func scanPartialDownloads() async -> [CleanItem] {
        let partialNote = L10n.shared.t("note.partial")
        let winNote = L10n.shared.t("note.windows")
        let names: [(String, String)] = [
            ("*.download", partialNote), ("*.crdownload", partialNote),
            ("*.part", partialNote), ("*.partial", partialNote),
            ("Thumbs.db", winNote), ("desktop.ini", winNote),
        ]
        var expr: [String] = ["("]
        for (i, n) in names.enumerated() {
            if i > 0 { expr.append("-o") }
            expr += ["-name", n.0]
        }
        expr.append(")")
        let roots = ["Downloads", "Desktop", "Documents"]
            .map { home + "/" + $0 }
            .filter { FileManager.default.fileExists(atPath: $0) }
        var found: [String: String] = [:]  // path → note
        for root in roots {
            guard let out = await runProc("/usr/bin/find", [root, "-maxdepth", "6"] + expr) else { continue }
            for line in out.split(separator: "\n") {
                let p = String(line).trimmingCharacters(in: .whitespaces)
                if p.isEmpty || p.contains("/Library/") { continue }
                let base = (p as NSString).lastPathComponent.lowercased()
                let note = names.first { n, _ in
                    n.hasPrefix("*") ? base.hasSuffix(n.dropFirst()) : base == n.lowercased()
                }?.1
                if found[p] == nil { found[p] = note ?? partialNote }
            }
        }
        let notes = found
        let items = await mapLimit(Array(notes.keys), 8) { p -> CleanItem? in
            let fm = FileManager.default
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: p, isDirectory: &isDir) else { return nil }
            let size: UInt64
            if isDir.boolValue {
                size = await duSize(p)  // .download — это пакеты-папки
            } else {
                size = ((try? fm.attributesOfItem(atPath: p))?[.size] as? NSNumber)?.uint64Value ?? 0
            }
            if size < 1024 { return nil }
            let attrs = try? fm.attributesOfItem(atPath: p)
            return CleanItem(path: p, name: p.replacingOccurrences(of: home, with: "~"),
                             size: size, mtime: attrs?[.modificationDate] as? Date,
                             isDir: isDir.boolValue, note: notes[p])
        }
        return items.sorted { $0.size > $1.size }
    }

    /// Битые .plist в ~/Library/Preferences: macOS не может их прочитать,
    /// из-за этого приложения иногда теряют настройки или глючат.
    /// Удалённый файл приложение создаст заново при запуске.
    static func scanBrokenPlists() async -> [CleanItem] {
        let dir = home + "/Library/Preferences"
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return [] }
        var items: [CleanItem] = []
        let note = L10n.shared.t("note.plist")
        for entry in entries where entry.hasSuffix(".plist") && !entry.hasPrefix("com.apple") {
            let p = dir + "/" + entry
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: p)), !data.isEmpty else { continue }
            if (try? PropertyListSerialization.propertyList(from: data, format: nil)) != nil { continue }
            let attrs = try? FileManager.default.attributesOfItem(atPath: p)
            let size = (attrs?[.size] as? NSNumber)?.uint64Value ?? 0
            items.append(CleanItem(path: p, name: entry, size: size,
                                   mtime: attrs?[.modificationDate] as? Date,
                                   isDir: false, note: note))
        }
        return items.sorted { $0.size > $1.size }
    }

    /// История посещений и куки браузеров.
    /// Файлы уходят в Корзину — браузер создаст новые (закройте браузер перед удалением).
    static func scanPrivacy() async -> [CleanItem] {
        let fm = FileManager.default
        var items: [CleanItem] = []
        let histNote = L10n.shared.t("note.history")
        let cookieNote = L10n.shared.t("note.cookies")

        func add(_ path: String, _ name: String, _ note: String) {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue else { return }
            guard let attrs = try? fm.attributesOfItem(atPath: path),
                  let size = (attrs[.size] as? NSNumber)?.uint64Value, size > 0 else { return }
            items.append(CleanItem(path: path, name: name, size: size,
                                   mtime: attrs[.modificationDate] as? Date,
                                   isDir: false, note: note))
        }

        // Safari (нужен Полный доступ к диску)
        add(home + "/Library/Safari/History.db", "Safari: History.db", histNote)
        add(home + "/Library/Safari/History.db-wal", "Safari: History.db-wal", histNote)
        add(home + "/Library/Safari/History.db-shm", "Safari: History.db-shm", histNote)
        add(home + "/Library/Containers/com.apple.Safari/Data/Library/Cookies/Cookies.binarycookies",
            "Safari: Cookies", cookieNote)

        // Chromium-семейство: профили Default / Profile N
        let chromiums: [(String, String)] = [
            ("Google/Chrome", "Chrome"),
            ("Microsoft Edge", "Edge"),
            ("BraveSoftware/Brave-Browser", "Brave"),
            ("Arc/User Data", "Arc"),
            ("Chromium", "Chromium"),
            ("Yandex/YandexBrowser", "Yandex"),
            ("Vivaldi", "Vivaldi"),
        ]
        for (rel, browser) in chromiums {
            let root = home + "/Library/Application Support/" + rel
            guard let profiles = try? fm.contentsOfDirectory(atPath: root) else { continue }
            for prof in profiles where prof == "Default" || prof.hasPrefix("Profile ") || prof.hasPrefix("Person ") {
                let dir = root + "/" + prof
                add(dir + "/History", "\(browser): History (\(prof))", histNote)
                add(dir + "/History-journal", "\(browser): History-journal (\(prof))", histNote)
                add(dir + "/Network/Cookies", "\(browser): Cookies (\(prof))", cookieNote)
                add(dir + "/Network/Cookies-journal", "\(browser): Cookies-journal (\(prof))", cookieNote)
                add(dir + "/Cookies", "\(browser): Cookies (\(prof))", cookieNote)
            }
        }

        // Opera (другая раскладка: файлы прямо в профиле)
        let opera = home + "/Library/Application Support/Opera Software/Opera Stable"
        add(opera + "/History", "Opera: History", histNote)
        add(opera + "/Cookies", "Opera: Cookies", cookieNote)

        // Firefox: история живёт в places.sqlite вместе с закладками — её не трогаем.
        // Чистим только куки и историю автозаполнения форм.
        let ffRoot = home + "/Library/Application Support/Firefox/Profiles"
        if let profiles = try? fm.contentsOfDirectory(atPath: ffRoot) {
            for prof in profiles {
                let dir = ffRoot + "/" + prof
                add(dir + "/cookies.sqlite", "Firefox: cookies (\(prof))", cookieNote)
                add(dir + "/cookies.sqlite-wal", "Firefox: cookies-wal (\(prof))", cookieNote)
                add(dir + "/formhistory.sqlite", "Firefox: formhistory (\(prof))",
                    L10n.shared.t("note.formhistory"))
            }
        }
        return items.sorted { $0.size > $1.size }
    }

    // MARK: - Расширения системы (QuickLook, интернет-плагины, службы и т.п.)

    /// Группы расширений: ключ локализации + папки (пользовательские и общесистемные).
    static let extensionDirs: [(key: String, dirs: [String])] = [
        ("ext.quicklook", ["~/Library/QuickLook", "/Library/QuickLook"]),
        ("ext.plugins", ["~/Library/Internet Plug-Ins", "/Library/Internet Plug-Ins"]),
        ("ext.services", ["~/Library/Services"]),
        ("ext.prefpanes", ["~/Library/PreferencePanes", "/Library/PreferencePanes"]),
        ("ext.spotlight", ["~/Library/Spotlight", "/Library/Spotlight"]),
    ]

    /// Сканирование расширений. Возвращает только непустые группы.
    /// Системные Apple-расширения (/System/Library/…) сюда не входят.
    static func scanExtensions() async -> [ExtensionGroup] {
        var groups: [ExtensionGroup] = []
        for g in extensionDirs {
            var items: [CleanItem] = []
            for dir in g.dirs.map({ $0.replacingOccurrences(of: "~", with: home) }) {
                let keys: [URLResourceKey] = [.isDirectoryKey, .contentModificationDateKey]
                guard let urls = try? FileManager.default.contentsOfDirectory(
                    at: URL(fileURLWithPath: dir), includingPropertiesForKeys: keys,
                    options: [.skipsHiddenFiles]) else { continue }
                for url in urls {
                    let vals = try? url.resourceValues(forKeys: Set(keys))
                    let isDir = vals?.isDirectory ?? false
                    let size = await duSize(url.path)
                    items.append(CleanItem(path: url.path, name: url.lastPathComponent, size: size,
                                           mtime: vals?.contentModificationDate,
                                           isDir: isDir, note: nil))
                }
            }
            items.sort { $0.size > $1.size }
            if !items.isEmpty {
                groups.append(ExtensionGroup(key: g.key, items: items))
            }
        }
        return groups
    }

    /// Локальные снимки Time Machine (только чтение списка).
    static func tmSnapshots() async -> (count: Int, last: String?) {
        guard let out = await runProc("/usr/bin/tmutil", ["listlocalsnapshotdates", "/"]) else {
            return (0, nil)
        }
        let lines = out.split(separator: "\n").map { String($0) }
            .filter { $0.range(of: #"^\d{4}-\d{2}-\d{2}-\d{6}$"#, options: .regularExpression) != nil }
        return (lines.count, lines.last)
    }

    static func scanOldDownloads() async -> [CleanItem] {
        let dir = home + "/Downloads"
        guard FileManager.default.fileExists(atPath: dir),
              let out = await runProc("/usr/bin/find", [dir, "-type", "f", "-mtime", "+30"])
        else { return [] }
        let files = out.split(separator: "\n").map { String($0) }
        let items = await mapLimit(files, 10) { p -> CleanItem? in
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: p),
                  let size = (attrs[.size] as? NSNumber)?.uint64Value,
                  size >= 1024 * 1024
            else { return nil }
            return CleanItem(path: p,
                             name: p.replacingOccurrences(of: dir + "/", with: ""),
                             size: size,
                             mtime: attrs[.modificationDate] as? Date,
                             isDir: false, note: nil)
        }
        return Array(items.sorted { $0.size > $1.size }.prefix(300))
    }

    static func scanTrash() async -> ScanResult {
        guard (try? FileManager.default.contentsOfDirectory(atPath: trashDir)) != nil else {
            return ScanResult(items: [], denied: true)
        }
        return ScanResult(items: await scanChildren(of: trashDir, note: nil), denied: false)
    }

    static func emptyTrashViaFinder() async -> Bool {
        await Task.detached {
            let script = NSAppleScript(source: "tell application \"Finder\" to empty trash")
            var error: NSDictionary?
            script?.executeAndReturnError(&error)
            return error == nil
        }.value
    }

    // MARK: - Объём диска

    static func volumeCapacities() -> (total: UInt64, free: UInt64) {
        let url = URL(fileURLWithPath: "/")
        guard let vals = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
        else { return (0, 0) }
        let total = UInt64(vals.volumeTotalCapacity ?? 0)
        let free = UInt64(vals.volumeAvailableCapacityForImportantUsage ?? 0)
        return (total, free)
    }

    // MARK: - Глубокое сканирование (обзор + большие файлы + кандидаты на дубликаты)

    static func classify(path: String, ext: String) -> FileCategory {
        let comps = path.lowercased()
        if comps.contains("/node_modules/") || comps.contains("/deriveddata/") ||
           comps.contains("/.build/") || comps.contains("/target/debug/") || comps.contains("/target/release/") {
            return .dev
        }
        guard let type = UTType(filenameExtension: ext) else { return .other }
        if type.conforms(to: .movie) || type.conforms(to: .video) { return .video }
        if type.conforms(to: .image) { return .images }
        if ext == "dmg" || ext == "iso" || ext == "zip" || ext == "rar" || ext == "7z" ||
           ext == "tar" || ext == "gz" || ext == "tgz" || ext == "bz2" || ext == "xz" || ext == "pkg" {
            return .archives
        }
        if type.conforms(to: .pdf) || type.conforms(to: .text) || type.conforms(to: .presentation) ||
           type.conforms(to: .spreadsheet) || ext == "doc" || ext == "docx" || ext == "xls" ||
           ext == "xlsx" || ext == "ppt" || ext == "pptx" || ext == "pages" || ext == "numbers" || ext == "key" {
            return .docs
        }
        if type.conforms(to: .audio) { return .video }
        return .other
    }

    static func deepScan(progress: @Sendable @escaping (Int, String) -> Void) async throws -> DeepScanResult {
        try await Task.detached(priority: .userInitiated) {
            var byCategory: [FileCategory: UInt64] = [:]
            var large: [LargeFile] = []
            var dupeCandidates: [LargeFile] = []
            var topByCategory: [FileCategory: [LargeFile]] = [:]
            var folderSizes: [String: UInt64] = [:]
            var topLevelSizes: [String: UInt64] = [:]
            var scanned = 0

            /// Добавляет размер всем папкам-предкам глубиной 1–3 от домашней
            func addToAncestors(_ path: String, _ size: UInt64) {
                guard path.hasPrefix(home + "/") else { return }
                let rel = String(path.dropFirst(home.count + 1))
                let comps = rel.split(separator: "/", omittingEmptySubsequences: true)
                if let first = comps.first {
                    topLevelSizes[home + "/" + first, default: 0] += size
                }
                for depth in 2...3 where comps.count >= depth {
                    let key = home + "/" + comps.prefix(depth).joined(separator: "/")
                    folderSizes[key, default: 0] += size
                }
            }

            let fm = FileManager.default
            // totalFileAllocatedSize — физически занятое место: «облачные» файлы-заглушки
            // (iCloud Photos, CloudStorage) имеют большой логический размер, но ноль на диске.
            let keys: [URLResourceKey] = [.fileSizeKey, .totalFileAllocatedSizeKey, .contentAccessDateKey, .isDirectoryKey, .isPackageKey]
            guard let enumerator = fm.enumerator(at: URL(fileURLWithPath: home),
                                                 includingPropertiesForKeys: keys,
                                                 options: [],
                                                 errorHandler: { _, _ in true }) else {
                return DeepScanResult(byCategory: [:], large: [], dupeCandidates: [], topByCategory: [:],
                                      topFolders: [], topLevel: [:], folderSizes: [:])
            }

            while let url = enumerator.nextObject() as? URL {
                if Task.isCancelled { throw CancellationError() }
                let path = url.path
                // Не лезем в Корзину
                if path.hasPrefix(trashDir) { enumerator.skipDescendants(); continue }

                let vals = try? url.resourceValues(forKeys: Set(keys))
                let isDir = vals?.isDirectory ?? false

                if isDir {
                    let name = url.lastPathComponent
                    // .app считаем целиком как «Приложения», внутрь не заходим
                    if name.hasSuffix(".app") {
                        let size = duSizeSync(path)
                        byCategory[.apps, default: 0] += size
                        topByCategory[.apps, default: []].append(
                            LargeFile(path: path, name: name, size: size, access: nil, category: .apps, isDir: true))
                        addToAncestors(path, size)
                        enumerator.skipDescendants()
                        continue
                    }
                    // Тяжёлые дев-папки считаем целиком
                    if name == "node_modules" || name == "DerivedData" {
                        let size = duSizeSync(path)
                        byCategory[.dev, default: 0] += size
                        topByCategory[.dev, default: []].append(
                            LargeFile(path: path, name: name, size: size, access: nil, category: .dev, isDir: true))
                        addToAncestors(path, size)
                        enumerator.skipDescendants()
                        continue
                    }
                    continue
                }

                let size = UInt64(vals?.totalFileAllocatedSize ?? vals?.fileSize ?? 0)
                let ext = url.pathExtension.lowercased()
                let cat = classify(path: path, ext: ext)
                byCategory[cat, default: 0] += size
                scanned += 1
                addToAncestors(path, size)

                if size >= 2 * 1024 * 1024 { // от 2 МБ — показываем в детализации категории
                    topByCategory[cat, default: []].append(
                        LargeFile(path: path, name: url.lastPathComponent, size: size,
                                  access: vals?.contentAccessDate, category: cat))
                }

                if size >= 30 * 1024 * 1024 { // от 30 МБ — кандидаты в дубликаты и большие файлы
                    let lf = LargeFile(path: path, name: url.lastPathComponent, size: size,
                                       access: vals?.contentAccessDate, category: cat)
                    dupeCandidates.append(lf)
                    if size >= 50 * 1024 * 1024 { large.append(lf) }
                }

                if scanned % 3000 == 0 { progress(scanned, url.lastPathComponent) }
            }

            large.sort { $0.size > $1.size }
            if large.count > 500 { large = Array(large.prefix(500)) }
            for cat in topByCategory.keys {
                var arr = topByCategory[cat] ?? []
                arr.sort { $0.size > $1.size }
                if arr.count > 400 { arr = Array(arr.prefix(400)) }
                topByCategory[cat] = arr
            }
            // Топ тяжёлых папок: от 100 МБ, не более 40
            let topFolders: [LargeFile] = folderSizes
                .filter { $0.value >= 100 * 1024 * 1024 }
                .sorted { $0.value > $1.value }
                .prefix(40)
                .map { path, size in
                    LargeFile(path: path, name: (path as NSString).lastPathComponent,
                              size: size, access: nil, category: .other, isDir: true)
                }
            progress(scanned, "")
            return DeepScanResult(byCategory: byCategory, large: large,
                                  dupeCandidates: Array(dupeCandidates.prefix(8000)),
                                  topByCategory: topByCategory, topFolders: Array(topFolders),
                                  topLevel: topLevelSizes, folderSizes: folderSizes)
        }.value
    }

    // MARK: - Дубликаты (по размеру → быстрый хэш → полный хэш)

    static func quickHash(_ path: String, size: UInt64) -> String? {
        guard let fh = FileHandle(forReadingAtPath: path) else { return nil }
        defer { try? fh.close() }
        var hasher = SHA256()
        let chunk = 1024 * 1024
        let head = fh.readData(ofLength: chunk)
        hasher.update(data: head)
        if size > UInt64(chunk) {
            let tailOffset = size > UInt64(chunk * 2) ? size - UInt64(chunk) : UInt64(chunk)
            try? fh.seek(toOffset: tailOffset)
            let tail = fh.readData(ofLength: chunk)
            hasher.update(data: tail)
        }
        var sizeBytes = size
        hasher.update(data: Data(bytes: &sizeBytes, count: MemoryLayout<UInt64>.size))
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    static func fullHash(_ path: String) -> String? {
        guard let stream = InputStream(fileAtPath: path) else { return nil }
        stream.open()
        defer { stream.close() }
        var hasher = SHA256()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024 * 512)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: 1024 * 512)
            if read <= 0 { break }
            hasher.update(bufferPointer: UnsafeRawBufferPointer(start: buffer, count: read))
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    /// Облачные файлы-заглушки: чтение их содержимого запускает скачивание из iCloud.
    /// Для хэширования их пропускаем.
    static func isCloudPath(_ p: String) -> Bool {
        p.hasPrefix(home + "/Library/CloudStorage/") || p.hasPrefix(home + "/Library/Mobile Documents/")
    }

    static func findDuplicates(in candidates: [LargeFile]) async -> [DupeGroup] {
        // 1. Группы по размеру (облачные заглушки не хэшируем)
        var bySize: [UInt64: [LargeFile]] = [:]
        for f in candidates where !isCloudPath(f.path) { bySize[f.size, default: []].append(f) }
        let sizeGroups = bySize.values.filter { $0.count > 1 }
        // 2. Быстрый хэш
        var byQuick: [String: [LargeFile]] = [:]
        for group in sizeGroups {
            for f in group {
                if Task.isCancelled { return [] }
                if let h = quickHash(f.path, size: f.size) {
                    byQuick[h, default: []].append(f)
                }
            }
        }
        // 3. Полный хэш только у совпавших
        var result: [DupeGroup] = []
        for (_, group) in byQuick where group.count > 1 {
            if Task.isCancelled { return [] }
            var byFull: [String: [String]] = [:]
            for f in group {
                if Task.isCancelled { return [] }
                if let h = fullHash(f.path) {
                    byFull[h, default: []].append(f.path)
                }
            }
            for (h, paths) in byFull where paths.count > 1 {
                result.append(DupeGroup(hash: h, size: group[0].size, paths: paths.sorted()))
            }
        }
        return result.sorted { $0.waste > $1.waste }
    }

    // MARK: - Приложения

    static func scanApps() async -> [AppEntry] {
        let dirs = ["/Applications", home + "/Applications"]
        var found: [URL] = []
        for dir in dirs {
            guard let urls = try? FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: dir), includingPropertiesForKeys: nil) else { continue }
            for url in urls where url.pathExtension == "app" {
                found.append(url)
            }
        }
        let apps = await mapLimit(found, 6) { url -> AppEntry? in
            let bundle = Bundle(url: url)
            let name = (bundle?.infoDictionary?["CFBundleDisplayName"] as? String)
                ?? (bundle?.infoDictionary?["CFBundleName"] as? String)
                ?? url.deletingPathExtension().lastPathComponent
            let bundleID = bundle?.bundleIdentifier ?? ""
            // Системные приложения Apple не трогаем
            if bundleID.hasPrefix("com.apple.") { return nil }
            let size = await duSize(url.path)
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            return AppEntry(url: url, name: name, bundleID: bundleID, size: size, icon: icon)
        }
        return apps.sorted { $0.size > $1.size }
    }

    /// Библиотечные места, где живут файлы приложений.
    static let appDataDirs = [
        "Library/Application Support",
        "Library/Caches",
        "Library/Preferences",
        "Library/Logs",
        "Library/Saved Application State",
        "Library/HTTPStorages",
        "Library/WebKit",
        "Library/Containers",
    ]

    /// Остатки конкретного приложения (по bundle id и имени).
    static func findLeftovers(of app: AppEntry) async -> [CleanItem] {
        let tokens = leftoverTokens(name: app.name, bundleID: app.bundleID)
        var items: [CleanItem] = []
        for rel in appDataDirs {
            let dir = home + "/" + rel
            guard let urls = try? FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: dir), includingPropertiesForKeys: [.isDirectoryKey])
            else { continue }
            for url in urls {
                let low = url.lastPathComponent.lowercased()
                if low.hasPrefix("com.apple.") { continue }
                if tokens.contains(where: { low.contains($0) }) {
                    let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                    let size = await duSize(url.path)
                    items.append(CleanItem(path: url.path,
                                           name: rel.replacingOccurrences(of: "Library/", with: "") + "/" + url.lastPathComponent,
                                           size: size, mtime: nil, isDir: isDir, note: nil))
                }
            }
        }
        return items.sorted { $0.size > $1.size }
    }

    /// Слова, которые слишком общие для матчинга: «studio» ловит CherryStudio и т.п.
    static let genericTokens: Set<String> = [
        "studio", "app", "apps", "mac", "macos", "pro", "code", "editor", "viewer",
        "player", "manager", "helper", "desktop", "client", "cloud", "sync", "notes",
        "mail", "suite", "tool", "tools", "hub", "launcher", "agent", "service",
        "browser", "reader", "writer", "monitor", "cleaner", "utility", "utilities"
    ]

    static func leftoverTokens(name: String, bundleID: String) -> [String] {
        var tokens: Set<String> = []
        let clean = name.lowercased().replacingOccurrences(of: " ", with: "")
        if clean.count >= 5 && !genericTokens.contains(clean) { tokens.insert(clean) }
        let bid = bundleID.lowercased()
        if bid.count >= 6 { tokens.insert(bid) }
        // последняя часть bundle id: com.company.app → app
        if let last = bid.split(separator: ".").last {
            let s = String(last)
            if s.count >= 5 && !genericTokens.contains(s) { tokens.insert(s) }
        }
        return Array(tokens)
    }

    /// «Сироты»: библиотечные папки, для которых приложения больше нет.
    static func findOrphans(installedApps: [AppEntry]) async -> [CleanItem] {
        var installedTokens = Set<String>()
        for app in installedApps {
            let cleanName = app.name.lowercased().replacingOccurrences(of: " ", with: "")
            if cleanName.count >= 5 && !genericTokens.contains(cleanName) {
                installedTokens.insert(cleanName)
            }
            installedTokens.insert(app.bundleID.lowercased())
            if let last = app.bundleID.split(separator: ".").last {
                let s = String(last).lowercased()
                if s.count >= 5 && !genericTokens.contains(s) { installedTokens.insert(s) }
            }
        }
        // Папки, которые точно нельзя считать сиротами
        let allowlist: Set<String> = ["apple", "com.apple", "adobe", "microsoft", "google",
                                      "icloud", "icloudcontent", "mobilesync", "cloudkit",
                                      "knowledge", "callhistorydb", "addressbook", "safari"]

        var orphans: [CleanItem] = []
        let dirs = ["Library/Application Support", "Library/Caches", "Library/Preferences",
                    "Library/Saved Application State", "Library/HTTPStorages", "Library/Logs"]
        for rel in dirs {
            let dir = home + "/" + rel
            guard let urls = try? FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: dir), includingPropertiesForKeys: [.isDirectoryKey])
            else { continue }
            for url in urls {
                let low = url.lastPathComponent.lowercased()
                if low.hasPrefix("com.apple") || low.hasPrefix("apple") { continue }
                if allowlist.contains(where: { low.hasPrefix($0) }) { continue }
                let base = low
                    .replacingOccurrences(of: ".plist", with: "")
                    .replacingOccurrences(of: " ", with: "")
                // Если по имени находится живое приложение — не сирота.
                // Обратное сравнение только для длинных имён, чтобы короткая папка
                // вроде «mail» не маскировалась под любое приложение.
                let hasApp = installedTokens.contains(where: { token in
                    !token.isEmpty && (base.contains(token) || (base.count >= 5 && token.contains(base)))
                })
                if !hasApp {
                    let p = url.path
                    let size = await duSize(p)
                    if size < 256 * 1024 { continue }
                    let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                    orphans.append(CleanItem(path: p,
                                             name: rel.replacingOccurrences(of: "Library/", with: "") + "/" + url.lastPathComponent,
                                             size: size, mtime: nil, isDir: isDir,
                                             note: "приложение не найдено"))
                }
            }
        }
        return orphans.sorted { $0.size > $1.size }
    }

    // MARK: - Автозагрузка (пользовательские Launch Agents)

    static func scanLaunchAgents() async -> [StartupItem] {
        var items: [StartupItem] = []
        let dirs = [home + "/Library/LaunchAgents"]
        for dir in dirs {
            guard let entries = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
            for entry in entries where entry.hasSuffix(".plist") {
                let p = dir + "/" + entry
                var label = entry.replacingOccurrences(of: ".plist", with: "")
                var program = ""
                if let data = try? Data(contentsOf: URL(fileURLWithPath: p)),
                   let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                    label = plist["Label"] as? String ?? label
                    if let prog = plist["Program"] as? String {
                        program = prog
                    } else if let args = plist["ProgramArguments"] as? [String] {
                        program = args.first ?? ""
                    }
                }
                let size = await duSize(p)
                // Битый агент: программа, на которую он ссылается, уже удалена
                let missing = program.hasPrefix("/") && !FileManager.default.fileExists(atPath: program)
                items.append(StartupItem(path: p, label: label, program: program, size: size,
                                         programMissing: missing))
            }
        }
        return items.sorted { $0.label < $1.label }
    }

    // MARK: - Процессы и утилиты

    /// Физический размер файла/папки своим обходом — без запуска внешнего du.
    /// Симлинки не разыменовываются; считаем allocated size (реально занятое на диске).
    static func duSize(_ path: String) async -> UInt64 {
        await Task.detached(priority: .userInitiated) { Self.duSizeSync(path) }.value
    }

    /// Синхронная версия — звать из уже фонового контекста (deepScan и т.п.)
    static func duSizeSync(_ path: String) -> UInt64 {
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .fileSizeKey,
                                      .isDirectoryKey, .isSymbolicLinkKey]
        let url = URL(fileURLWithPath: path)
        guard let vals = try? url.resourceValues(forKeys: Set(keys)) else { return 0 }
        func sizeOf(_ v: URLResourceValues) -> UInt64 {
            UInt64(v.totalFileAllocatedSize ?? v.fileSize ?? 0)
        }
        // Файл или симлинк — размер самого элемента
        guard (vals.isDirectory ?? false) && !(vals.isSymbolicLink ?? false) else {
            return sizeOf(vals)
        }
        guard let en = FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys,
                                                      options: [],
                                                      errorHandler: { _, _ in true }) else {
            return sizeOf(vals)
        }
        var total: UInt64 = sizeOf(vals)  // сама папка (du тоже её считает)
        var n = 0
        for case let u as URL in en {
            // Даём возможность отменить длинный обход
            n += 1
            if n % 256 == 0 && Task.isCancelled { break }
            guard let v = try? u.resourceValues(forKeys: Set(keys)) else { continue }
            if (v.isDirectory ?? false), (v.isSymbolicLink ?? false) { continue }
            total &+= sizeOf(v)
        }
        return total
    }

    static func runProc(_ path: String, _ args: [String]) async -> String? {
        await Task.detached(priority: .userInitiated) {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: path)
            p.arguments = args
            let pipe = Pipe()
            p.standardOutput = pipe
            p.standardError = FileHandle.nullDevice
            do { try p.run() } catch { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            return String(data: data, encoding: .utf8)
        }.value
    }

    static func mapLimit<T, R>(_ items: [T], _ limit: Int,
                               _ fn: @Sendable @escaping (T) async -> R?) async -> [R] where T: Sendable, R: Sendable {
        var result: [R] = []
        guard !items.isEmpty else { return result }
        var index = 0
        while index < items.count {
            let end = min(index + limit, items.count)
            let chunk = Array(items[index..<end])
            let part: [R] = await withTaskGroup(of: R?.self) { group in
                for item in chunk { group.addTask { await fn(item) } }
                var acc: [R] = []
                for await r in group { if let r { acc.append(r) } }
                return acc
            }
            result.append(contentsOf: part)
            index = end
        }
        return result
    }
}
