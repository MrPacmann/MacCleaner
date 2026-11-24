import Foundation
import AppKit

/// Проверка обновлений через GitHub Releases:
/// сравнивает tag_name последнего релиза с CFBundleShortVersionString.
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

    static let shared = UpdateChecker()

    /// Репозиторий с релизами
    static let repoAPI = "https://api.github.com/repos/MrPacmann/MacCleaner/releases/latest"

    var state: State = .idle
    var releaseURL: URL? = nil

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
}
