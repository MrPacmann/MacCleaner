import SwiftUI
import AppKit

// MARK: - Общие мелкие элементы списков

struct SelectionToolbar: View {
    @Environment(CleanerViewModel.self) private var model
    let paths: [String]

    var body: some View {
        HStack(spacing: 10) {
            GhostButton(title: L10n.shared.t("btn.selectAll")) { for p in paths { model.selected.insert(p) } }
            GhostButton(title: L10n.shared.t("btn.deselect")) { for p in paths { model.selected.remove(p) } }
        }
    }
}

// MARK: - Обзор диска

struct OverviewView: View {
    @Environment(CleanerViewModel.self) private var model

    var body: some View {
        Group {
            if let cat = model.drillCategory {
                CategoryDetailView(category: cat)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        PageHeader(title: L10n.shared.t("sec.overview"))
                        heroCard
                        if model.disk.phase == .scanning { scanningCard }
                        if model.disk.phase == .done { detailsCard }
                        if model.disk.phase == .done { nextSteps }
                    }
                    .padding(24)
                }
            }
        }
        .task {
            await model.runDeepScan()
            // Тихие фоновые сканы для рекомендаций в «Что дальше?»
            if model.downloadsCategory.status == .idle { await model.scanJunk(model.downloadsCategory) }
            if model.trashCategory.status == .idle { await model.scanJunk(model.trashCategory) }
        }
    }

    // Hero-карточка «Место для важного»
    var heroCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(L10n.shared.t("hero.caption"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    ScanButton(title: L10n.shared.t("btn.rescan"),
                               isScanning: model.disk.phase == .scanning) {
                        Task { await model.runDeepScan(force: true) }
                    }
                }

                if model.disk.phase == .scanning {
                    Text(L10n.shared.t("misc.scanning"))
                        .font(.system(size: 34, weight: .bold))
                    Text(L10n.shared.f("misc.checked", model.disk.filesScanned))
                        .font(.callout).foregroundStyle(.secondary)
                } else {
                    Text(Format.bytes(model.disk.volumeFree))
                        .font(.system(size: 44, weight: .bold))
                    Text(L10n.shared.f("hero.freeOf", Format.bytes(model.disk.volumeTotal)))
                        .font(.callout).foregroundStyle(.secondary)
                }

                Divider().padding(.vertical, 4)

                HStack {
                    let used = model.disk.volumeTotal > model.disk.volumeFree
                        ? model.disk.volumeTotal - model.disk.volumeFree : 0
                    Text(L10n.shared.f("hero.used", Format.bytes(used)))
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    if let at = model.disk.finishedAt {
                        Text(Calendar.current.isDateInToday(at)
                             ? L10n.shared.f("hero.lastToday", at.formatted(date: .omitted, time: .shortened))
                             : L10n.shared.f("hero.lastDate", at.formatted(date: .numeric, time: .shortened)))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
        }
    }

    // Карточка прогресса «Изучаю ваш диск»
    var scanningCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(L10n.shared.t("scan.title")).font(.callout.weight(.semibold))
                    Spacer()
                }
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(Theme.accent)
                Text(model.disk.currentPath.isEmpty ? "…" : model.disk.currentPath)
                    .font(.caption).foregroundStyle(.secondary)
                    .lineLimit(1).truncationMode(.middle)
                HStack {
                    Text(L10n.shared.t("scan.eta"))
                        .font(.caption).foregroundStyle(.tertiary)
                    Spacer()
                    Text(L10n.shared.t("scan.bg"))
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(20)
        }
    }

    // «Ваш диск в деталях»: полоса + легенда
    var detailsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(L10n.shared.t("details.title")).font(.callout.weight(.semibold))
                    Spacer()
                    Text(L10n.shared.t("details.count")).font(.caption).foregroundStyle(.secondary)
                }
                SegmentedBar()
                legendGrid
            }
            .padding(20)
        }
    }

    var legendGrid: some View {
        let known = model.disk.usedByKnown
        let unknown = model.disk.volumeTotal > model.disk.volumeFree + known
            ? model.disk.volumeTotal - model.disk.volumeFree - known : 0
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 5),
                         alignment: .leading, spacing: 14) {
            ForEach(FileCategory.allCases) { cat in
                let size = model.disk.byCategory[cat] ?? 0
                if size > 0 {
                                    Button { model.drillCategory = cat } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Circle().fill(cat.color).frame(width: 8, height: 8)
                                Text(L10n.shared.t(cat.titleKey)).font(.caption.weight(.medium))
                            }
                            Text(Format.bytes(size))
                                .font(.caption2).foregroundStyle(.secondary)
                                .padding(.leading, 14)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(L10n.shared.f("help.catOpen", L10n.shared.t(cat.titleKey)))
                }
            }
            if unknown > 0 {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Circle().fill(Color(nsColor: .tertiaryLabelColor)).frame(width: 8, height: 8)
                        Text(L10n.shared.t("cat.system")).font(.caption.weight(.medium))
                    }
                    Text(Format.bytes(unknown))
                        .font(.caption2).foregroundStyle(.secondary)
                        .padding(.leading, 14)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Circle().fill(Color.primary.opacity(0.18)).frame(width: 8, height: 8)
                    Text(L10n.shared.t("cat.free")).font(.caption.weight(.medium))
                }
                Text(Format.bytes(model.disk.volumeFree))
                    .font(.caption2).foregroundStyle(.secondary)
                    .padding(.leading, 14)
            }
        }
    }

    // «Что дальше?» — персональные рекомендации по объёму
    struct Hint: Identifiable {
        let id: String
        let icon: String
        let color: Color
        let title: String
        let text: String
        let section: AppSection
        let bytes: UInt64
    }

    var hints: [Hint] {
        var list: [Hint] = []
        let lfSize = model.disk.largeFiles.reduce(0) { $0 + $1.size }
        if !model.disk.largeFiles.isEmpty {
            list.append(Hint(id: "large", icon: "doc",
                             color: Color(red: 0.50, green: 0.70, blue: 0.95),
                             title: L10n.shared.t("sec.largeFiles"),
                             text: "\(model.disk.largeFiles.count) файлов · \(Format.bytes(lfSize))",
                             section: .largeFiles, bytes: lfSize))
        }
        if let top = model.disk.topFolders.first {
            list.append(Hint(id: "folders", icon: "folder.fill",
                             color: Color(red: 0.93, green: 0.70, blue: 0.40),
                             title: L10n.shared.t("sec.folders"),
                             text: L10n.shared.f("hint.topFolder", top.name, Format.bytes(top.size)),
                             section: .folders, bytes: top.size))
        }
        if model.dupes.status == .done && !model.dupes.groups.isEmpty {
            list.append(Hint(id: "dupes", icon: "square.on.square", color: Theme.accent,
                             title: L10n.shared.t("sec.duplicates"),
                             text: L10n.shared.f("hint.dupes", model.dupes.groups.count, Format.bytes(model.dupes.totalWaste)),
                             section: .duplicates, bytes: model.dupes.totalWaste))
        }
        if model.downloadsCategory.status == .done && model.downloadsCategory.total > 0 {
            list.append(Hint(id: "downloads", icon: "arrow.down.circle",
                             color: Color(red: 0.60, green: 0.55, blue: 0.97),
                             title: L10n.shared.t("hint.dl.title"),
                             text: L10n.shared.f("hint.downloads", Format.bytes(model.downloadsCategory.total)),
                             section: .downloads, bytes: model.downloadsCategory.total))
        }
        if model.trashCategory.status == .done && model.trashCategory.total > 0 {
            list.append(Hint(id: "trash", icon: "trash", color: Theme.danger,
                             title: L10n.shared.t("sec.trash"),
                             text: L10n.shared.f("hint.trash", Format.bytes(model.trashCategory.total)),
                             section: .trash, bytes: model.trashCategory.total))
        }
        let junkScanned = model.categories.filter { $0.status == .done }
        let junkTotal = junkScanned.reduce(0) { $0 + $1.total }
        if junkTotal > 0 {
            list.append(Hint(id: "junk", icon: "sparkles", color: Theme.success,
                             title: L10n.shared.t("sec.junk"),
                             text: L10n.shared.f("hint.junk", Format.bytes(junkTotal)),
                             section: .junk, bytes: junkTotal))
        }
        list.sort { $0.bytes > $1.bytes }
        // Добиваем до трёх карточек универсальными подсказками
        if list.count < 3 && model.dupes.status != .done {
            list.append(Hint(id: "dupes-generic", icon: "square.on.square", color: Theme.accent,
                             title: L10n.shared.t("sec.duplicates"), text: L10n.shared.t("hint.dupesGeneric"),
                             section: .duplicates, bytes: 0))
        }
        if list.count < 3 && junkTotal == 0 {
            list.append(Hint(id: "junk-generic", icon: "sparkles", color: Theme.success,
                             title: L10n.shared.t("sec.junk"), text: L10n.shared.t("hint.junkGeneric"),
                             section: .junk, bytes: 0))
        }
        return Array(list.prefix(3))
    }

    var nextSteps: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.shared.t("next.title")).font(.headline)
            HStack(spacing: 12) {
                ForEach(hints) { hint in
                    hintCard(icon: hint.icon, color: hint.color,
                             title: hint.title, text: hint.text, section: hint.section)
                }
            }
        }
    }

    func hintCard(icon: String, color: Color, title: String, text: String, section: AppSection) -> some View {
        Button { model.section = section } label: {
            HStack(spacing: 12) {
                IconTile(symbol: icon, color: color, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.callout.weight(.semibold))
                    Text(text).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.stroke))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SegmentedBar: View {
    @Environment(CleanerViewModel.self) private var model

    struct Segment {
        let cat: FileCategory?
        let size: UInt64
        let isFree: Bool
    }

    var segments: [Segment] {
        let total = max(model.disk.volumeTotal, 1)
        let known = model.disk.usedByKnown
        let unknown = total > model.disk.volumeFree + known ? total - model.disk.volumeFree - known : 0
        var result: [Segment] = FileCategory.allCases.compactMap { cat in
            let size = model.disk.byCategory[cat] ?? 0
            return size > 0 ? Segment(cat: cat, size: size, isFree: false) : nil
        }
        if unknown > 0 { result.append(Segment(cat: nil, size: unknown, isFree: false)) }
        result.append(Segment(cat: nil, size: model.disk.volumeFree, isFree: true))
        return result
    }

    var body: some View {
        let total = max(model.disk.volumeTotal, 1)
        let spacing: CGFloat = 2
        GeometryReader { geo in
            let available = max(0, geo.size.width - spacing * CGFloat(segments.count - 1))
            HStack(spacing: spacing) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                    let color: Color = seg.cat?.color
                        ?? (seg.isFree ? Color.primary.opacity(0.12) : Color(nsColor: .tertiaryLabelColor))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: max(3, available * CGFloat(seg.size) / CGFloat(total)))
                        .contentShape(Rectangle())
                        .onTapGesture { if let cat = seg.cat { model.drillCategory = cat } }
                        .help(seg.cat.map { "\(L10n.shared.t($0.titleKey)) · \(Format.bytes(seg.size)) — \(L10n.shared.t("help.tapOpen"))" }
                              ?? "\((seg.isFree ? L10n.shared.t("cat.free") : L10n.shared.t("cat.system"))) · \(Format.bytes(seg.size))")
                }
            }
        }
        .frame(height: 16)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: - Детализация категории (проваливание из обзора)

