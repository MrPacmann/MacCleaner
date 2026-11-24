#!/usr/bin/env python3
"""Генерирует фон окна DMG: мягкий светлый градиент + фиолетовая стрелка
от иконки приложения к Applications. Выход: background.tiff (1x + 2x, Retina)."""

from PIL import Image, ImageDraw, ImageFilter

W, H = 580, 360          # размер окна в точках
SCALE = 2                 # рендерим сразу в 2x, потом даунскейлим для 1x

def lerp(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

def make(scale):
    w, h = W * scale, H * scale
    # --- фон: тонкий вертикальный градиент в стиле macOS ---
    top, bottom = (247, 247, 250), (234, 234, 240)
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        c = lerp(top, bottom, y / (h - 1))
        for x in range(w):
            px[x, y] = c

    # --- форма стрелки (маска) ---
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    # координаты в пикселях текущего масштаба
    ax0 = int(245 * scale)
    ax1 = int(338 * scale)
    ay = int(172 * scale)
    thick = int(11 * scale)
    r = thick // 2
    head_len = int(28 * scale)
    head_half = int(21 * scale)
    shaft_end = ax1 - head_len
    # линия со скруглёнными концами
    d.line([ax0, ay, shaft_end, ay], fill=255, width=thick)
    d.ellipse([ax0 - r, ay - r, ax0 + r, ay + r], fill=255)
    d.ellipse([shaft_end - r, ay - r, shaft_end + r, ay + r], fill=255)
    # наконечник
    d.polygon([(shaft_end, ay - head_half), (shaft_end, ay + head_half), (ax1, ay)], fill=255)

    # --- тень ---
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sh_mask = mask.filter(ImageFilter.GaussianBlur(5 * scale))
    shadow_layer = Image.new("RGBA", (w, h), (60, 50, 90, 70))
    shadow.paste(shadow_layer, (0, int(3 * scale)), sh_mask)
    img = Image.alpha_composite(img.convert("RGBA"), shadow)

    # --- сама стрелка: горизонтальный фиолетовый градиент ---
    grad = Image.new("RGB", (w, h))
    gp = grad.load()
    c_left, c_right = (167, 139, 250), (124, 58, 237)  # #A78BFA -> #7C3AED
    for x in range(ax0 - r, ax1 + 1):
        t = (x - ax0) / max(1, (ax1 - ax0))
        c = lerp(c_left, c_right, t)
        for yy in range(ay - head_half - 2, ay + head_half + 3):
            if 0 <= yy < h:
                gp[x, yy] = c
    img.paste(grad, (0, 0), mask)

    return img.convert("RGB")

img2x = make(2)
img1x = img2x.resize((W, H), Image.LANCZOS)

img2x.save("background_2x.png")
img1x.save("background_1x.png")
print("ok")
