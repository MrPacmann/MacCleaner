import Foundation
import AppKit

// MARK: - Статусы разрешений приложения

enum PermStatus {
    case granted, denied, unknown

    var key: String {
        switch self {
        case .granted: return "perm.granted"
        case .denied: return "perm.denied"
        case .unknown: return "perm.unknown"
        }
    }
}

enum Permissions {

    /// Полный доступ к диску: проверяем чтение защищённой папки Safari
    static var fullDiskAccess: PermStatus {
        let probe = NSHomeDirectory() + "/Library/Safari"
        if (try? FileManager.default.contentsOfDirectory(atPath: probe)) != nil {
            return .granted
        }
        return .unknown   // TCC не даёт надёжно отличить «не спрашивали» от «отказано»
    }

    /// Файлы и папки: чтение ~/Downloads
    static var filesAndFolders: PermStatus {
        let probe = NSHomeDirectory() + "/Downloads"
        if (try? FileManager.default.contentsOfDirectory(atPath: probe)) != nil {
            return .granted
        }
        return .unknown
    }

    /// Медиатека и Apple Music: проверяем чтение папки медиатеки
    static var mediaLibrary: PermStatus {
        let probe = NSHomeDirectory() + "/Music/Music/Media"
        if (try? FileManager.default.contentsOfDirectory(atPath: probe)) != nil {
            return .granted
        }
        return .unknown
    }

    /// Открыть нужный раздел Системных настроек
    static func openSettings(pane: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") {
            NSWorkspace.shared.open(url)
        }
    }
}
