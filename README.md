# Dragochi - Your Game Life Diary

Dragochi is repositioning from a game time tracker to a companion-style **Game Life Diary / 遊戲生活日記**. It helps users capture feelings, game moments, and daily memories in one gentle flow.

## Product Positioning

Dragochi is designed for emotional logging with game context:

- Record how you felt before, during, and after play.
- Keep small daily memories, not only performance metrics.
- Build a sense of companionship through reflective prompts and supportive tone.

## Audience

**Female-first, inclusive of all emotional loggers.**

Primary audience focus:

- Users who love aesthetic experiences.
- Users who enjoy recording life details.
- Users who share daily life moments in IG Story style.
- Users who want an app that feels emotionally companionable, not judgmental.

## Product Pillars

- **Mood-first journaling**
- **Session-assisted memory capture**
- **Companion reflection**
- **Aesthetic daily storytelling**

## Current Build Reality

This documentation is vision-first and uses status tags to clarify reality.

### In code

- Session tracking flow (start/stop, elapsed timer, setup context)
- History view and session editing foundation
- Stats view and monthly playtime summaries
- Settings and backup/export/import surfaces
- Screenshot test baseline workflow

### Planned

- Deeper emotional companion loops (reflection prompts, supportive summaries)
- Full pastel-cute visual refresh replacing current neon-dark implementation theme
- Expanded diary-first copy across all runtime screens

## Documentation Map

- Detailed functional specification: [doc/detail-function.md](doc/detail-function.md)
- Target audience and writing guardrails: [doc/target-audience.md](doc/target-audience.md)
- Vision-first screen map and copy alignment: [doc/screen.md](doc/screen.md)
- Pastel cute cartoon design contract: [doc/dragonlet-ui-system.md](doc/dragonlet-ui-system.md)
- Remote config technical runbook: [doc/get-remote-config.md](doc/get-remote-config.md)
- Screenshot baseline notes: [screenshots/README.md](screenshots/README.md)

## Terminology Contract (Documentation)

- `time tracking` -> `game life diary`
- `productivity mode` -> `companion journaling mode` (target wording)

## Release Bundle Identifier

- Release bundle ID: `com.ericho.Dragochi` (App Store / TestFlight)
- Debug bundle ID: `com.ericho.dragochi.dev` (local development)
- Case-only bundle ID changes are not a valid App Store app identity migration path.

## UI Screenshot Export Workflow

`ScreenshotUITests` stores screenshot artifacts as XCTest attachments (`home.png`, `home_start.png`, `history.png`, `stats.png`, `settings.png`, `add-session.png`, `friend-settings-no-friend.png`, `friend-settings-one-friend.png`, `friend-settings-many-friends.png`).

Run UI tests with a deterministic simulator destination and keep the result bundle:

```bash
xcodebuild test \
  -scheme Dragochi \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -maximum-concurrent-test-simulator-destinations 1 \
  -resultBundlePath build/ScreenshotUITests.xcresult
```

Export attachment PNG files into the tracked baseline folder (`/Users/ericho/iosHub/Dragochi/screenshots` by default):

```bash
scripts/export_ui_screenshots.sh build/ScreenshotUITests.xcresult
```

You can also provide a custom output path as the second argument.
