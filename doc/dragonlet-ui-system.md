# Dragonlet UI System (Pastel Cute Cartoon)

This document defines the target reusable UI contract for Dragochi's Game Life Diary direction.

## 1. Scope and Status

- Goal: establish reusable tokens and components for a companion-style, emotional-safe, cute cartoon visual language.
- Scope: UI system contract only.
- Out of scope: persistence, sync internals, business logic.

Status:

- `In code`: current runtime implementation baseline uses `DragonTheme.neonDark`.
- `Planned`: pastel cute cartoon tokens and copy-forward visual behavior in this document.

Migration note:

- Current `DragonTheme.neonDark` is implementation baseline.
- Pastel system in this document is the target contract.

## 2. Theme Tokens (Target Contract)

### 2.1 Color Tokens

| Token | Value | Usage |
|---|---|---|
| `bg.base` | `#FFF7FB` | app background |
| `bg.softGradientStart` | `#FFF1F8` | atmospheric gradient |
| `bg.softGradientEnd` | `#F4FBFF` | atmospheric gradient |
| `surface.card` | `#FFFFFF` | primary cards/sheets |
| `surface.cardSoft` | `#FFF3FA` | secondary cards |
| `accent.primary` | `#FF7FB8` | primary CTA |
| `accent.secondary` | `#6ECBF5` | supportive highlights |
| `accent.warm` | `#FFB58A` | emotional tags |
| `text.primary` | `#4A3A48` | main text |
| `text.secondary` | `#7C6D7A` | secondary text |
| `text.placeholder` | `#B8AAB7` | input placeholder |
| `border.soft` | `#F0DCE9` | soft outlines |
| `overlay.scrim` | `rgba(74,58,72,0.22)` | modal dim |

### 2.2 Typography Tokens

| Token | Spec |
|---|---|
| `display.timer` | `56 / Bold` |
| `title.section` | `16 / Semibold` |
| `label.small` | `12 / Medium` |
| `body` | `14 / Regular` |
| `cta` | `17 / Semibold` |

Typeface direction:

- Primary: rounded friendly family (for example, `Baloo 2` / `Nunito`).
- Fallback: `SF Pro`.

### 2.3 Radius, Shadow, and Elevation

| Token | Value |
|---|---|
| `radius.bottomSheetTop` | `36` |
| `radius.card` | `24` |
| `radius.avatar` | `9999` |
| `radius.pill` | `9999` |

Effects:

- Gentle shadow for cards (`low blur, low opacity`).
- Primary CTA can use soft glow in `accent.primary`.
- Avoid high-contrast neon outlines in target style.

## 3. Component Catalog

### 3.1 Atomic Components

| Component | Purpose | States |
|---|---|---|
| `DragonSelectableGameCard` | choose game context | `selected`, `unselected`, `add` |
| `DragonPlatformPill` | choose platform | `selected`, `unselected`, `disabled` |
| `DragonTeammateAvatarChip` | choose companions | `selected`, `unselected`, `add` |
| `DragonPrimaryCTAButton` | primary action | `enabled`, `pressed`, `disabled`, `loading` |
| `DragonTextButton` | secondary action | `enabled`, `pressed`, `disabled` |

### 3.2 Composite Components

| Component | Purpose |
|---|---|
| `DragonSessionHero` | moment title + timer + supportive trend message |
| `DragonSectionHeader` | section title + optional action |
| `DragonNotesInput` | emotional/life detail capture |
| `DragonBottomSheetContainer` | session/moment flow container |

## 4. SwiftUI Public Interface Contract

Status: `In code` names and signatures available; visual restyling is `Planned`.

```swift
enum SelectionState { case selected, unselected, add }
enum ControlState { case enabled, pressed, disabled, loading }
enum TrendDirection { case up, down, neutral }

struct GameCardModel: Identifiable, Hashable { id, title, imageURL }
struct TeammateChipModel: Identifiable, Hashable { id, name, avatarURL }
struct PlatformOption: Identifiable, Hashable { id, iconName, title, isEnabled }
struct NotesQuickAction: Identifiable, Hashable { id, iconName }
```

```swift
DragonBottomSheetContainer<Content: View, Footer: View>
DragonSessionHero(title: String, durationText: String, trendText: String, trendDirection: TrendDirection)
DragonSectionHeader(title: String, trailingText: String?, trailingAction: (() -> Void)?)
DragonSelectableGameCard(model: GameCardModel, state: SelectionState, action: () -> Void)
DragonPlatformPill(platform: PlatformOption, isSelected: Bool, action: () -> Void)
DragonTeammateAvatarChip(model: TeammateChipModel, state: SelectionState, action: () -> Void)
DragonNotesInput(text: Binding<String>, placeholder: String, actions: [NotesQuickAction], onAction: ((NotesQuickAction) -> Void)?)
DragonPrimaryCTAButton(title: String, icon: String?, state: ControlState, action: () -> Void)
DragonTextButton(title: String, state: ControlState, action: () -> Void)
```

## 5. State Matrix and Acceptance

- `GameCard`: `selected` / `unselected` / `add`
- `PlatformPill`: `selected` / `unselected` / `disabled`
- `AvatarChip`: `selected` / `unselected` / `add`
- `PrimaryCTA`: `enabled` / `pressed` / `disabled` / `loading`
- `NotesInput`: `idle` / `focused` / `filled`

Implementation checks:

- CTA labels do not truncate on iPhone sizes.
- Dynamic Type up to at least Large keeps layout readable.
- Token updates propagate globally without per-screen hardcoded color edits.

## 6. Do and Don't

Do:

- Use tokenized color/type/radius/spacing through `DragonTheme` contracts.
- Keep surfaces emotionally calm and visually soft.
- Favor companion cues over competitive visual emphasis.

Don't:

- Hardcode neon/high-contrast colors into feature screens.
- Introduce duplicate button primitives with overlapping semantics.
- Ship target-style claims without status labels when runtime still differs.

## 7. File References

- UI system contract: `/Users/ericho/iosHub/Dragochi/doc/dragonlet-ui-system.md`
- Current theme baseline:
  - `/Users/ericho/iosHub/Dragochi/Dragochi/Theme/DragonTheme.swift`
  - `/Users/ericho/iosHub/Dragochi/Dragochi/Theme/DragonColor.swift`
  - `/Users/ericho/iosHub/Dragochi/Dragochi/Theme/DragonTypography.swift`
  - `/Users/ericho/iosHub/Dragochi/Dragochi/Theme/DragonRadius.swift`
  - `/Users/ericho/iosHub/Dragochi/Dragochi/Theme/DragonSpacing.swift`
- Components:
  - `/Users/ericho/iosHub/Dragochi/Dragochi/DesignSystem/`
  - `/Users/ericho/iosHub/Dragochi/Dragochi/DesignSystem/DragonComponentPreviews.swift`