struct CategoryDetailView: View {
    @Environment(CleanerViewModel.self) private var model
    let category: FileCategory
    @State private var sortBySize = true
    @State private var query = ""

    var files: [LargeFile] {
        var all = model.disk.topByCategory[category] ?? []
        if !query.isEmpty {
            all = all.filter {
                $0.name.localizedCaseInsensitiveContains(query)
                    || $0.path.localizedCaseInsensitiveContains(query)
            }
        }
        return sortBySize ? all : all.sorted { ($0.access ?? .distantPast) < ($1.access ?? .distantPast) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Button { model.drillCategory = nil } label: {
                    Label(L10n.shared.t("detail.back"), systemImage: "chevron.left")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                PageHeader(title: L10n.shared.t(category.titleKey),
                           subtitle: L10n.shared.f("catdetail.sub", L10n.shared.t(category.titleKey), Format.bytes(model.disk.byCategory[category] ?? 0), files.count))

                if files.isEmpty && query.isEmpty {
                    EmptyState(icon: "checkmark", title: L10n.shared.t("empty.cat.t"),
                               subtitle: L10n.shared.t("empty.cat.s"))
                } else {
                    HStack {
                        SearchField(query: $query)
                            .frame(maxWidth: 280)
                        SelectionToolbar(paths: files.map(\.path))
                        Spacer()
                        Picker("", selection: $sortBySize) {
                            Text(L10n.shared.t("sort.size")).tag(true)
                            Text(L10n.shared.t("sort.age")).tag(false)
                        }
                        .labelsHidden()
                        .frame(width: 130)
                    }

                    if files.isEmpty {
                        Text(L10n.shared.f("search.empty", query))
                            .font(.callout).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 30)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(files) { file in
                                SelectableRow(path: file.path, name: file.name, size: file.size,
                                              isDir: file.isDir,
                                              subtitle: file.path.replacingOccurrences(of: Scanner.home, with: "~"),
                                              note: file.accessNote)
                            }
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Тяжёлые папки

struct FoldersView: View {
    @Environment(CleanerViewModel.self) private var model
    @State private var query = ""

    var folders: [LargeFile] {
        let all = model.disk.topFolders
        guard !query.isEmpty else { return all }
        return all.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.path.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(title: L10n.shared.t("sec.folders"),
                           subtitle: L10n.shared.t("sub.folders"))

                if model.disk.phase == .scanning {
                    Card { HStack { ProgressView().controlSize(.small); Text(L10n.shared.t("misc.scanning")) }.padding(16) } }
                else if model.disk.phase != .done {
                    EmptyState(icon: "folder.badge.questionmark", iconColor: Theme.accent,
                               title: L10n.shared.t("empty.scanFirst.t"),
                               subtitle: L10n.shared.t("empty.scanFolders.s"),
                               buttonTitle: L10n.shared.t("btn.scan")) { Task { await model.runDeepScan(force: true) } }
                }
                else if model.disk.topFolders.isEmpty {
                    EmptyState(icon: "checkmark", title: L10n.shared.t("empty.noFolders.t"),
                               subtitle: L10n.shared.t("empty.noFolders.s"))
                }
                else {
                    HStack {
                        Text(L10n.shared.f("folders.count", folders.count, Format.bytes(folders.reduce(0) { $0 + $1.size })))
                            .font(.callout.weight(.medium)).foregroundStyle(.secondary)
                        Spacer()
                        SearchField(query: $query)
                            .frame(maxWidth: 280)
                    }
                    if folders.isEmpty {
                        Text(L10n.shared.f("search.empty", query))
                            .font(.callout).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 30)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(folders) { folder in
                                FolderRow(folder: folder)
                            }
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .padding(24)
        }
        .task { await model.runDeepScan() }
    }
}

struct FolderRow: View {
    @Environment(CleanerViewModel.self) private var model
    let folder: LargeFile
    @State private var expanded = false
    @State private var children: [CleanItem]? = nil

    var isSelected: Bool { model.selected.contains(folder.path) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                CheckBox(isOn: isSelected) { model.toggle(folder.path, $0) }
                IconTile(symbol: "folder.fill", color: Color(red: 0.93, green: 0.70, blue: 0.40), size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(folder.name)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Text(folder.path.replacingOccurrences(of: Scanner.home, with: "~"))
                        .font(.caption).foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .help(folder.path)
                Spacer(minLength: 8)
                Text(Format.bytes(folder.size))
                    .font(.callout.weight(.semibold).monospacedDigit())
                    .frame(minWidth: 76, alignment: .trailing)
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: folder.path)])
                } label: {
                    Label("Finder", systemImage: "folder")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Theme.ghost, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { expanded.toggle() }
                    if expanded && children == nil {
                        Task { children = await Scanner.scanChildren(of: folder.path, note: nil).prefix(20).map { $0 } }
                    }
                } label: {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 26, height: 26)
                        .background(Theme.ghost, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .help(L10n.shared.t("folders.expand"))
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
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.2)) { expanded.toggle() }
                if expanded && children == nil {
                    Task { children = await Scanner.scanChildren(of: folder.path, note: nil).prefix(20).map { $0 } }
                }
            }

            if expanded {
                VStack(spacing: 6) {
                    if let children {
                        if children.isEmpty {
                            Text(L10n.shared.t("folders.empty"))
                                .font(.caption).foregroundStyle(.tertiary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(children) { item in
                                SelectableRow(path: item.path, name: item.name, size: item.size,
                                              isDir: item.isDir,
                                              subtitle: item.path.replacingOccurrences(of: Scanner.home, with: "~"))
                            }
                        }
                    } else {
                        HStack { ProgressView().controlSize(.small); Text(L10n.shared.t("folders.counting")) }
                            .font(.callout).foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.leading, 40)
                .padding(.top, 6)
            }
        }
    }
}

// MARK: - Большие файлы

struct LargeFilesView: View {
    @Environment(CleanerViewModel.self) private var model
    @State private var sortBySize = true
    @State private var query = ""

