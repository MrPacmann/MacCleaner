import AppKit

let size: CGFloat = 1024
let outDir = CommandLine.arguments[1]

// MARK: - Хелперы

func tintedSymbol(_ name: String, pointSize: CGFloat, color: NSColor,
                  weight: NSFont.Weight = .medium) -> NSImage? {
    guard let base = NSImage(systemSymbolName: name, variableValue: 1.0, accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: pointSize, weight: weight)) else { return nil }
    let img = NSImage(size: base.size)
    img.lockFocus()
    base.draw(in: NSRect(origin: .zero, size: base.size))
    color.set()
    NSRect(origin: .zero, size: base.size).fill(using: .sourceAtop)
    img.unlockFocus()
    return img
}

func gradientSymbol(_ name: String, pointSize: CGFloat, gradient: NSGradient,
                    weight: NSFont.Weight = .medium) -> NSImage? {
    guard let base = NSImage(systemSymbolName: name, variableValue: 1.0, accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: pointSize, weight: weight)) else { return nil }
    let img = NSImage(size: base.size)
    img.lockFocus()
    base.draw(in: NSRect(origin: .zero, size: base.size))
    NSGraphicsContext.current?.compositingOperation = .sourceIn
    gradient.draw(in: NSRect(origin: .zero, size: base.size), angle: -60)
    img.unlockFocus()
    return img
}

func drawCentered(_ img: NSImage, in rect: NSRect, dy: CGFloat = 0) {
    let x = rect.midX - img.size.width / 2
    let y = rect.midY - img.size.height / 2 + dy
    img.draw(in: NSRect(x: x, y: y, width: img.size.width, height: img.size.height))
}

func squircle(_ inset: CGFloat, radius k: CGFloat = 0.225) -> NSBezierPath {
    NSBezierPath(roundedRect: NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2),
                 xRadius: size * k, yRadius: size * k)
}

func render(_ name: String, _ body: @escaping () -> Void) {
    let img = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
        body()
        return true
    }
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("FAIL \(name)"); return
    }
    try? png.write(to: URL(fileURLWithPath: outDir + "/" + name))
    print("OK \(name)")
}

let purple = NSGradient(colors: [
    NSColor(calibratedRed: 0.62, green: 0.52, blue: 0.99, alpha: 1),
    NSColor(calibratedRed: 0.44, green: 0.34, blue: 0.93, alpha: 1)
])!
let purpleDeep = NSGradient(colors: [
    NSColor(calibratedRed: 0.55, green: 0.44, blue: 0.98, alpha: 1),
    NSColor(calibratedRed: 0.36, green: 0.27, blue: 0.86, alpha: 1)
])!
let dark = NSGradient(colors: [
    NSColor(calibratedRed: 0.13, green: 0.13, blue: 0.19, alpha: 1),
    NSColor(calibratedRed: 0.07, green: 0.07, blue: 0.11, alpha: 1)
])!
let light = NSGradient(colors: [
    NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1),
    NSColor(calibratedRed: 0.93, green: 0.93, blue: 0.97, alpha: 1)
])!
let full = NSRect(x: 0, y: 0, width: size, height: size)
let inset: CGFloat = 40

// Верхний блик
func gloss(_ path: NSBezierPath) {
    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    NSGradient(colors: [NSColor.white.withAlphaComponent(0.18), .clear])!
        .draw(in: NSRect(x: inset, y: size * 0.55, width: size - inset * 2, height: size * 0.45),
              angle: -90)
    NSGraphicsContext.restoreGraphicsState()
}

// MARK: - 1. Фиолетовый сквиркл + корзина с блёсткой
render("concept1.png") {
    let p = squircle(inset)
    purple.draw(in: p, angle: -60)
    gloss(p)
    if let t = tintedSymbol("trash.fill", pointSize: 430, color: .white) {
        drawCentered(t, in: full, dy: -10)
    }
    // блёстка в кружке справа снизу
    let badgeR = NSRect(x: size - 300, y: 130, width: 190, height: 190)
    NSColor(calibratedRed: 0.36, green: 0.27, blue: 0.86, alpha: 1).setFill()
    NSBezierPath(ovalIn: badgeR).fill()
    NSColor.white.setStroke()
    NSBezierPath(ovalIn: badgeR.insetBy(dx: -8, dy: -8)).lineWidth = 10
    NSBezierPath(ovalIn: badgeR.insetBy(dx: -8, dy: -8)).stroke()
    if let s = tintedSymbol("sparkles", pointSize: 90, color: .white) {
        drawCentered(s, in: badgeR)
    }
}

