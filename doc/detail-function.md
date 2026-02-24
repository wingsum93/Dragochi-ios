# Dragochi Detailed Functional Spec (Game Life Diary MVP)

## 1. Goal and Scope

Dragochi's MVP goal is to deliver a usable **Game Life Diary** that blends session context with emotional logging. The product is female-first but inclusive, and focuses on companion-style reflection rather than productivity pressure.

This document is a vision-first implementation contract with status tags.

- `In code`: available in current runtime behavior.
- `Planned`: target direction not fully shipped.

## 2. Core Product Loop

### 2.1 Capture moment (`In code`)

- Start/stop session quickly from Home.
- Preserve basic session context:
  - `startTime`
  - `endTime`
  - `duration`
  - `platform`
  - `game`
  - `friends`
- Keep low friction and support quick continuation behavior.

### 2.2 Record mood + context (`In code` + `Planned`)

- `In code`:
  - Session completion flow supports notes input.
  - Session metadata can be edited through existing screens.
- `Planned`:
  - Mood-first fields and clearer emotional prompts.
  - Companion-style check-in copy replacing grind-oriented wording.
  - Structured emotional tags to improve reflection quality.

### 2.3 Reflect with companion cues (`Planned`)

- Gentle reflective prompts after sessions and at day-end.
- Emotional summaries connected to play context.
- Supportive, non-judgmental insight tone.

## 3. Feature Semantics (Renamed)

### 3.1 Gentle Session Start/Stop (formerly Quick Track)

Status: `In code`

- Single primary action to start or stop a session.
- Session setup includes game, platform, teammates, and optional notes.
- Resume-last-setup behavior is available and should remain low friction.

### 3.2 Life Diary Timeline (formerly History)

Status: `In code`

- List/calendar-style session history for review.
- Per-session details can be corrected.
- Timeline is the base surface for memory recall.

### 3.3 Emotional + Play Pattern Summary (formerly Monthly Report)

Status: `In code` + `Planned`

- `In code`:
  - Monthly total playtime.
  - Game/platform breakdown.
  - Month-to-month metrics and trend basics.
- `Planned`:
  - Emotional overlays and reflection summaries.
  - Companion phrasing and mood-aware interpretation.

## 4. Metrics Contract (Technical + Product Meaning)

- Monthly total duration:
  - `sum(durationSeconds)` grouped by session end month.
- Breakdown dimensions:
  - game
  - platform
- MoM change:
  - `((currentMonthTotal - previousMonthTotal) / previousMonthTotal) * 100%`
  - If previous month is 0, display product-defined non-error output.
- Trend window:
  - last 6 months duration trend.
- Teammate signals:
  - frequency by shared sessions or shared duration.
  - rare teammates via recent-window rule.

Product interpretation rule:

- Duration metrics are **context**, not judgment.
- Emotional reflection language must avoid pressure framing.

## 5. Data Model (Documentation Contract)

Status: `In code` foundation, `Planned` emotional extensions

### 5.1 Session

- `id`
- `startAt`
- `endAt`
- `durationSeconds`
- `platform`
- `gameId` (optional)
- `note` (optional)

### 5.2 Friend

- `id`
- `name`
- `handle` (optional)

### 5.3 Game

- `id`
- `name`
- `icon` (optional)

### 5.4 SessionFriend

- many-to-many association between `Session` and `Friend`

### 5.5 Platform enum

- `mobile`
- `pc`
- `console`

### 5.6 Planned emotional model additions

- Mood tag set per session/day
- Reflection prompt response fields
- Optional companion-note metadata

## 6. Sync and Storage Strategy

Status: `In code` baseline + `Planned` cloud depth

- `In code`:
  - Local-first storage path.
  - Existing data flow supports current session/history/stats behavior.
- `Planned`:
  - Clear iCloud sync contract rollout and conflict-handling hardening.
  - Additional validation for emotional metadata sync quality.

## 7. Risk and UX Safeguards

Status: `In code` + `Planned`

- `In code` baseline:
  - Existing session handling and edit surfaces reduce data loss risk.
- `Planned` safeguards:
  - Long-running session reminder confirmation.
  - App-reopen recovery choices for interrupted running sessions.
  - Emotional safety copy checks to avoid guilt or pressure language.

## 8. Public Interfaces / Type Changes

This round introduces **documentation contract changes only**.

- Product terminology shift:
  - `time tracking` -> `game life diary`
  - `productivity mode` -> `companion journaling mode` (target)
- No runtime Swift API/type signature changes in this documentation task.

## 9. Implementation Status Snapshot

- Gentle Session Start/Stop: `In code`
- Life Diary Timeline: `In code`
- Emotional + Play Pattern Summary:
  - quantitative metrics: `In code`
  - emotional companion overlays: `Planned`
- Emotional logging prompts and structured mood loop: `Planned`
- Pastel-cute full visual refresh: `Planned`

## 10. Doc Acceptance Criteria

- Document clearly states what is in code vs planned.
- Product framing is consistently "Game Life Diary" and emotional-logger-oriented.
- Technical metrics/data contracts remain accurate and implementable.
- Wording avoids productivity/grind-default tone.