    var items: [LargeFile] {
        var files = model.disk.largeFiles
        if !query.isEmpty {
            files = files.filter {
                $0.name.localizedCaseInsensitiveContains(query)
                    || $0.path.localizedCaseInsensitiveContains(query)
            }
        }
        return sortBySize ? files : files.sorted { ($0.access ?? .distantPast) < ($1.access ?? .distantPast) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(title: L10n.shared.t("sec.largeFiles"),
                           subtitle: L10n.shared.t("sub.largeFiles"))

                if model.disk.phase == .scanning {
                    Card { HStack { ProgressView().controlSize(.small); Text(L10n.shared.t("misc.scanning")) }.padding(16) } }
                else if model.disk.phase != .done {
                    EmptyState(icon: "doc.magnifyingglass", iconColor: Theme.accent,
                               title: L10n.shared.t("empty.scanFirst.t"),
                               subtitle: L10n.shared.t("empty.scanLarge.s"),
                               buttonTitle: L10n.shared.t("btn.scan")) { Task { await model.runDeepScan(force: true) } }
                }
                else if model.disk.largeFiles.isEmpty {
                    EmptyState(icon: "checkmark", title: L10n.shared.t("empty.none.t"),
                               subtitle: L10n.shared.t("empty.noneLarge.s"),
                               buttonTitle: L10n.shared.t("btn.rescan")) { Task { await model.runDeepScan(force: true) } }
                }
                else {
                    HStack {
                        Text(L10n.shared.f("misc.filesCount", items.count, Format.bytes(items.reduce(0) { $0 + $1.size })))
                            .font(.callout.weight(.medium)).foregroundStyle(.secondary)
                        Spacer()
                    }
                    HStack {
                        SearchField(query: $query)
                            .frame(maxWidth: 280)
                        SelectionToolbar(paths: items.map(\.path))
                        Spacer()
                        Picker("", selection: $sortBySize) {
                            Text(L10n.shared.t("sort.big")).tag(true)
                            Text(L10n.shared.t("sort.old")).tag(false)
                        }
                        .labelsHidden()
                        .frame(width: 130)
                    }

                    if items.isEmpty {
                        Text(L10n.shared.f("search.empty", query))
                            .font(.callout).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 30)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(items) { file in
                                SelectableRow(path: file.path, name: file.name, size: file.size,
                                              subtitle: file.path.replacingOccurrences(of: Scanner.home, with: "~"),
                                              note: file.accessNote)
                            }
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .padding(24)
        }
        .task { await model.runDeepScan() }
    }
}

// MARK: - Дубликаты

struct DuplicatesView: View {
    @Environment(CleanerViewModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    PageHeader(title: L10n.shared.t("sec.duplicates"),
                               subtitle: L10n.shared.t("sub.duplicates"))
                    Spacer()
                    ScanButton(title: L10n.shared.t("btn.findDupes"),
                               isScanning: model.dupes.status == .scanning || model.disk.phase == .scanning) {
                        Task { await model.runDupeScan() }
                    }
                }

