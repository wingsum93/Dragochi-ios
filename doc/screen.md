# Dragochi Screen Map (Vision-first)

This document maps user-facing screens with target diary voice while preserving current in-code labels for implementation clarity.

Status tags:

- `In code`: currently shown in runtime.
- `Planned`: target copy/style not yet fully shipped.
- `In transition`: both exist (target direction documented, runtime still older wording).

## Main App Tabs

Root uses a `TabView` with 4 tabs.

- Home
- History
- Stats
- Settings

Status: `In code`
Source: `Dragochi/AppRootView.swift`

## Home Screen (`MainView`)

### Target copy (vision)

- "Moment Capture"
- "Companion Journaling Mode"
- Status text:
  - "Ready for a gentle check-in"
  - "You're in this moment"
- Resume card language:
  - "Continue your last vibe setup"
- Main CTA:
  - "Start Moment"
  - "Finish Moment"

### Current in-code copy

- "Quick Track"
- "PRODUCTIVITY MODE"
- Status text:
  - "READY TO GRIND" (idle)
  - "KEEP GOING" (running)
- Resume card:
  - "RESUME LAST SETUP"
- Main CTA:
  - "START"
  - "STOP"

Status: `In transition`
Source: `Dragochi/Features/Main/MainView.swift`

## History Screen (`HistoryView`)

### Target copy (vision)

- "Life Diary Timeline"
- Filter chips:
  - "All Moments"
  - "This Week"
  - "Last Month"
- Header summary:
  - "Total Recorded Moments"

### Current in-code copy

- "History"
- Filter chips:
  - "All Time"
  - "This Week"
  - "Last Month"
- Header summary:
  - "TOTAL PLAYTIME: ..."

Status: `In transition`
Sources:

- `Dragochi/Features/History/HistoryView.swift`
- `Dragochi/Features/History/HistoryStore.swift`

## Stats Screen (`StatisticView`)

### Target copy (vision)

- "Reflection"
- "Monthly Emotional + Play Pattern"
- "Platform Story"

### Current in-code copy

- "Stats"
- "Total Playtime"
- "MoM: ..."
- "Platform Breakdown"

Status: `In transition`
Source: `Dragochi/Features/Stats/StatisticView.swift`

## Settings Screen (`SettingsView`)

### Target copy (vision)

- "Settings"
- "Sync & Memory Safety"
- "Diary Backup"
- Action labels remain direct and clear.

### Current in-code copy

- "Settings"
- "iCloud Sync"
- "Sync across devices (local-only toggle for now)."
- "Backup"
- Actions:
  - "Export" / "Exporting..."
  - "Import" / "Importing..."

Status: `In transition`
Source: `Dragochi/Features/Settings/SettingsView.swift`

## Add Session Sheet (`AddSessionView`)

### Target copy (vision)

- Title:
  - "Moment Complete"
  - "Session Setup" (pre-start)
- Section labels:
  - "Game"
  - "Platform"
  - "Companions"
  - "How did this moment feel?"
- Notes placeholder:
  - "Capture highlights, feelings, or tiny memories..."
- Footer actions:
  - "Save Moment"
  - "Discard"

### Current in-code copy

- Title:
  - "Session Complete"
  - "Session Setup"
- Section labels:
  - "Game Played"
  - "Platform"
  - "Teammates"
  - "Session Notes"
- Notes placeholder:
  - "Rank change, highlights, or mood..."
- Footer actions:
  - "Save Session"
  - "Discard Entry"

Status: `In transition`
Source: `Dragochi/Features/AddSession/AddSessionView.swift`

## Copy Alignment Rules

- Avoid productivity-grind wording in target copy.
- Keep current in-code strings documented until runtime migration lands.
- When target and runtime differ, always show both with explicit status.
