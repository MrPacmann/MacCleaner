import SwiftUI
import AppKit

// MARK: - Тема (по макетам Figma: тёмные карточки, фиолетовый акцент)

enum Theme {
    /// Фиолетовый акцент
    static let accent = Color(red: 0.51, green: 0.42, blue: 0.98)      // #836BFA
    static let accentSoft = Color(red: 0.62, green: 0.55, blue: 0.99)
    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.55, green: 0.44, blue: 0.98), Color(red: 0.44, green: 0.35, blue: 0.93)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    /// Успех / безопасно
    static let success = Color(red: 0.24, green: 0.78, blue: 0.50)     // #3DC77F
    /// Опасные действия
    static let danger = Color(red: 0.93, green: 0.36, blue: 0.42)      // #EE5C6B

    /// Фон окна
    static var bg: Color { Color(nsColor: .init(name: nil, dynamicProvider: { a in
        a.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(calibratedRed: 0.055, green: 0.055, blue: 0.082, alpha: 1)   // #0E0E15
            : NSColor(calibratedRed: 0.957, green: 0.957, blue: 0.973, alpha: 1)   // #F4F4F8
    })) }

    /// Фон карточек
    static var card: Color { Color(nsColor: .init(name: nil, dynamicProvider: { a in
        a.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(calibratedRed: 0.106, green: 0.110, blue: 0.161, alpha: 1)   // #1B1C29
            : .white
    })) }

    /// Обводка карточек
    static var stroke: Color { Color.primary.opacity(0.06) }

    /// Подложка приглушённых кнопок
    static var ghost: Color { Color.primary.opacity(0.06) }
}

extension Text {
    func badgeStyle(color: Color) -> some View {
        self
            .font(.caption2.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.14), in: Capsule())
    }
}

// MARK: - Цветной тайл с SF-иконкой (пастельный скруглённый квадрат)

struct IconTile: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 38

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.42))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.16), in: RoundedRectangle(cornerRadius: size * 0.28))
    }
}

// MARK: - Иконка файла по типу

struct FileIconView: View {
    let name: String
    let isDir: Bool
    var size: CGFloat = 34

    var body: some View {
        let (symbol, color) = style
        IconTile(symbol: symbol, color: color, size: size)
    }

    var style: (String, Color) {
        if isDir { return ("folder", Color(red: 0.93, green: 0.70, blue: 0.40)) }
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "mov", "mp4", "mkv", "avi", "m4v", "webm":
            return ("play.rectangle", Color(red: 0.55, green: 0.49, blue: 0.96))
        case "zip", "rar", "7z", "tar", "gz", "dmg", "iso", "pkg":
            return ("doc.zipper", Color(red: 0.96, green: 0.70, blue: 0.42))
        case "jpg", "jpeg", "png", "heic", "gif", "tiff", "raw", "cr2", "nef":
            return ("photo", Color(red: 0.95, green: 0.62, blue: 0.77))
        case "mp3", "aac", "flac", "wav", "m4a", "ogg":
            return ("music.note", Color(red: 0.91, green: 0.46, blue: 0.55))
        case "pdf", "doc", "docx", "txt", "md", "pages":
            return ("doc.text", Color(red: 0.50, green: 0.70, blue: 0.95))
        default:
            return ("doc", Color(nsColor: .secondaryLabelColor))
        }
    }
}

// MARK: - Поле поиска по списку

struct SearchField: View {
    @Binding var query: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.callout)
                .foregroundStyle(.tertiary)
            TextField(L10n.shared.t("search.placeholder"), text: $query)
                .textFieldStyle(.plain)
                .font(.callout)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.ghost, in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Кастомный чекбокс (как в макете)

struct CheckBox: View {
    let isOn: Bool
    let action: (Bool) -> Void

    var body: some View {
        Button { action(!isOn) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isOn ? Theme.accent : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isOn ? Theme.accent : Color.primary.opacity(0.30), lineWidth: 1.5)
                    )
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 18, height: 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Строка файла — отдельная карточка-«пилюля» (по макету)

struct SelectableRow: View {
    @Environment(CleanerViewModel.self) private var model
    let path: String
    let name: String
    let size: UInt64
    var isDir: Bool = false
    var subtitle: String? = nil
    var note: String? = nil
    var date: Date? = nil
    var icon: NSImage? = nil
    var selectable: Bool = true

    var isSelected: Bool { model.selected.contains(path) }