                switch model.dupes.status {
                case .idle:
                    EmptyState(icon: "square.on.square", iconColor: Theme.accent,
                               title: L10n.shared.t("dup.idle.t"),
                               subtitle: L10n.shared.t("dup.idle.s"),
                               buttonTitle: L10n.shared.t("btn.findDupes")) { Task { await model.runDupeScan() } }
                case .scanning:
                    Card { HStack { ProgressView().controlSize(.small); Text(L10n.shared.t("dup.scanning")) }.padding(16) }
                case .done where model.dupes.groups.isEmpty:
                    EmptyState(icon: "checkmark", title: L10n.shared.t("dup.empty.t"),
                               subtitle: L10n.shared.t("dup.empty.s"))
                case .done:
                    // Сводная карточка
                    Card {
                        HStack(spacing: 12) {
                            IconTile(symbol: "square.on.square", color: Theme.accent, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.shared.f("dup.groups", model.dupes.groups.count))
                                    .font(.callout.weight(.semibold))
                                Text(L10n.shared.f("dup.free", Format.bytes(model.dupes.totalWaste)))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            PrimaryButton(title: L10n.shared.t("btn.selectAllDupes")) {
                                for g in model.dupes.groups {
                                    for p in g.paths.dropFirst() { model.selected.insert(p) }
                                }
                            }
                        }
                        .padding(16)
                    }

                    ForEach(model.dupes.groups) { group in
                        DupeGroupCard(group: group)
                    }
                default:
                    EmptyView()
                }

                if model.dupes.status == .done && !model.dupes.groups.isEmpty {
                    Text(L10n.shared.t("dup.note"))
                        .font(.caption).foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
            }
            .padding(24)
            .padding(.bottom, 70)
        }
        .task { await model.runDeepScan() }
    }
}

struct DupeGroupCard: View {
    @Environment(CleanerViewModel.self) private var model
    let group: DupeGroup
    @State private var expanded = false

    var firstName: String { URL(fileURLWithPath: group.paths.first ?? "").lastPathComponent }

    var body: some View {
        VStack(spacing: 0) {
            Button { withAnimation(.easeOut(duration: 0.2)) { expanded.toggle() } } label: {
                HStack(spacing: 12) {
                    FileIconView(name: firstName, isDir: false, size: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(firstName)
                                .font(.callout.weight(.semibold))
                                .lineLimit(1)
                            Text(L10n.shared.f("dup.waste", Format.bytes(group.waste)))
                                .badgeStyle(color: Color(red: 0.93, green: 0.55, blue: 0.35))
                        }
                        Text(L10n.shared.f("dup.copies", group.paths.count, Format.bytes(group.size)))
                            .font(.caption).foregroundStyle(.secondary)
                        Text(group.paths.map { ($0.replacingOccurrences(of: Scanner.home, with: "~") as NSString).deletingLastPathComponent }
                                .uniqued().joined(separator: " · "))
                            .font(.caption2).foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    Spacer()
                    GhostButton(title: L10n.shared.t("btn.selectDupes")) {
                        for p in group.paths.dropFirst() { model.selected.insert(p) }
                    }
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                Divider().padding(.horizontal, 14)
                VStack(spacing: 6) {
                    ForEach(group.paths, id: \.self) { p in
                        SelectableRow(path: p,
                                      name: URL(fileURLWithPath: p).lastPathComponent,
                                      size: group.size,
                                      subtitle: p.replacingOccurrences(of: Scanner.home, with: "~"))
                    }
                }
                .padding(10)
            }
        }
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.stroke))
    }
}

extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - Приложения

struct AppsView: View {
    @Environment(CleanerViewModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    PageHeader(title: L10n.shared.t("sec.apps"),
                               subtitle: L10n.shared.t("sub.apps"))
                    Spacer()
                    ScanButton(title: L10n.shared.t("btn.update"), isScanning: model.appsState.status == .scanning) {
                        Task { await model.scanApps() }
                    }
                }

                if model.appsState.status == .scanning {
                    Card { HStack { ProgressView().controlSize(.small); Text(L10n.shared.t("apps.scanning")) }.padding(16) }
                } else if model.appsState.status == .done {
                    if model.appsState.apps.isEmpty {
                        EmptyState(icon: "square.grid.2x2", iconColor: Theme.accent, title: L10n.shared.t("apps.none"))
                    } else {
                        HStack {
                            Text(L10n.shared.f("apps.count", model.appsState.apps.count, Format.bytes(model.appsState.apps.reduce(0) { $0 + $1.size })))
                                .font(.callout.weight(.medium)).foregroundStyle(.secondary)
                            Spacer()
                        }
                        VStack(spacing: 8) {
                            ForEach(model.appsState.apps) { app in
                                AppRow(app: app)
                            }
                        }
                    }

                    if !model.appsState.orphans.isEmpty {
                        OrphansCard()
                    } else if model.appsState.orphansScanned {
                        EmptyState(icon: "checkmark", title: L10n.shared.t("orph.none.t"),
                                   subtitle: L10n.shared.t("orph.none.s"))
                    }
                }
            }
            .padding(24)
        }
        .task {
            if model.appsState.status == .idle { await model.scanApps() }
        }
        .sheet(isPresented: Bindable(model).appsState.showUninstallSheet) {
            UninstallSheet()
        }
    }
}

struct AppRow: View {
    @Environment(CleanerViewModel.self) private var model
    let app: AppEntry

    var body: some View {
        HStack(spacing: 12) {
            if let icon = app.icon {
                Image(nsImage: icon).resizable().frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                FileIconView(name: app.name, isDir: false, size: 36)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name).font(.callout.weight(.medium))
                Text(app.url.path).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Text(Format.bytes(app.size))
                .font(.callout.weight(.semibold).monospacedDigit())
            GhostButton(title: L10n.shared.t("btn.deleteApp")) {
                Task { await model.prepareUninstall(app) }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.stroke))
    }
}

struct OrphansCard: View {
    @Environment(CleanerViewModel.self) private var model
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                IconTile(symbol: "folder", color: Color(red: 0.93, green: 0.70, blue: 0.40), size: 40)
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.shared.t("orph.title")).font(.callout.weight(.semibold))
                    Text(L10n.shared.f("orph.count", model.appsState.orphans.count, Format.bytes(model.appsState.orphans.reduce(0) { $0 + $1.size })))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(L10n.shared.t("orph.desc"))
                        .font(.caption2).foregroundStyle(.tertiary)
                }
                Spacer()
                GhostButton(title: L10n.shared.t(expanded ? "btn.hide" : "btn.showFiles")) {
                    withAnimation(.easeOut(duration: 0.2)) { expanded.toggle() }
                }
            }
            .padding(14)

            if expanded {
                Divider().padding(.horizontal, 14)
                VStack(spacing: 6) {
                    ForEach(model.appsState.orphans) { item in
                        SelectableRow(path: item.path, name: item.name, size: item.size,
                                      isDir: item.isDir, note: item.note)
                    }
                }
                .padding(10)
            }
        }
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.stroke))
    }
}

struct UninstallSheet: View {
    @Environment(CleanerViewModel.self) private var model
    @State private var chosen: Set<String> = []

    var body: some View {
        let app = model.appsState.pendingApp
        let leftovers = model.appsState.pendingLeftovers
        let totalChosen = chosen.reduce(0) { $0 + (model.sizeIndex[$1] ?? 0) }

        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                if let icon = app?.icon {
                    Image(nsImage: icon).resizable().frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.shared.f("uninst.title", app?.name ?? ""))
                        .font(.title3.bold())
                    Text(L10n.shared.t("uninst.sub"))
                        .font(.callout).foregroundStyle(.secondary)
                }
            }

            Text(L10n.shared.t("uninst.pick"))
                .font(.callout).foregroundStyle(.secondary)

            if leftovers.isEmpty {
                Text(L10n.shared.t("uninst.none"))
                    .font(.callout).foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(leftovers) { item in
                            HStack(spacing: 10) {
                                CheckBox(isOn: chosen.contains(item.path)) { on in
                                    if on { chosen.insert(item.path) } else { chosen.remove(item.path) }
                                }
                                FileIconView(name: item.name, isDir: item.isDir, size: 30)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.name).font(.callout.weight(.medium)).lineLimit(1)
                                    Text(item.path.replacingOccurrences(of: Scanner.home, with: "~"))
                                        .font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                                }
                                Spacer()
                                Text(Format.bytes(item.size))
                                    .font(.callout.weight(.semibold).monospacedDigit())
                                Button {
                                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
                                } label: {
                                    Label("Finder", systemImage: "folder")
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(Theme.ghost, in: RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .help(L10n.shared.t("help.finderOpen"))
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .frame(maxHeight: 260)
            }

            Text(L10n.shared.t("uninst.note"))
                .font(.caption).foregroundStyle(.tertiary)

            HStack {
                Spacer()
                Button(L10n.shared.t("btn.cancel")) { model.appsState.showUninstallSheet = false }
                    .buttonStyle(.plain)
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .keyboardShortcut(.cancelAction)
                Button {
                    var paths = chosen
                    if let app { paths.insert(app.url.path) }
                    model.appsState.showUninstallSheet = false
                    Task { await model.trashPaths(Array(paths)) }
                } label: {
                    Text(L10n.shared.f("dlg.confirmTrash", Format.bytes((app?.size ?? 0) + totalChosen)))
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 9)
                        .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 520)
        .onAppear {
            model.index(leftovers)
            chosen = Set(leftovers.map { $0.path })
        }
    }
}