// MARK: - 2. Тёмный сквиркл + градиентная диаграмма
render("concept2.png") {
    let p = squircle(inset)
    dark.draw(in: p, angle: -90)
    // тонкая фиолетовая окантовка
    NSColor(calibratedRed: 0.55, green: 0.44, blue: 0.98, alpha: 1).setStroke()
    p.lineWidth = 6
    p.stroke()
    if let c = gradientSymbol("chart.pie.fill", pointSize: 470, gradient: purple) {
        drawCentered(c, in: full)
    }
}

// MARK: - 3. Фиолетовый сквиркл + кисть
render("concept3.png") {
    let p = squircle(inset)
    purpleDeep.draw(in: p, angle: -45)
    gloss(p)
    if let b = tintedSymbol("paintbrush.fill", pointSize: 440, color: .white) {
        drawCentered(b, in: full)
    }
}

// Блёстка в кружке справа снизу
func sparkleBadge() {
    let badgeR = NSRect(x: size - 300, y: 130, width: 190, height: 190)
    NSColor(calibratedRed: 0.51, green: 0.40, blue: 0.96, alpha: 1).setFill()
    NSBezierPath(ovalIn: badgeR).fill()
    if let s = tintedSymbol("sparkles", pointSize: 90, color: .white) {
        drawCentered(s, in: badgeR)
    }
}

// MARK: - 5. Светлый сквиркл + фиолетовая кисть + блёстка (4 + 3 + 1)
render("concept5.png") {
    let p = squircle(inset)
    light.draw(in: p, angle: -90)
    NSColor.black.withAlphaComponent(0.08).setStroke()
    p.lineWidth = 3
    p.stroke()
    if let b = gradientSymbol("paintbrush.fill", pointSize: 440, gradient: purpleDeep) {
        drawCentered(b, in: full, dy: 14)
    }
    sparkleBadge()
}

// MARK: - 6. Фиолетовый сквиркл + белая кисть + блёстка (3 + 1)
render("concept6.png") {
    let p = squircle(inset)
    purpleDeep.draw(in: p, angle: -45)
    gloss(p)
    if let b = tintedSymbol("paintbrush.fill", pointSize: 440, color: .white) {
        drawCentered(b, in: full, dy: 14)
    }
    // блёстка на тёмно-фиолетовом кружке с белой окантовкой
    let badgeR = NSRect(x: size - 300, y: 130, width: 190, height: 190)
    NSColor(calibratedRed: 0.36, green: 0.27, blue: 0.86, alpha: 1).setFill()
    NSBezierPath(ovalIn: badgeR).fill()
    NSColor.white.setStroke()
    let ring = NSBezierPath(ovalIn: badgeR.insetBy(dx: -8, dy: -8))
    ring.lineWidth = 10
    ring.stroke()
    if let s = tintedSymbol("sparkles", pointSize: 90, color: .white) {
        drawCentered(s, in: badgeR)
    }
}

// MARK: - 7. Светлый сквиркл + фиолетовая кисть + мусорка
render("concept7.png") {
    let p = squircle(inset)
    light.draw(in: p, angle: -90)
    NSColor.black.withAlphaComponent(0.08).setStroke()
    p.lineWidth = 3
    p.stroke()
    if let b = gradientSymbol("paintbrush.fill", pointSize: 430, gradient: purpleDeep) {
        drawCentered(b, in: full, dy: 30)
    }
    if let t = gradientSymbol("trash.fill", pointSize: 210, gradient: purpleDeep) {
        t.draw(in: NSRect(x: size - 330, y: 150, width: t.size.width, height: t.size.height))
    }
}

