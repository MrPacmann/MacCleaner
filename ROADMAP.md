# 🗺️ Roadmap — Mac Cleaner

**English** · [Русский](ROADMAP.ru.md)

> Items may be reordered, appear and disappear.
> Legend: 🔥 next release · 🕐 someday · 💡 idea · ❄️ frozen

## ✅ Recently shipped

**v1.8**
- Statistics in Overview: total space freed + weekly chart
- Smart suggestions: developer caches, long-unused apps, orphans, low disk space warning
- Incremental scanning — only changed folders are rescanned
- Menu bar battery savings (animation adapts to CPU load)
- Xcode: simulators & DeviceSupport; package managers: Maven, SwiftPM, Cargo, Go
- Orphans: Containers, Group Containers, Application Scripts, LaunchAgents

**v1.6–1.7**
- Scan optimizations (custom du, lazy lists, scan cache)
- Public IP + country flag (spot an active VPN)
- Long-unused apps, Auto theme, right-click file actions

## 🔥 Up Next

- [ ] **Homebrew tap** — `brew install --cask mrpacmann/maccleaner/maccleaner`
      Own tap repository + automatic sha256 update on release.
      Trigger: first external users.
- [ ] **Scheduled auto-cleanup** — weekly/monthly cleanup of safe categories
      (caches, logs, Trash) with a "freed N GB" notification.
- [ ] **Low disk space alert** — the menu bar watches and warns
      with a "Clean up" button.

## 🕐 Someday

- [ ] **Quick Look with Space bar** in file lists
- [ ] **Scan report export** (CSV/PDF)
- [ ] **"What grew" over a period** — week / month picker, not just "since last scan"
- [ ] **Allowlist** of folders never suggested for deletion
- [ ] **Lazy folder sizing** in Heavy Folders — size only visible rows
- [ ] **One-click safe cleanup** — a button in Overview for zero-risk categories

## 💡 Ideas (to think over)

- **Similar photos** — perceptual hash (dHash), visually alike, not exact copies.

## ❄️ Frozen (with reason)

- **WidgetKit desktop widget** — tried during the 1.8 cycle, didn't fly:
  the system requires a sandboxed extension with a real Apple Team ID, and on
  macOS 26 widgets don't register when the host app isn't sandboxed
  (confirmed limitation). A sandbox is incompatible with a cleaner —
  it needs to delete files all over the disk. Revisit if Apple's policy changes.
- **Developer ID + notarization** — requires a paid Apple Developer account ($99/year).
  Would remove the Gatekeeper warning on install.
- **Official homebrew-cask** — needs ~30⭐ on GitHub.

---

*Updated: 2026-11-27*