// MARK: - Загрузки

struct DownloadsView: View {
    @Environment(CleanerViewModel.self) private var model
    @State private var query = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    PageHeader(title: L10n.shared.t("sec.downloads"),
                               subtitle: L10n.shared.t("sub.downloads"))
                    Spacer()
                    ScanButton(title: L10n.shared.t("btn.scan"), isScanning: model.downloadsCategory.status == .scanning) {
                        Task { await model.scanJunk(model.downloadsCategory) }
                    }
                }

                switch model.downloadsCategory.status {
                case .idle:
                    EmptyState(icon: "arrow.down.circle", iconColor: Theme.accent,
                               title: L10n.shared.t("empty.pressScan"))
                case .scanning:
                    Card { HStack { ProgressView().controlSize(.small); Text(L10n.shared.t("dl.scanning")) }.padding(16) }
                case .done where model.downloadsCategory.items.isEmpty:
                    EmptyState(icon: "checkmark", title: L10n.shared.t("dl.empty.t"),
                               subtitle: L10n.shared.t("dl.empty.s"))
                case .done:
                    let all = model.downloadsCategory.items
                    let items = query.isEmpty ? all : all.filter {
                        $0.name.localizedCaseInsensitiveContains(query)
                            || $0.path.localizedCaseInsensitiveContains(query)
                    }
                    HStack {
                        Text(L10n.shared.f("misc.filesCount", items.count, Format.bytes(items.reduce(0) { $0 + $1.size })))
                            .font(.callout.weight(.medium)).foregroundStyle(.secondary)
                        Spacer()
                    }
                    HStack {
                        SearchField(query: $query)
                            .frame(maxWidth: 280)
                        SelectionToolbar(paths: items.map(\.path))
                        Spacer()
                    }
                    if items.isEmpty {
                        Text(L10n.shared.f("search.empty", query))
                            .font(.callout).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 30)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(items) { item in
                                SelectableRow(path: item.path, name: item.name, size: item.size, date: item.mtime)
                            }
                        }
                        .padding(.bottom, 80)
                    }
                case .error(let msg):
                    Card { Text(L10n.shared.f("misc.error", msg)).foregroundStyle(Theme.danger).padding(16) }
                case .denied:
                    EmptyView()
                }
            }
            .padding(24)
        }
        .task {
            if model.downloadsCategory.status == .idle { await model.scanJunk(model.downloadsCategory) }
        }
    }
}

// MARK: - Системный мусор

struct JunkView: View {
    @Environment(CleanerViewModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    PageHeader(title: L10n.shared.t("sec.junk"),
                               subtitle: L10n.shared.t("sub.junk"))
                    Spacer()
                    ScanButton(title: L10n.shared.t("btn.scanAll"),
                               isScanning: model.categories.contains { $0.status == .scanning }) {
                        Task { await model.scanAllJunk() }
                    }
                }

                ForEach(model.categories) { cat in
                    JunkCategoryCard(cat: cat)
                }

                tmSnapshotsCard
            }
            .padding(24)
            .padding(.bottom, 70)
        }
        .task {
            if model.categories.allSatisfy({ $0.status == .idle }) { await model.scanAllJunk() }
            if model.tmSnapshots == nil { await model.loadTMSnapshots() }
        }
    }

    /// Информационная карточка о локальных снимках Time Machine (только чтение)
    var tmSnapshotsCard: some View {
        HStack(spacing: 12) {
            IconTile(symbol: "clock.arrow.2.circlepath", color: Color(nsColor: .secondaryLabelColor), size: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.shared.t("tm.title")).font(.callout.weight(.semibold))
                if let tm = model.tmSnapshots {
                    Text(tm.count == 0
                         ? L10n.shared.t("tm.none")
                         : L10n.shared.f("tm.count", tm.count, tm.last ?? "—"))
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("…").font(.caption).foregroundStyle(.secondary)
                }
                Text(L10n.shared.t("tm.desc"))
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.stroke))
    }
}

struct JunkCategoryCard: View {
    @Environment(CleanerViewModel.self) private var model
    let cat: CategoryState

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { cat.expanded.toggle() }
                if cat.expanded && cat.status == .idle { Task { await model.scanJunk(cat) } }
            } label: {
                HStack(spacing: 12) {
                    IconTile(symbol: cat.icon,
                             color: cat.isSafe ? Theme.accent : Color(red: 0.93, green: 0.70, blue: 0.40),
                             size: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.shared.t("junk.\(cat.id).t")).font(.callout.weight(.semibold))
                        Text(L10n.shared.t("junk.\(cat.id).s")).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
Text(L10n.shared.t("junk.badge")).badgeStyle(color: Color(red: 0.93, green: 0.55, blue: 0.35))
                    statusView
                    Image(systemName: cat.expanded ? "chevron.up" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if cat.expanded { bodyContent }
        }
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.stroke))
    }

    @ViewBuilder
    var statusView: some View {
        switch cat.status {
        case .idle:
            Text(L10n.shared.t("junk.notScanned")).font(.caption).foregroundStyle(.tertiary)
        case .scanning:
            ProgressView().controlSize(.small)
        case .done:
            Text(Format.bytes(cat.total)).font(.callout.weight(.semibold).monospacedDigit())
        case .denied:
            Text(L10n.shared.t("junk.denied")).font(.caption).foregroundStyle(.secondary)
        case .error:
            Image(systemName: "exclamationmark.triangle").foregroundStyle(Theme.danger)
        }
    }

    @ViewBuilder
    var bodyContent: some View {
        Divider().padding(.horizontal, 14)
        switch cat.status {
        case .scanning:
            Text(L10n.shared.t("misc.scanning")).font(.callout).foregroundStyle(.secondary).padding(14)
        case .done where cat.items.isEmpty:
            HStack {
                Image(systemName: "checkmark.circle").foregroundStyle(Theme.success)
                Text(L10n.shared.t("junk.clean")).font(.callout).foregroundStyle(.secondary)
            }
            .padding(14)
        case .done:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SelectionToolbar(paths: cat.items.map(\.path))
                    Text(L10n.shared.f("junk.selCount", cat.items.filter { model.selected.contains($0.path) }.count, cat.items.count))
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    GhostButton(title: L10n.shared.t("btn.update")) { Task { await model.scanJunk(cat) } }
                }
                ForEach(cat.items) { item in
                    SelectableRow(path: item.path, name: item.name, size: item.size,
                                  isDir: item.isDir, note: item.note, date: item.mtime)
                }
            }
            .padding(12)
        case .error(let msg):
            Text(L10n.shared.f("misc.error", msg)).font(.callout).foregroundStyle(Theme.danger).padding(14)
        default:
            EmptyView()
        }
    }
}

