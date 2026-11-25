import AppKit

// MARK: - Стили анимированной иконки меню-бара
//
// Каждая иконка рисуется вектором на прозрачном фоне в template-режиме
// (macOS сама красит в чёрный/белый под тему меню-бара).
// Скорость анимации зависит от загрузки CPU — как в RunCat.

enum MenuBarIconStyle: String, CaseIterable, Identifiable {
    case trash, rotor, coffee, drop, newton, sheep, radiation

    var id: String { rawValue }
    var titleKey: String { "mbicon." + rawValue }

    static let iconSize: CGFloat = 22

    /// Кадр анимации. t — секунды с момента старта, cpu — загрузка 0…1
    func image(t: TimeInterval, cpu: Double) -> NSImage {
        switch self {
        case .trash:
            // Покачивание: чем выше загрузка — тем быстрее и размашистее
            let freq = 0.5 + cpu * 3.0
            let amp = 6.0 + cpu * 8.0
            let angle = sin(2 * .pi * freq * t) * amp
            return Self.rotated(Self.trashBase, degrees: angle)
        case .rotor:
            return rotorImage(t: t, cpu: cpu)
        case .coffee:
            return coffeeImage(t: t, cpu: cpu)
        case .drop:
            return dropImage(t: t, cpu: cpu)
        case .newton:
            return newtonImage(t: t, cpu: cpu)
        case .sheep:
            return sheepImage(t: t, cpu: cpu)
        case .radiation:
            return radiationImage(t: t, cpu: cpu)
        }
    }

    // MARK: Общий рендер кадра

    private static func render(_ draw: @escaping (CGFloat) -> Void) -> NSImage {
        let img = NSImage(size: NSSize(width: iconSize, height: iconSize), flipped: false) { rect in
            NSColor.black.setFill()
            NSColor.black.setStroke()
            draw(rect.width / 22.0)   // s — масштаб от базовой сетки 22
            return true
        }
        img.isTemplate = true
        return img
    }

