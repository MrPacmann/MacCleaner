import Foundation
import SwiftUI
import Darwin
import IOKit.ps

// MARK: - Мониторинг железа (CPU, память, батарея, нагрев)
//
// Используются только публичные API: host_statistics, sysctl, IOPS, ProcessInfo.
// Точная температура и обороты вентиляторов на Apple Silicon без прав
// администратора недоступны — вместо градусов показываем «тепловое давление»
// системы (ProcessInfo.thermalState): так же честно оценивает нагрев сама macOS.

@MainActor
@Observable
final class MonitorState {
    var cpuUsage: Double = 0                 // 0…1
    var loadAvg: (Double, Double, Double) = (0, 0, 0)
    let coreCount: Int = ProcessInfo.processInfo.processorCount

    var memUsed: UInt64 = 0
    let memTotal: UInt64 = ProcessInfo.processInfo.physicalMemory
    var swapUsed: UInt64 = 0

    var hasBattery: Bool = false
    var batteryLevel: Int = 0                // %
    var batteryCharging: Bool = false

    var thermal: ProcessInfo.ThermalState = .nominal
    var uptime: TimeInterval = 0
    var diskFree: UInt64 = 0
    var diskTotal: UInt64 = 0

    let macOSVersion: String = ProcessInfo.processInfo.operatingSystemVersionString
        .replacingOccurrences(of: "Version ", with: "")
        .replacingOccurrences(of: #" \(Build .*\)"#, with: "", options: .regularExpression)
    let chipName: String = MonitorState.sysctlString("machdep.cpu.brand_string")
        .isEmpty ? "Apple Silicon" : MonitorState.sysctlString("machdep.cpu.brand_string")

    private var prevTicks: (user: UInt64, sys: UInt64, idle: UInt64, nice: UInt64)?

    func refresh() {
        // CPU: дельта тиков между замерами
        if let ticks = Self.cpuTicks() {
            if let prev = prevTicks {
                let dIdle = ticks.idle &- prev.idle
                let dTotal = (ticks.user &- prev.user) &+ (ticks.sys &- prev.sys)
                           &+ (ticks.nice &- prev.nice) &+ dIdle
                cpuUsage = dTotal > 0 ? max(0, min(1, 1.0 - Double(dIdle) / Double(dTotal))) : 0
            }
            prevTicks = ticks
        }
        var loads = [Double](repeating: 0, count: 3)
        getloadavg(&loads, 3)
        loadAvg = (loads[0], loads[1], loads[2])

        memUsed = Self.memoryUsed() ?? 0
        swapUsed = Self.swapUsage()
        let batt = Self.batteryInfo()
        hasBattery = batt.hasBattery
        batteryLevel = batt.level
        batteryCharging = batt.charging
        thermal = ProcessInfo.processInfo.thermalState
        uptime = ProcessInfo.processInfo.systemUptime
        let caps = Scanner.volumeCapacities()
        diskFree = caps.free
        diskTotal = caps.total
    }

    // MARK: Низкоуровневые замеры

    private static func cpuTicks() -> (user: UInt64, sys: UInt64, idle: UInt64, nice: UInt64)? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return nil }
        // CPU_STATE_USER, CPU_STATE_SYSTEM, CPU_STATE_IDLE, CPU_STATE_NICE
        return (UInt64(info.cpu_ticks.0), UInt64(info.cpu_ticks.1),
                UInt64(info.cpu_ticks.2), UInt64(info.cpu_ticks.3))
    }

    private static func memoryUsed() -> UInt64? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return nil }
        let page = UInt64(vm_kernel_page_size)
        return (UInt64(stats.active_count) + UInt64(stats.wire_count)
                + UInt64(stats.compressor_page_count)) * page
    }

    private static func swapUsage() -> UInt64 {
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        sysctlbyname("vm.swapusage", &usage, &size, nil, 0)
        return usage.xsu_used
    }

    private static func batteryInfo() -> (level: Int, charging: Bool, hasBattery: Bool) {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef]
        else { return (0, false, false) }
        for ps in sources {
            guard let desc = IOPSGetPowerSourceDescription(blob, ps)?.takeUnretainedValue() as? [String: Any],
                  let type = desc[kIOPSTypeKey] as? String, type == kIOPSInternalBatteryType
            else { continue }
            let cur = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
            let maxCap = desc[kIOPSMaxCapacityKey] as? Int ?? 100
            let charging = desc[kIOPSIsChargingKey] as? Bool ?? false
            let level = maxCap > 0 ? Int(Double(cur) / Double(maxCap) * 100) : 0
            return (level, charging, true)
        }
        return (0, false, false)
    }

    private static func sysctlString(_ name: String) -> String {
        var size = 0
        sysctlbyname(name, nil, &size, nil, 0)
        guard size > 0 else { return "" }
        var buf = [CChar](repeating: 0, count: size)
        sysctlbyname(name, &buf, &size, nil, 0)
        return String(cString: buf)
    }

    // MARK: Отображение

    var thermalTitle: String {
        switch thermal {
        case .nominal: return L10n.shared.t("mon.thermal.nominal")
        case .fair: return L10n.shared.t("mon.thermal.fair")
        case .serious: return L10n.shared.t("mon.thermal.serious")
        case .critical: return L10n.shared.t("mon.thermal.critical")
        @unknown default: return "—"
        }
    }

    var thermalColor: Color {
        switch thermal {
        case .nominal: return Theme.success
        case .fair: return Color(red: 0.93, green: 0.70, blue: 0.40)
        case .serious: return Color(red: 0.93, green: 0.55, blue: 0.35)
        case .critical: return Theme.danger
        @unknown default: return .secondary
        }
    }

    var uptimeText: String {
        let total = Int(uptime)
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let mins = (total % 3600) / 60
        let ru = L10n.shared.lang != "en"
        if days > 0 {
            let dWord = ru
                ? (days == 1 ? "день" : days < 5 ? "дня" : "дней")
                : (days == 1 ? "day" : "days")
            let hWord = ru
                ? (hours == 1 ? "час" : hours < 5 ? "часа" : "часов")
                : (hours == 1 ? "hour" : "hours")
            return "\(days) \(dWord) \(hours) \(hWord)"
        }
        if hours > 0 {
            let hWord = ru
                ? (hours == 1 ? "час" : hours < 5 ? "часа" : "часов")
                : (hours == 1 ? "hour" : "hours")
            return "\(hours) \(hWord) \(mins) " + (ru ? "мин" : "min")
        }
        return "\(mins) " + (ru ? "мин" : "min")
    }
}