// MARK: - Автозагрузка

struct StartupView: View {
    @Environment(CleanerViewModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    PageHeader(title: L10n.shared.t("sec.startup"),
                               subtitle: L10n.shared.t("sub.startup"))
                    Spacer()
                    ScanButton(title: L10n.shared.t("btn.scan"), isScanning: model.startup.status == .scanning) {
                        Task { await model.scanStartup() }
                    }
                }

                // Баннер-пояснение
                HStack(spacing: 12) {
                    IconTile(symbol: "power", color: Theme.accent, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.shared.t("start.banner.t")).font(.callout.weight(.semibold))
                        Text(L10n.shared.t("start.banner.s"))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.accent.opacity(0.25)))

                switch model.startup.status {
                case .idle:
                    EmptyState(icon: "bolt", iconColor: Theme.accent, title: L10n.shared.t("empty.pressScan"))
                case .scanning:
                    Card { HStack { ProgressView().controlSize(.small); Text(L10n.shared.t("misc.scanning")) }.padding(16) }
                case .done where model.startup.items.isEmpty:
                    EmptyState(icon: "checkmark", title: L10n.shared.t("start.empty.t"),
                               subtitle: L10n.shared.t("start.empty.s"))
                case .done:
                    VStack(spacing: 8) {
                        ForEach(model.startup.items) { item in
                            SelectableRow(path: item.path, name: item.label, size: item.size,
                                          subtitle: item.program,
                                          note: item.programMissing ? L10n.shared.t("start.broken") : nil)
                        }
                    }
                    Text(L10n.shared.f("start.footer", model.startup.items.count))
                        .font(.caption).foregroundStyle(.tertiary)
                default:
                    EmptyView()
                }
            }
            .padding(24)
            .padding(.bottom, 70)
        }
        .task {
            if model.startup.status == .idle { await model.scanStartup() }
        }
    }
}

// MARK: - Корзина

struct TrashView: View {
    @Environment(CleanerViewModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    PageHeader(title: L10n.shared.t("sec.trash"),
                               subtitle: L10n.shared.t("sub.trash"))
                    Spacer()
                    ScanButton(title: L10n.shared.t("btn.update"), isScanning: model.trashCategory.status == .scanning) {
                        Task { await model.scanJunk(model.trashCategory) }
                    }
                }

                switch model.trashCategory.status {
                case .denied:
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.shared.t("trash.denied"))
                                .font(.callout).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Button(L10n.shared.t("trash.emptyBtn"), role: .destructive) {
                                model.showEmptyTrashConfirm = true
                            }
                            .controlSize(.small)
                        }
                        .padding(16)
                    }
                case .scanning:
                    Card { HStack { ProgressView().controlSize(.small); Text(L10n.shared.t("misc.scanning")) }.padding(16) }
                case .done where model.trashCategory.items.isEmpty:
                    EmptyState(icon: "trash", iconColor: Theme.accent,
                               title: L10n.shared.t("trash.clean.t"),
                               subtitle: L10n.shared.t("trash.clean.s"),
                               buttonTitle: L10n.shared.t("btn.toOverview")) { model.section = .overview }
                case .done:
                    // Hero-карточка Корзины
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 14) {
                                IconTile(symbol: "trash", color: Theme.danger, size: 52)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(Format.bytes(model.trashCategory.total))
                                        .font(.system(size: 30, weight: .bold))
                                    Text(L10n.shared.f("trash.count", model.trashCategory.items.count))
                                        .font(.callout).foregroundStyle(.secondary)
                                }
                                Spacer()
                                PrimaryButton(title: L10n.shared.t("trash.clear"), icon: "trash") {
                                    model.showEmptyTrashConfirm = true
                                }
                            }
                            Divider()
                            Text(L10n.shared.t("trash.note"))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(18)
                    }

                    Text(L10n.shared.t("trash.recent")).font(.headline)

                    VStack(spacing: 8) {
                        ForEach(model.trashCategory.items) { item in
                            SelectableRow(path: item.path, name: item.name, size: item.size,
                                          isDir: item.isDir, date: item.mtime, selectable: false)
                        }
                    }
                default:
                    EmptyState(icon: "trash", iconColor: Theme.accent, title: L10n.shared.t("empty.pressUpdate"))
                }
            }
            .padding(24)
        }
        .task {
            if model.trashCategory.status == .idle { await model.scanJunk(model.trashCategory) }
        }
    }
}

// MARK: - История

struct HistoryView: View {
    @Environment(CleanerViewModel.self) private var model

    var totalBytes: UInt64 { model.history.reduce(0) { $0 + $1.bytes } }
    var totalFiles: Int { model.history.reduce(0) { $0 + $1.count } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(title: L10n.shared.t("sec.history"),
                           subtitle: L10n.shared.t("sub.history"))

                if model.history.isEmpty {
                    EmptyState(icon: "clock", iconColor: Theme.accent, title: L10n.shared.t("hist.empty.t"),
                               subtitle: L10n.shared.t("hist.empty.s"))
                } else {
                    // Статистика
                    Card {
                        HStack(spacing: 0) {
                            statCell(value: Format.bytes(totalBytes), label: L10n.shared.t("hist.freed"))
                            statCell(value: "\(model.history.count)", label: L10n.shared.t("hist.runs"), accent: true)
                            statCell(value: "\(totalFiles)", label: L10n.shared.t("hist.items"))
                        }
                        .padding(.vertical, 18)
                    }

                    VStack(spacing: 8) {
                        ForEach(model.history) { entry in
                            HStack(spacing: 12) {
                                IconTile(symbol: "clock", color: Theme.accent, size: 34)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(Format.dateTime(entry.date)).font(.callout.weight(.medium))
                                    Text(L10n.shared.f("hist.row", entry.count))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(Format.bytes(entry.bytes))
                                    .font(.callout.weight(.semibold).monospacedDigit())
                            }
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.stroke))
                        }
                    }