    var body: some View {
        HStack(spacing: 12) {
            if selectable {
                CheckBox(isOn: isSelected) { model.toggle(path, $0) }
            }

            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                FileIconView(name: name, isDir: isDir)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .help(path)

            Spacer(minLength: 8)

            if let note, !note.isEmpty {
                Text(note)
                    .font(.caption).foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            if let date {
                Text(Format.date(date))
                    .font(.caption).foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Text(Format.bytes(size))
                .font(.callout.weight(.semibold).monospacedDigit())
                .frame(minWidth: 76, alignment: .trailing)

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
            } label: {
                Label("Finder", systemImage: "folder")
                    .font(.caption.weight(.medium))
                    .labelStyle(.titleAndIcon)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Theme.ghost, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(L10n.shared.t("help.finder"))
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Theme.accent.opacity(0.14) : Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Theme.accent.opacity(0.45) : Theme.stroke, lineWidth: 1)
        )
    }
}

// MARK: - Карточка-обёртка

struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.stroke))
    }
}

// MARK: - Пустое состояние (иконка-тайл + заголовок + подпись + кнопка)

struct EmptyState: View {
    let icon: String
    var iconColor: Color = Theme.success
    let title: String
    var subtitle: String = ""
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            IconTile(symbol: icon, color: iconColor, size: 56)
            Text(title).font(.title3.bold())
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.callout).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let buttonTitle, let action {
                PrimaryButton(title: buttonTitle, action: action)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 52)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.stroke))
    }
}

// MARK: - Шапка страницы (крупный заголовок + подзаголовок)

struct PageHeader: View {
    let title: String
    var subtitle: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 28, weight: .bold))
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}

/// Старое имя — оставлено для совместимости
typealias SectionHeader = PageHeader

// MARK: - Кнопки

/// Главная фиолетовая кнопка с градиентом
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let icon { Label(title, systemImage: icon) } else { Text(title) }
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

/// Приглушённая кнопка
struct GhostButton: View {
    let title: String
    var icon: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let icon { Label(title, systemImage: icon) } else { Text(title) }
            }
            .font(.callout.weight(.medium))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Theme.ghost, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Статус-пилюля в правом верхнем углу

struct StatusPill: View {
    @Environment(CleanerViewModel.self) private var model

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(Theme.success)
                .frame(width: 7, height: 7)
            Text(text)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Theme.success.opacity(0.12), in: Capsule())
        .foregroundStyle(Theme.success)
    }

    var text: String {
        if model.disk.phase == .scanning {
            return L10n.shared.f("status.scanning", model.disk.filesScanned)
        }
        if let at = model.disk.finishedAt {
            if Calendar.current.isDateInToday(at) {
                return L10n.shared.f("status.today", at.formatted(date: .omitted, time: .shortened))
            }
            return L10n.shared.f("status.date", at.formatted(date: .numeric, time: .omitted))
        }
        return L10n.shared.t("status.ready")
    }
}

// MARK: - Нижняя панель выбора (плавающая карточка)

struct SelectionBar: View {
    @Environment(CleanerViewModel.self) private var model

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.accent.opacity(0.15)).frame(width: 38, height: 38)
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("\(L10n.shared.t("misc.selected")): \(model.selected.count) · \(Format.bytes(model.selectedSize))")
                    .font(.callout.weight(.semibold))
                    .contentTransition(.numericText())
                Text(L10n.shared.t("misc.toTrashNote"))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                withAnimation(.easeOut(duration: 0.15)) { model.selected.removeAll() }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(Theme.ghost, in: RoundedRectangle(cornerRadius: 10))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(L10n.shared.t("help.deselect"))
            PrimaryButton(title: L10n.shared.t("btn.delete"), icon: "trash") {
                model.showTrashConfirm = true
            }
            .keyboardShortcut(.delete, modifiers: .command)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent.opacity(0.25)))
        .shadow(color: .black.opacity(0.25), radius: 16, y: 6)
        .padding(.horizontal, 24)
        .padding(.bottom, 14)
    }
}

// MARK: - Кнопка сканирования с прогрессом

struct ScanButton: View {
    let title: String
    let isScanning: Bool
    let action: () -> Void

    var body: some View {
        if isScanning {
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text(L10n.shared.t("misc.scanning")).font(.callout)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Theme.ghost, in: RoundedRectangle(cornerRadius: 10))
        } else {
            GhostButton(title: title, icon: "arrow.clockwise", action: action)
        }
    }
}

// MARK: - Диалог подтверждения (кастомный, по макету)

struct ConfirmDialog: View {
    let icon: String
    var iconColor: Color = Theme.accent
    let title: String
    let subtitle: String
    let note: String
    let confirmTitle: String
    var confirmColor: Color = Theme.accent
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            IconTile(symbol: icon, color: iconColor, size: 52)

            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.title3.bold())
                Text(subtitle).font(.callout.weight(.medium)).foregroundStyle(.secondary)
                Text(note)
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Spacer()
                Button(L10n.shared.t("btn.cancel"), action: onCancel)
                    .buttonStyle(.plain)
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 14).padding(.vertical, 9)
                Button(action: onConfirm) {
                    Text(confirmTitle)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 9)
                        .background(confirmColor, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.stroke))
        .shadow(color: .black.opacity(0.45), radius: 40, y: 12)
    }
}
