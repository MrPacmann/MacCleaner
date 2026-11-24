import AppKit

// Тонирует SF Symbol в отдельном буфере, чтобы заливка не выходила за контур глифа.
func tintedSymbol(_ name: String, pointSize: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSImage? {
    guard let sym = NSImage(systemSymbolName: name, accessibilityDescription: nil),
          let conf = sym.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight))
    else { return nil }
    let size = conf.size
    let out = NSImage(size: size)
    out.lockFocus()
    conf.draw(in: NSRect(origin: .zero, size: size))
    color.set()
    NSRect(origin: .zero, size: size).fill(using: .sourceIn)
    out.unlockFocus()
    return out
}

let S: CGFloat = 1024
let img = NSImage(size: NSSize(width: S, height: S))
img.lockFocus()

// Фон — тёмный squircle с лёгким градиентом
let inset: CGFloat = 56
let rect = NSRect(x: inset, y: inset, width: S - inset * 2, height: S - inset * 2)
let squircle = NSBezierPath(roundedRect: rect, xRadius: 216, yRadius: 216)
let top = NSColor(calibratedRed: 0.13, green: 0.13, blue: 0.17, alpha: 1)
let bottom = NSColor(calibratedRed: 0.07, green: 0.07, blue: 0.10, alpha: 1)
NSGradient(colors: [top, bottom])!.draw(in: squircle, angle: -90)

// Тонкая светлая кромка
NSColor(white: 1, alpha: 0.08).setStroke()
squircle.lineWidth = 4
squircle.stroke()

// Корзина — янтарная
let amber = NSColor(calibratedRed: 0.91, green: 0.64, blue: 0.24, alpha: 1)
if let trash = tintedSymbol("trash.fill", pointSize: 430, weight: .medium, color: amber) {
    let ts = trash.size
    trash.draw(in: NSRect(x: (S - ts.width) / 2, y: (S - ts.height) / 2 - 24, width: ts.width, height: ts.height))
}

// Искра — светлая, справа сверху
if let spark = tintedSymbol("sparkle", pointSize: 130, weight: .bold,
                            color: NSColor(calibratedRed: 0.98, green: 0.85, blue: 0.55, alpha: 1)) {
    let ss = spark.size
    spark.draw(in: NSRect(x: S * 0.665, y: S * 0.665, width: ss.width, height: ss.height))
}

img.unlockFocus()

if let tiff = img.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png"
    try? png.write(to: URL(fileURLWithPath: out))
    print("saved \(out)")
} else {
    print("failed")
}
