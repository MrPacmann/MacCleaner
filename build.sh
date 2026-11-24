#!/bin/bash
# Сборка «Чистка Mac» в нативный .app без Xcode — только Command Line Tools.
set -euo pipefail
cd "$(dirname "$0")"

APP="build/MacCleaner.app"
BINARY="$APP/Contents/MacOS/MacCleaner"

rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "→ Компилирую SwiftUI-приложение…"
swiftc -O -parse-as-library \
  -target arm64-apple-macosx14.0 \
  -o "$BINARY" \
  Sources/*.swift

cp Info.plist "$APP/Contents/Info.plist"

# Иконка, если сгенерирована
if [ -f Resources/AppIcon.icns ]; then
  cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
fi

echo "→ Подписываю (ad-hoc, для локального запуска)…"
xattr -cr "$APP"
codesign --force --sign - "$APP"

echo "✓ Готово: $APP"
echo "  Запуск: open \"$APP\""
