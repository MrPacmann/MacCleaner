import SwiftUI
import AppKit

// MARK: - Карта диска (treemap, squarified layout)

struct TreeSlice: Identifiable {
    let id = UUID()
    let path: String
    let name: String
    let size: UInt64
    let hasChildren: Bool
}

/// Squarified treemap: раскладывает площади пропорционально значениям.
enum TreemapLayout {
    static func frames(for values: [Double], in rect: CGRect) -> [CGRect] {
        func worstRatio(_ row: [Double], _ sum: Double, _ side: Double) -> Double {
            row.reduce(0.0) { worst, a in
                let r1 = side * side * a / (sum * sum)
                let r2 = (sum * sum) / (side * side * a)
                return max(worst, max(r1, r2))
            }
        }

        var result = Array(repeating: CGRect.zero, count: values.count)
        let total = values.reduce(0, +)
        guard total > 0, rect.width > 1, rect.height > 1 else { return result }

        // Индексы, отсортированные по убыванию площади
        let order = values.indices.sorted { values[$0] > values[$1] }
        let areas = order.map { values[$0] / total * Double(rect.width * rect.height) }
        var r = rect
        var i = 0

        while i < areas.count {
            let side = Double(min(r.width, r.height))
            // Наращиваем строку, пока худшее соотношение сторон улучшается
            var rowCount = 1
            var rowSum = areas[i]
            while i + rowCount < areas.count {
                let newSum = rowSum + areas[i + rowCount]
                let worstNow = worstRatio(Array(areas[i..<(i + rowCount)]), rowSum, side)
                let worstNew = worstRatio(Array(areas[i..<(i + rowCount + 1)]), newSum, side)
                if worstNew <= worstNow {
                    rowCount += 1
                    rowSum = newSum
                } else { break }
            }

            // Раскладываем строку вдоль короткой стороны
            let horizontal = r.width >= r.height // строка — вертикальная полоса слева
            if horizontal {
                let stripW = CGFloat(rowSum / Double(r.height))
                var y = r.minY
                for k in 0..<rowCount {
                    let h = CGFloat(areas[i + k] / Double(stripW))
                    result[order[i + k]] = CGRect(x: r.minX, y: y, width: stripW, height: h)
                    y += h
                }
                r = CGRect(x: r.minX + stripW, y: r.minY,
                           width: r.width - stripW, height: r.height)
            } else {
                let stripH = CGFloat(rowSum / Double(r.width))
                var x = r.minX
                for k in 0..<rowCount {
                    let w = CGFloat(areas[i + k] / Double(stripH))
                    result[order[i + k]] = CGRect(x: x, y: r.minY, width: w, height: stripH)
                    x += w
                }
                r = CGRect(x: r.minX, y: r.minY + stripH,
                           width: r.width, height: r.height - stripH)
            }
            i += rowCount
        }
        return result
    }
}

// MARK: - Раздел «Карта диска»

struct MapView: View {
    @Environment(CleanerViewModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(title: L10n.shared.t("sec.map"),
                           subtitle: L10n.shared.t("sub.map"))

                if model.disk.phase == .scanning {
                    Card { HStack { ProgressView().controlSize(.small); Text(L10n.shared.t("misc.scanning")) }.padding(16) } }
                else if model.disk.phase != .done {
                    EmptyState(icon: "square.split.2x2", iconColor: Theme.accent,
                               title: L10n.shared.t("empty.scanFirst.t"),
                               subtitle: L10n.shared.t("empty.scanFolders.s"),
                               buttonTitle: L10n.shared.t("btn.scan")) { model.startDeepScan(force: true) }
                }
                else {
                    TreemapCard(height: 480)
                }
            }
            .padding(24)
        }
        .task { await model.runDeepScan() }
    }
}

struct TreemapCard: View {
    @Environment(CleanerViewModel.self) private var model
    var height: CGFloat = 260
    @State private var drill: String? = nil