// MARK: - 8. Фиолетовый сквиркл + белая кисть + мусорка
render("concept8.png") {
    let p = squircle(inset)
    purpleDeep.draw(in: p, angle: -45)
    gloss(p)
    if let b = tintedSymbol("paintbrush.fill", pointSize: 430, color: .white) {
        drawCentered(b, in: full, dy: 30)
    }
    if let t = tintedSymbol("trash.fill", pointSize: 210, color: .white) {
        t.draw(in: NSRect(x: size - 330, y: 150, width: t.size.width, height: t.size.height))
    }
}

// Рисует изображение, перевёрнутое по вертикали (ворс кисти смотрит вниз)
func drawFlippedV(_ img: NSImage, in rect: NSRect) {
    NSGraphicsContext.saveGraphicsState()
    let t = NSAffineTransform()
    t.translateX(by: rect.minX, yBy: rect.minY + rect.height)
    t.scaleX(by: 1, yBy: -1)
    t.concat()
    img.draw(in: NSRect(x: 0, y: 0, width: rect.width, height: rect.height))
    NSGraphicsContext.restoreGraphicsState()
}

// MARK: - 9. Светлый: мусорка + кисть по оси над ней (минимализм)
render("concept9.png") {
    let p = squircle(inset)
    light.draw(in: p, angle: -90)
    NSColor.black.withAlphaComponent(0.08).setStroke()
    p.lineWidth = 3
    p.stroke()
    if let t = gradientSymbol("trash.fill", pointSize: 430, gradient: purpleDeep) {
        drawCentered(t, in: full, dy: -90)
    }
    if let b = gradientSymbol("paintbrush.fill", pointSize: 250, gradient: purpleDeep) {
        drawFlippedV(b, in: NSRect(x: (size - b.size.width) / 2 + 90, y: 640,
                                   width: b.size.width, height: b.size.height))
    }
}

// MARK: - 12. Светлый: середина между 9 и 11
render("concept12.png") {
    let p = squircle(inset)
    light.draw(in: p, angle: -90)
    NSColor.black.withAlphaComponent(0.08).setStroke()
    p.lineWidth = 3
    p.stroke()
    if let t = gradientSymbol("trash.fill", pointSize: 455, gradient: purpleDeep) {
        drawCentered(t, in: full, dy: -75)
    }
    if let b = gradientSymbol("paintbrush.fill", pointSize: 235, gradient: purpleDeep) {
        drawFlippedV(b, in: NSRect(x: (size - b.size.width) / 2 + 120, y: 618,
                                   width: b.size.width, height: b.size.height))
    }
}

// MARK: - 11. Светлый: мусорка крупнее, кисть компактно над крышкой
render("concept11.png") {
    let p = squircle(inset)
    light.draw(in: p, angle: -90)
    NSColor.black.withAlphaComponent(0.08).setStroke()
    p.lineWidth = 3
    p.stroke()
    if let t = gradientSymbol("trash.fill", pointSize: 480, gradient: purpleDeep) {
        drawCentered(t, in: full, dy: -60)
    }
    if let b = gradientSymbol("paintbrush.fill", pointSize: 220, gradient: purpleDeep) {
        drawFlippedV(b, in: NSRect(x: (size - b.size.width) / 2 + 150, y: 600,
                                   width: b.size.width, height: b.size.height))
    }
}

// MARK: - 10. Фиолетовый: крупная мусорка + кисть смахивает в неё
render("concept10.png") {
    let p = squircle(inset)
    purpleDeep.draw(in: p, angle: -45)
    gloss(p)
    if let t = tintedSymbol("trash.fill", pointSize: 430, color: .white) {
        drawCentered(t, in: full, dy: -90)
    }
    if let b = tintedSymbol("paintbrush.fill", pointSize: 250, color: .white) {
        drawFlippedV(b, in: NSRect(x: (size - b.size.width) / 2 + 90, y: 640,
                                   width: b.size.width, height: b.size.height))
    }
}

// MARK: - 4. Светлый сквиркл + фиолетовая корзина
render("concept4.png") {
    let p = squircle(inset)
    light.draw(in: p, angle: -90)
    // тонкая внутренняя рамка
    NSColor.black.withAlphaComponent(0.08).setStroke()
    p.lineWidth = 3
    p.stroke()
    if let t = gradientSymbol("trash.fill", pointSize: 430, gradient: purpleDeep) {
        drawCentered(t, in: full)
    }
}
