# Agent Guidelines

## Project Architecture

- Use MVI architecture.
- Small SwiftUI views should not use a ViewModel; expose UI events with lambda/closure callbacks instead.
- Small SwiftUI views should include a preview.

## Data Layer

- Use SwiftData.

## Naming Rules

- Use `ViewModel` suffix for all V in MVI architecture.
- Use `Sheet` suffix for UI used in SwiftUI sheets.
- Use `FullPage` suffix for SwiftUI full-screen covers.
- Use singular names for all classes.
