# Dragochi Screen Map

This document lists all user-facing screens and major row/section labels to help new developers navigate the app UI quickly.

## Main App Tabs

The app root uses a `TabView` with 4 tabs:

1. **Home**
2. **History**
3. **Stats**
4. **Settings**

Source: `Dragochi/AppRootView.swift`

---

## Home Screen (`MainView`)

Primary labels and sections:

- **Quick Track**
- **PRODUCTIVITY MODE**
- Timer status text:
  - **KEEP GOING** (running)
  - **READY TO GRIND** (idle)
- **RESUME LAST SETUP**
- Main CTA text:
  - **START**
  - **STOP**

Dynamic row/chip values:

- Selected game name (if available)
- Selected platform (uppercased)

Source: `Dragochi/Features/Main/MainView.swift`

---

## History Screen (`HistoryView`)

Primary labels and sections:

- **History**
- Filter chips:
  - **All Time**
  - **This Week**
  - **Last Month**
- **TOTAL PLAYTIME: ...**
- Dynamic section headers by date (`section.title.uppercased()`)

Row content per history item:

- `gameTitle`
- `subtitle` (platform)
- `durationText`
- `timeText`

Sources:

- `Dragochi/Features/History/HistoryView.swift`
- `Dragochi/Features/History/HistoryStore.swift` (filter labels)

---

## Stats Screen (`StatsView`)

Primary labels and sections:

- **Stats**
- **Total Playtime**
- **MoM: ...** (shown when report data exists)
- **Platform Breakdown**

Dynamic row content:

- Platform labels from `item.platform.rawValue.uppercased()`
- Duration per platform

Source: `Dragochi/Features/Stats/StatsView.swift`

---

## Settings Screen (`SettingsView`)

Primary labels and sections:

- **Settings**
- **iCloud Sync**
- **Sync across devices (local-only toggle for now).**
- **Backup**
- Backup status text:
  - **Last export: ...**
  - **No backup created yet.**
- Action buttons:
  - **Export** / **Exporting...**
  - **Import** / **Importing...**

Source: `Dragochi/Features/Settings/SettingsView.swift`

---

## Add Session Sheet (`AddSessionView`)

This is a presented sheet (not a tab), but includes important UI sections:

- **Session Complete**
- **Game Played** (trailing: **See all**)
- **Platform**
- **Teammates** (trailing dynamic: `N selected`)
- **Session Notes**
- Notes placeholder: **Rank change, highlights, or mood...**
- Footer actions:
  - **Save Session**
  - **Discard Entry**

Dynamic/option labels:

- Platform options: **PC**, **Console**, **Mobile**
- Includes teammate chip labeled **Add**

Source: `Dragochi/Features/AddSession/AddSessionView.swift`
