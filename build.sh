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

echo "→ Подписываю…"
xattr -cr "$APP"
# Finder/iCloud любят оставлять на бандле com.apple.FinderInfo —
# codesign его не переваривает. Снимаем и пробуем до 5 раз.
sign_with_retry() {
  local identity="$1"
  for i in 1 2 3 4 5; do
    xattr -d com.apple.FinderInfo "$APP" 2>/dev/null || true
    if codesign --force --sign "$identity" "$APP" 2>/dev/null; then
      return 0
    fi
    sleep 0.3
  done
  return 1
}
if security find-identity -v -p codesigning | grep -q "MacCleaner Dev"; then
  # Стабильная локальная подпись: macOS (TCC) запоминает выданные
  # разрешения между сборками и обновлениями.
  if ! sign_with_retry "MacCleaner Dev"; then
    echo "⚠️  FinderInfo не даёт подписать — закрой папку build в Finder и повтори"
    exit 1
  fi
else
  # Запасной вариант: ad-hoc (разрешения будут переспрашивать после каждой сборки)
  codesign --force --sign - "$APP"
fi

echo "✓ Готово: $APP"
echo "  Запуск: open \"$APP\""