    /// Поворот готовой иконки на угол
    static func rotated(_ image: NSImage, degrees: CGFloat) -> NSImage {
        let size = image.size
        let out = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current else { return false }
            ctx.imageInterpolation = .high
            let tr = NSAffineTransform()
            tr.translateX(by: rect.midX, yBy: rect.midY)
            tr.rotate(byDegrees: degrees)
            tr.translateX(by: -rect.midX, yBy: -rect.midY)
            tr.concat()
            image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
            return true
        }
        out.isTemplate = true
        return out
    }

    // MARK: Мусорка (базовый глиф, качается через rotated)

    static let trashBase: NSImage = {
        let img = NSImage(size: NSSize(width: iconSize, height: iconSize), flipped: false) { rect in
            NSColor.black.setFill()
            let s = rect.width / 22.0
            // Ручка крышки
            NSBezierPath(roundedRect: NSRect(x: 9 * s, y: 17.6 * s, width: 4 * s, height: 1.8 * s),
                         xRadius: 0.9 * s, yRadius: 0.9 * s).fill()
            // Крышка
            NSBezierPath(roundedRect: NSRect(x: 4 * s, y: 15 * s, width: 14 * s, height: 1.8 * s),
                         xRadius: 0.9 * s, yRadius: 0.9 * s).fill()
            // Корпус: трапеция со скруглённым низом
            let body = NSBezierPath()
            body.move(to: NSPoint(x: 5.5 * s, y: 13.5 * s))
            body.line(to: NSPoint(x: 16.5 * s, y: 13.5 * s))
            body.line(to: NSPoint(x: 15.3 * s, y: 4.5 * s))
            body.curve(to: NSPoint(x: 13.3 * s, y: 3 * s),
                       controlPoint1: NSPoint(x: 15.1 * s, y: 3.2 * s),
                       controlPoint2: NSPoint(x: 14.5 * s, y: 3 * s))
            body.line(to: NSPoint(x: 8.7 * s, y: 3 * s))
            body.curve(to: NSPoint(x: 6.7 * s, y: 4.5 * s),
                       controlPoint1: NSPoint(x: 7.5 * s, y: 3 * s),
                       controlPoint2: NSPoint(x: 6.9 * s, y: 3.2 * s))
            body.close()
            // Прорези (even-odd)
            for cx in [8.6, 11.0, 13.4] {
                body.append(NSBezierPath(roundedRect: NSRect(x: (cx - 0.6) * s, y: 5.5 * s,
                                                             width: 1.2 * s, height: 6.5 * s),
                                         xRadius: 0.6 * s, yRadius: 0.6 * s))
            }
            body.windingRule = .evenOdd
            body.fill()
            return true
        }
        img.isTemplate = true
        return img
    }()

    // MARK: Ротор двигателя Ванкеля — треугольный ротор в корпусе, вращается

    private func rotorImage(t: TimeInterval, cpu: Double) -> NSImage {
        let theta = 2 * .pi * (0.4 + cpu * 3.0) * t
        return Self.render { s in
            let cx = 11 * s, cy = 10.5 * s
            // Корпус: округлая «капсула» (эпитрохоида в миниатюре)
            let housing = NSBezierPath(ovalIn: NSRect(x: 2.5 * s, y: 2.5 * s,
                                                      width: 17 * s, height: 16 * s))
            housing.lineWidth = 1.3 * s
            housing.stroke()
            // Ротор: треугольник с выпуклыми гранями
            let r = 5.2 * s
            var pts: [NSPoint] = []
            for i in 0..<3 {
                let a = theta + Double(i) * 2 * Double.pi / 3
                pts.append(NSPoint(x: cx + r * CGFloat(cos(a)), y: cy + r * CGFloat(sin(a))))
            }
            let rotor = NSBezierPath()
            rotor.move(to: pts[0])
            for i in 0..<3 {
                let p1 = pts[i], p2 = pts[(i + 1) % 3]
                let mid = NSPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
                let out = NSPoint(x: cx + (mid.x - cx) * 1.5, y: cy + (mid.y - cy) * 1.5)
                rotor.curve(to: p2, controlPoint1: out, controlPoint2: out)
            }
            rotor.close()
            // Центральная шестерня (дырка)
            rotor.append(NSBezierPath(ovalIn: NSRect(x: cx - 1.4 * s, y: cy - 1.4 * s,
                                                     width: 2.8 * s, height: 2.8 * s)))
            rotor.windingRule = .evenOdd
            rotor.fill()
        }
    }

    // MARK: Кофе — чашка с поднимающимся паром

    private func coffeeImage(t: TimeInterval, cpu: Double) -> NSImage {
        let f = 0.5 + cpu * 2.0
        return Self.render { s in
            // Чашка: корпус-трапеция со скруглённым низом
            let cup = NSBezierPath()
            cup.move(to: NSPoint(x: 4.5 * s, y: 13.5 * s))
            cup.line(to: NSPoint(x: 13.5 * s, y: 13.5 * s))
            cup.line(to: NSPoint(x: 12.5 * s, y: 5 * s))
            cup.curve(to: NSPoint(x: 10.5 * s, y: 3.5 * s),
                      controlPoint1: NSPoint(x: 12.3 * s, y: 3.9 * s),
                      controlPoint2: NSPoint(x: 11.5 * s, y: 3.5 * s))
            cup.line(to: NSPoint(x: 7.5 * s, y: 3.5 * s))
            cup.curve(to: NSPoint(x: 5.5 * s, y: 5 * s),
                      controlPoint1: NSPoint(x: 6.5 * s, y: 3.5 * s),
                      controlPoint2: NSPoint(x: 5.7 * s, y: 3.9 * s))
            cup.close()
            cup.fill()
            // Ручка — кольцо справа
            let handle = NSBezierPath(ovalIn: NSRect(x: 12.6 * s, y: 7.5 * s,
                                                     width: 4.6 * s, height: 4.6 * s))
            handle.append(NSBezierPath(ovalIn: NSRect(x: 13.7 * s, y: 8.6 * s,
                                                      width: 2.4 * s, height: 2.4 * s)))
            handle.windingRule = .evenOdd
            handle.fill()
            // Блюдце
            NSBezierPath(roundedRect: NSRect(x: 4.5 * s, y: 1.5 * s, width: 9 * s, height: 1 * s),
                         xRadius: 0.5 * s, yRadius: 0.5 * s).fill()
            // Пар: две волны, поднимаются и тают; скорость — от CPU
            for i in 0..<2 {
                let x = (7.5 + CGFloat(i) * 3.0) * s
                let phase = (t * f + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
                let dy = CGFloat(phase) * 2.2 * s
                let alpha = CGFloat(1.0 - phase)
                let steam = NSBezierPath()
                steam.move(to: NSPoint(x: x, y: 15 * s + dy))
                steam.curve(to: NSPoint(x: x, y: 20 * s + dy),
                            controlPoint1: NSPoint(x: x - 1.5 * s, y: 16.5 * s + dy),
                            controlPoint2: NSPoint(x: x + 1.5 * s, y: 18.5 * s + dy))
                NSColor.black.withAlphaComponent(alpha).setStroke()
                steam.lineWidth = 1.1 * s
                steam.lineCapStyle = .round
                steam.stroke()
            }
        }
    }

    // MARK: Капля — падает вниз и растекается

    private func dropImage(t: TimeInterval, cpu: Double) -> NSImage {
        let period = 1.0 / (0.6 + cpu * 2.4)
        let phase = t.truncatingRemainder(dividingBy: period) / period   // 0…1
        return Self.render { s in
            if phase < 0.85 {
                // Падение с ускорением: от верха до низа
                let fall = phase / 0.85
                let y = (19.0 - 14.0 * fall * fall) * s
                Self.dropPath(cx: 11 * s, cy: y, s: s).fill()
            } else {
                // Всплеск: эллипс растёт и тает
                let p = (phase - 0.85) / 0.15
                let w = (2 + p * 9) * s
                NSColor.black.withAlphaComponent(CGFloat(1 - p)).setFill()
                NSBezierPath(ovalIn: NSRect(x: 11 * s - w / 2, y: 2.2 * s,
                                            width: w, height: 1.7 * s)).fill()
            }
        }
    }

    /// Глиф капли: кончик сверху, круглое донышко
    private static func dropPath(cx: CGFloat, cy: CGFloat, s: CGFloat) -> NSBezierPath {
        let p = NSBezierPath()
        p.move(to: NSPoint(x: cx, y: cy + 3.4 * s))
        p.curve(to: NSPoint(x: cx + 2.7 * s, y: cy - 1.0 * s),
                controlPoint1: NSPoint(x: cx + 1.9 * s, y: cy + 1.7 * s),
                controlPoint2: NSPoint(x: cx + 2.7 * s, y: cy + 0.5 * s))
        p.curve(to: NSPoint(x: cx - 2.7 * s, y: cy - 1.0 * s),
                controlPoint1: NSPoint(x: cx + 2.7 * s, y: cy - 3.5 * s),
                controlPoint2: NSPoint(x: cx - 2.7 * s, y: cy - 3.5 * s))
        p.curve(to: NSPoint(x: cx, y: cy + 3.4 * s),
                controlPoint1: NSPoint(x: cx - 2.7 * s, y: cy + 0.5 * s),
                controlPoint2: NSPoint(x: cx - 1.9 * s, y: cy + 1.7 * s))
        p.close()
        return p
    }

    // MARK: Овечка — бежит и перепрыгивает через забор

    private func sheepImage(t: TimeInterval, cpu: Double) -> NSImage {
        let period = 1.0 / (0.45 + cpu * 2.0)
        let p = t.truncatingRemainder(dividingBy: period) / period   // 0…1
        return Self.render { s in
            // Забор: две стойки и перекладина
            NSBezierPath(rect: NSRect(x: 9.6 * s, y: 3 * s, width: 1.0 * s, height: 6.5 * s)).fill()
            NSBezierPath(rect: NSRect(x: 12.4 * s, y: 3 * s, width: 1.0 * s, height: 6.5 * s)).fill()
            NSBezierPath(rect: NSRect(x: 8.8 * s, y: 8.2 * s, width: 5.4 * s, height: 1.2 * s)).fill()
            // Бег слева направо по кругу
            let x = (-2 + p * 26) * s
            // Прыжок дугой в районе забора
            var y = 7.0 * s
            let xu = Double(x / s)
            let jStart = 7.0, jEnd = 14.5
            let jumping = xu > jStart && xu < jEnd
            if jumping {
                let jp = (xu - jStart) / (jEnd - jStart)
                y += CGFloat(sin(.pi * jp)) * 6.0 * s
            }
            // Тело — облачко из трёх кругов
            for (dx, dy, r) in [(-1.8, 0.0, 2.0), (0.0, 0.9, 2.3), (1.8, 0.0, 2.0)] {
                let rr = CGFloat(r) * s
                NSBezierPath(ovalIn: NSRect(x: x + CGFloat(dx) * s - rr,
                                            y: y + CGFloat(dy) * s - rr,
                                            width: rr * 2, height: rr * 2)).fill()
            }
            // Голова спереди (по направлению бега)
            NSBezierPath(ovalIn: NSRect(x: x + 3.0 * s - 1.3 * s, y: y + 0.7 * s - 1.3 * s,
                                        width: 2.6 * s, height: 2.6 * s)).fill()
            // Ноги — только на земле; в прыжке поджаты
            if !jumping {
                NSBezierPath(rect: NSRect(x: x - 1.6 * s, y: y - 4.2 * s,
                                          width: 0.9 * s, height: 2.6 * s)).fill()
                NSBezierPath(rect: NSRect(x: x + 0.7 * s, y: y - 4.2 * s,
                                          width: 0.9 * s, height: 2.6 * s)).fill()
            }
        }
    }

    // MARK: Радиация — трефоил вращается

    private func radiationImage(t: TimeInterval, cpu: Double) -> NSImage {
        let theta = 360.0 * (0.3 + cpu * 2.7) * t
        return Self.render { s in
            let c = NSPoint(x: 11 * s, y: 11 * s)
            let r0 = 3.2 * s, r1 = 8.8 * s
            for i in 0..<3 {
                let center = 90.0 + Double(i) * 120.0 + theta
                let a0 = center - 30, a1 = center + 30
                let blade = NSBezierPath()
                blade.move(to: Self.polar(c, r0, a0))
                blade.line(to: Self.polar(c, r1, a0))
                blade.appendArc(withCenter: c, radius: r1, startAngle: a0, endAngle: a1)
                blade.line(to: Self.polar(c, r0, a1))
                blade.appendArc(withCenter: c, radius: r0, startAngle: a1, endAngle: a0, clockwise: true)
                blade.close()
                blade.fill()
            }
            // Центральный круг
            NSBezierPath(ovalIn: NSRect(x: c.x - 2 * s, y: c.y - 2 * s,
                                        width: 4 * s, height: 4 * s)).fill()
        }
    }

    /// Точка на окружности: угол в градусах, 0° — вправо, против часовой
    private static func polar(_ c: NSPoint, _ r: CGFloat, _ deg: Double) -> NSPoint {
        let a = deg * .pi / 180
        return NSPoint(x: c.x + r * CGFloat(cos(a)), y: c.y + r * CGFloat(sin(a)))
    }

    // MARK: Маятник Ньютона — крайние шары качаются по очереди

    private func newtonImage(t: TimeInterval, cpu: Double) -> NSImage {
        let w = 2 * .pi * (0.5 + cpu * 2.0)
        let aL = 0.65 * max(0, sin(w * t))
        let aR = 0.65 * max(0, -sin(w * t))
        return Self.render { s in
            // Верхняя перекладина
            NSBezierPath(roundedRect: NSRect(x: 3.5 * s, y: 18 * s, width: 15 * s, height: 1.1 * s),
                         xRadius: 0.55 * s, yRadius: 0.55 * s).fill()
            let r = 1.55 * s
            let len = 8.5 * s
            for i in 0..<5 {
                let px = (4.7 + CGFloat(i) * 3.1) * s
                let py = 18 * s
                let angle: CGFloat = i == 0 ? -aL : (i == 4 ? aR : 0)
                let bx = px + len * sin(angle)
                let by = py - len * cos(angle)
                let string = NSBezierPath()
                string.move(to: NSPoint(x: px, y: py))
                string.line(to: NSPoint(x: bx, y: by))
                string.lineWidth = 0.8 * s
                string.stroke()
                NSBezierPath(ovalIn: NSRect(x: bx - r, y: by - r,
                                            width: 2 * r, height: 2 * r)).fill()
            }
        }
    }
}