                    Text(L10n.shared.t("hist.note"))
                        .font(.caption).foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
            }
            .padding(24)
        }
    }

    func statCell(value: String, label: String, accent: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(accent ? Theme.accent : .primary)
            Text(label)
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Настройки

struct SettingsView: View {
    @Environment(CleanerViewModel.self) private var model

    var appVersion: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = info?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(title: L10n.shared.t("sec.settings"),
                           subtitle: L10n.shared.t("sub.settings"))

                // Оформление
                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        Label(L10n.shared.t("settings.appearance"), systemImage: "paintbrush")
                            .font(.callout.weight(.semibold))
                        HStack {
                            Text(L10n.shared.t("settings.theme"))
                                .font(.callout).foregroundStyle(.secondary)
                            Spacer()
                            ThemeSwitcher()
                                .frame(width: 220)
                        }
                        Divider()
                        HStack {
                            Text(L10n.shared.t("settings.language"))
                                .font(.callout).foregroundStyle(.secondary)
                            Spacer()
                            LanguageSwitcher()
                                .frame(width: 220)
                        }
                    }
                    .padding(16)
                }

                // Разрешения
                Card {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(L10n.shared.t("settings.permissions"), systemImage: "lock.shield")
                            .font(.callout.weight(.semibold))
                            .padding(.bottom, 6)
                        PermissionRow(icon: "internaldrive", color: Theme.accent,
                                      titleKey: "settings.perm.fda", descKey: "settings.perm.fda.desc",
                                      status: Permissions.fullDiskAccess, pane: "Privacy_AllFiles")
                        Divider().padding(.vertical, 4)
                        PermissionRow(icon: "folder.badge.gearshape", color: Theme.success,
                                      titleKey: "settings.perm.files", descKey: "settings.perm.files.desc",
                                      status: Permissions.filesAndFolders, pane: "Privacy_FilesAndFolders")
                        Divider().padding(.vertical, 4)
                        PermissionRow(icon: "music.note", color: Color(red: 0.95, green: 0.65, blue: 0.78),
                                      titleKey: "settings.perm.media", descKey: "settings.perm.media.desc",
                                      status: Permissions.mediaLibrary, pane: "Privacy_Media")
                    }
                    .padding(16)
                }

                // Обновления
                Card {
                    HStack(spacing: 12) {
                        IconTile(symbol: "arrow.triangle.2.circlepath", color: Theme.accent, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.shared.t("settings.updates")).font(.callout.weight(.semibold))
                            Text("\(L10n.shared.t("settings.version")) \(appVersion)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        updateAction
                    }
                    .padding(16)
                }

                // О приложении
                Card {
                    HStack(spacing: 14) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Mac Cleaner").font(.callout.weight(.semibold))
                            Text("\(L10n.shared.t("settings.version")) \(appVersion)")
                                .font(.caption).foregroundStyle(.secondary)
                            Text("\(L10n.shared.t("settings.author")): \(L10n.shared.t("settings.authorName"))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .padding(24)
        }
    }

    /// Кнопка/статус проверки обновлений (GitHub Releases)
    @ViewBuilder
    var updateAction: some View {
        let updater = UpdateChecker.shared
        switch updater.state {
        case .idle:
            GhostButton(title: L10n.shared.t("settings.checkUpdates")) {
                Task { await updater.check() }
            }
        case .checking:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text(L10n.shared.t("upd.checking")).font(.caption).foregroundStyle(.secondary)
            }
        case .current:
            HStack(spacing: 10) {
                Text(L10n.shared.t("settings.latestVersion")).badgeStyle(color: Theme.success)
                GhostButton(title: L10n.shared.t("btn.update")) {
                    Task { await updater.check() }
                }
            }
        case .available(let v):
            HStack(spacing: 10) {
                Text(L10n.shared.f("upd.available", v)).badgeStyle(color: Theme.accent)
                GhostButton(title: L10n.shared.t("upd.download")) {
                    updater.openReleasePage()
                }
            }
        case .failed:
            HStack(spacing: 10) {
                Text(L10n.shared.t("upd.failed")).badgeStyle(color: Theme.danger)
                GhostButton(title: L10n.shared.t("settings.checkUpdates")) {
                    Task { await updater.check() }
                }
            }
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let color: Color
    let titleKey: String
    let descKey: String
    let status: PermStatus
    let pane: String

    var statusColor: Color {
        switch status {
        case .granted: return Theme.success
        case .denied: return Theme.danger
        case .unknown: return Color(red: 0.93, green: 0.70, blue: 0.40)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            IconTile(symbol: icon, color: color, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(L10n.shared.t(titleKey)).font(.callout.weight(.medium))
                    Text(L10n.shared.t(status.key)).badgeStyle(color: statusColor)
                }
                Text(L10n.shared.t(descKey))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            GhostButton(title: L10n.shared.t("settings.configure")) {
                Permissions.openSettings(pane: pane)
            }
        }
        .padding(.vertical, 6)
    }
}

struct LanguageSwitcher: View {
    var body: some View {
        HStack(spacing: 4) {
            langButton(value: "ru", label: "Русский")
            langButton(value: "en", label: "English")
        }
        .padding(3)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.stroke))
    }

    func langButton(value: String, label: String) -> some View {
        let active = L10n.shared.lang == value
        return Button {
            withAnimation(.easeOut(duration: 0.15)) { L10n.shared.lang = value }
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
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
