# Dragonlet UI System（Neon Dark）

本文件定義 Dragonlet 可重用 UI 設計契約，基準來源為 Figma `Dragonlet-draft` node `2001:111`（Session Details Summary）。

## 1. Scope

- 目標：建立可重用 component + token 系統，供後續頁面直接組裝。
- 此文件聚焦 UI 層，不包含資料持久化、商業邏輯、同步流程。
- 主題固定為單一 `Neon Dark`（本期不做 light/dark 雙軌）。

## 2. Theme Tokens

### 2.1 Color Tokens

| Token | Value |
|---|---|
| `bg.base` | `#102216` |
| `surface.card` | `#152E1E` |
| `accent.primary` | `#13EC5B` |
| `accent.primaryDim` | `rgba(19,236,91,0.20)` |
| `accent.primarySoft` | `rgba(19,236,91,0.10)` |
| `text.primary` | `rgba(255,255,255,0.90)` |
| `text.secondary` | `rgba(255,255,255,0.60)` |
| `text.tertiary` | `rgba(255,255,255,0.40)` |
| `text.placeholder` | `rgba(255,255,255,0.20)` |
| `border.soft` | `rgba(255,255,255,0.10)` |
| `border.neon` | `rgba(19,236,91,0.20)` |
| `overlay.scrim` | `rgba(16,34,22,0.80)` |

### 2.2 Typography Tokens

| Token | Spec |
|---|---|
| `display.timer` | `60 / Bold` |
| `title.section` | `14 / Semibold` |
| `label.small` | `12 / Medium` |
| `body` | `14 / Regular` |
| `cta` | `18 / Bold` |

字體族：`Be Vietnam Pro`。  
fallback：`SF Pro`（當自訂字體未打包）。

### 2.3 Radius and Effects

| Token | Value |
|---|---|
| `radius.bottomSheetTop` | `48` |
| `radius.card` | `32` |
| `radius.avatar` | `9999` |
| `radius.pill` | `9999` |

特效規範：

- Selected card / primary CTA 使用 accent glow。
- 背景模糊：`2`。
- Bottom sheet 玻璃感 blur：`6`（視系統材質可微調）。

## 3. Component Catalog

### 3.1 Atomic

| Component | Purpose | States |
|---|---|---|
| `DragonSelectableGameCard` | Game 選擇卡 | `selected`, `unselected`, `add` |
| `DragonPlatformPill` | Platform 切換 pill | `selected`, `unselected`, `disabled` |
| `DragonTeammateAvatarChip` | Teammate 頭像 chip | `selected`, `unselected`, `add` |
| `DragonPrimaryCTAButton` | 主要 CTA（Save Session） | `enabled`, `pressed`, `disabled`, `loading` |
| `DragonTextButton` | 次要文字按鈕（Discard Entry） | `enabled`, `pressed`, `disabled` |

### 3.2 Composite

| Component | Purpose |
|---|---|
| `DragonSessionHero` | Session 標題 + Timer + Trend badge |
| `DragonSectionHeader` | 區塊標題 + trailing text/action |
| `DragonNotesInput` | 多行 notes 輸入 + quick actions |
| `DragonBottomSheetContainer` | Session Summary 整體容器（含 drag handle + sticky footer） |

## 4. SwiftUI Public Interfaces

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

## 5. Figma to Code Mapping

### 5.1 Figma Component Names

- `Dragon/BottomSheet`
- `Dragon/GameCard`
- `Dragon/PlatformPill`
- `Dragon/AvatarChip`
- `Dragon/Button/Primary`
- `Dragon/Button/Text`

### 5.2 Figma Variables

- `color/bg/base`
- `color/accent/primary`
- `text/primary`
- `radius/card/32`
- `space/24`

規則：

- Figma variant 名稱與 Swift enum case 一一對應。
- 若需新增 UI state，先加 enum case，再補 Figma variant。

## 6. State Matrix（驗收）

- `GameCard`: `selected` / `unselected` / `add`
- `PlatformPill`: `selected` / `unselected` / `disabled`
- `AvatarChip`: `selected` / `unselected` / `add`
- `PrimaryCTA`: `enabled` / `pressed` / `disabled` / `loading`
- `NotesInput`: `idle` / `focused` / `filled`

實作檢查點：

- 小螢幕（iPhone）CTA 不截斷。
- Dynamic Type 至少 Large 不破版。
- token 調整可全域生效，不需逐元件改色值。

## 7. Do / Don’t

Do:

- 只用 `DragonTheme` token 取色、字級、圓角、間距。
- 新畫面優先由既有 component 組合。
- 新增元件前先檢查是否能以 `SectionHeader + Atomic` 拼裝。

Don’t:

- 不直接 hardcode 新色、字級、shadow 到業務頁。
- 不建立語義重複的按鈕元件（例如另一個 PrimaryButton）。
- 不在未更新 token 契約下私自改動設計語言。

## 8. File References

- UI system contract: `/Users/ericho/iosHub/Dragochi/doc/dragonlet-ui-system.md`
- Theme tokens: `/Users/ericho/iosHub/Dragochi/Dragochi/DesignSystem/DragonTokens.swift`
- Components: `/Users/ericho/iosHub/Dragochi/Dragochi/DesignSystem/DragonComponents.swift`
- State previews: `/Users/ericho/iosHub/Dragochi/Dragochi/DesignSystem/DragonComponentPreviews.swift`