// MARK: - Экран «Мониторинг»

struct MonitorView: View {
    @Environment(CleanerViewModel.self) private var model

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PageHeader(title: L10n.shared.t("sec.monitor"),
                           subtitle: L10n.shared.t("sub.monitor"))

                LazyVGrid(columns: columns, spacing: 14) {
                    cpuCard
                    memoryCard
                    batteryCard
                    thermalCard
                    diskCard
                    systemCard
                }

                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(L10n.shared.t("mon.tempNote"))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 4)
            }
            .padding(24)
        }
        .task {
            while !Task.isCancelled {
                model.monitor.refresh()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    // MARK: Карточки

    private var cpuCard: some View {
        MonitorCard(icon: "cpu", title: L10n.shared.t("mon.cpu"),
                    color: Color(red: 0.55, green: 0.72, blue: 0.95)) {
            Text("\(Int(model.monitor.cpuUsage * 100))%")
                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
            MiniBar(value: model.monitor.cpuUsage,
                    color: Color(red: 0.55, green: 0.72, blue: 0.95))
            Text(L10n.shared.f("mon.loadAvg",
                               String(format: "%.2f", model.monitor.loadAvg.0),
                               String(format: "%.2f", model.monitor.loadAvg.1),
                               String(format: "%.2f", model.monitor.loadAvg.2)))
                .font(.caption).foregroundStyle(.secondary)
            Text(L10n.shared.f("mon.cores", model.monitor.coreCount))
                .font(.caption2).foregroundStyle(.tertiary)
        }
    }

    private var memoryCard: some View {
        let used = model.monitor.memUsed
        let total = model.monitor.memTotal
        return MonitorCard(icon: "memorychip", title: L10n.shared.t("mon.memory"),
                           color: Color(red: 0.42, green: 0.84, blue: 0.72)) {
            Text(L10n.shared.f("mon.usedOf", Format.bytes(used), Format.bytes(total)))
                .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
            MiniBar(value: total > 0 ? Double(used) / Double(total) : 0,
                    color: Color(red: 0.42, green: 0.84, blue: 0.72))
            Text(L10n.shared.f("mon.swap", Format.bytes(model.monitor.swapUsed)))
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var batteryCard: some View {
        MonitorCard(icon: model.monitor.hasBattery
                    ? (model.monitor.batteryCharging ? "battery.100percent.bolt" : "battery.75percent")
                    : "bolt.fill",
                    title: L10n.shared.t("mon.battery"),
                    color: Color(red: 0.86, green: 0.89, blue: 0.45)) {
            if model.monitor.hasBattery {
                Text("\(model.monitor.batteryLevel)%")
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                MiniBar(value: Double(model.monitor.batteryLevel) / 100,
                        color: Color(red: 0.86, green: 0.89, blue: 0.45))
                Text(L10n.shared.t(model.monitor.batteryCharging ? "mon.charging" : "mon.discharging"))
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text(L10n.shared.t("mon.noBattery"))
                    .font(.callout.weight(.medium)).foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
        }
    }

    private var thermalCard: some View {
        MonitorCard(icon: "thermometer.medium", title: L10n.shared.t("mon.thermal"),
                    color: model.monitor.thermalColor) {
            Text(model.monitor.thermalTitle)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(model.monitor.thermalColor)
                .padding(.vertical, 6)
        }
    }

    private var diskCard: some View {
        MonitorCard(icon: "internaldrive", title: L10n.shared.t("mon.disk"),
                    color: Theme.accent) {
            Text(L10n.shared.f("mon.freeOf", Format.bytes(model.monitor.diskFree),
                               Format.bytes(model.monitor.diskTotal)))
                .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
            MiniBar(value: model.monitor.diskTotal > 0
                    ? 1.0 - Double(model.monitor.diskFree) / Double(model.monitor.diskTotal) : 0,
                    color: Theme.accent)
        }
    }

    private var systemCard: some View {
        MonitorCard(icon: "desktopcomputer", title: L10n.shared.t("mon.system"),
                    color: Color(red: 0.60, green: 0.55, blue: 0.97)) {
            Text(L10n.shared.f("mon.mac", model.monitor.macOSVersion, model.monitor.chipName))
                .font(.callout.weight(.medium))
                .lineLimit(1)
            Text(L10n.shared.f("mon.uptime", model.monitor.uptimeText))
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Общая карточка монитора

struct MonitorCard<Content: View>: View {
    let icon: String
    let title: String
    let color: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.stroke))
    }
}

/// Тонкая полоска прогресса для карточек монитора
struct MiniBar: View {
    let value: Double   // 0…1
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.08))
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: geo.size.width * max(0, min(1, value)))
            }
        }
        .frame(height: 6)
    }
}