    static let palette: [Color] = [
        Color(red: 0.60, green: 0.55, blue: 0.97),
        Color(red: 0.95, green: 0.65, blue: 0.78),
        Color(red: 0.96, green: 0.72, blue: 0.45),
        Color(red: 0.55, green: 0.72, blue: 0.95),
        Color(red: 0.42, green: 0.84, blue: 0.72),
        Color(red: 0.86, green: 0.89, blue: 0.45),
        Color(red: 0.91, green: 0.46, blue: 0.55),
    ]

    static func color(for path: String) -> Color {
        palette[abs(path.hashValue) % palette.count]
    }

    /// Дети текущего уровня: глубина 1 → из topLevel, глубже → из folderSizes
    var slices: [TreeSlice] {
        var entries: [(path: String, size: UInt64)]
        if let drill {
            let prefix = drill + "/"
            entries = model.disk.folderSizes
                .filter { path, _ in
                    path.hasPrefix(prefix)
                        && path.dropFirst(prefix.count).split(separator: "/").count == 1
                }
                .map { ($0.key, $0.value) }
        } else {
            entries = model.disk.topLevel.map { ($0.key, $0.value) }
        }
        entries.sort { $0.size > $1.size }

        // Мелочь объединяем в «Остальное», чтобы карта не рассыпалась
        let maxNodes = 20
        if entries.count > maxNodes {
            let rest = entries.dropFirst(maxNodes - 1).reduce(0) { $0 + $1.size }
            entries = Array(entries.prefix(maxNodes - 1))
            entries.append(("__other__", rest))
        }

        return entries.map { path, size in
            let hasKids = path != "__other__"
                && model.disk.folderSizes.keys.contains { $0.hasPrefix(path + "/") }
            return TreeSlice(path: path,
                             name: path == "__other__"
                                ? L10n.shared.t("map.other")
                                : (path as NSString).lastPathComponent,
                             size: size, hasChildren: hasKids)
        }
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    if drill != nil {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                drill = drill.map { ($0 as NSString).deletingLastPathComponent }
                                if drill == Scanner.home { drill = nil }
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 26, height: 26)
                                .background(Theme.ghost, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .help(L10n.shared.t("map.back"))
                    }
                    Text(L10n.shared.t("map.title")).font(.callout.weight(.semibold))
                    if let drill {
                        Text(drill.replacingOccurrences(of: Scanner.home, with: "~"))
                            .font(.caption).foregroundStyle(.secondary)
                            .lineLimit(1).truncationMode(.middle)
                    }
                    Spacer()
                    Text(L10n.shared.t("map.hint"))
                        .font(.caption2).foregroundStyle(.tertiary)
                }

                GeometryReader { geo in
                    let current = slices
                    let rects = TreemapLayout.frames(for: current.map { Double($0.size) },
                                                     in: CGRect(origin: .zero, size: geo.size))
                    ZStack(alignment: .topLeading) {
                        ForEach(Array(current.enumerated()), id: \.element.id) { idx, slice in
                            let f = rects[idx]
                            cell(slice, frame: f)
                        }
                    }
                }
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(20)
        }
    }

    @ViewBuilder
    func cell(_ slice: TreeSlice, frame f: CGRect) -> some View {
        let color = slice.path == "__other__"
            ? Color(nsColor: .separatorColor) : TreemapCard.color(for: slice.path)
        Button {
            if slice.hasChildren {
                withAnimation(.easeOut(duration: 0.2)) { drill = slice.path }
            }
        } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(color.opacity(0.85))
                if f.width > 64 && f.height > 34 {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(slice.name)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                        if f.height > 50 {
                            Text(Format.bytes(slice.size))
                                .font(.caption2)
                                .opacity(0.8)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 5)
                }
            }
            .frame(width: max(f.width - 2, 0), height: max(f.height - 2, 0))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("\(slice.path == "__other__" ? slice.name : slice.path.replacingOccurrences(of: Scanner.home, with: "~")) · \(Format.bytes(slice.size))")
        .offset(x: f.minX + 1, y: f.minY + 1)
    }
}
