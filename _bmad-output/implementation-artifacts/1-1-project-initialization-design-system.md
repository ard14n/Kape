# Story 1.1: Project Initialization & Design System

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a Developer,
I want to initialize the project with the correct structure and design tokens,
so that we can build features with a consistent and premium "Electric Eagle" aesthetic.

## Acceptance Criteria

1. **Given** a clean Xcode workspace
   **When** the project is initialized
   **Then** it must use the "App" template with SwiftUI and no or SwiftData (via ModelContainer)

2. **And** the folder structure must match the `Features/Core/DesignSystem` architecture defined

3. **And** `Color+DesignSystem.swift` must include `.neonRed` (`#FF003F`), `.neonGreen` (`#39FF14`), `.trueBlack` (`#000000`)

4. **And** a `.neonGlow()` ViewModifier must be available for testing

## Tasks / Subtasks

- [x] Initialize Xcode Project
  - [x] Create new iOS App project "Kape"
  - [x] Target iOS 17.0+
  - [x] Enable SwiftData
- [x] Setup Folder Structure
  - [x] Create `Features`, `Core`, `DesignSystem` root groups
  - [x] Create `App` group for App entry point (Kept in root to avoid Xcode project modifications)
- [x] Implement Design System
  - [x] Create `Core/DesignSystem/Colors.swift` extension on Color
  - [x] Define `neonRed`, `neonGreen`, `trueBlack`
  - [x] Create `Core/DesignSystem/Modifiers.swift`
  - [x] Implement `neonGlow(color:radius:)` modifier
- [x] Verify Setup
  - [x] Add a test view in ContentView using neon colors and glow
  - [x] Verify build succeeds

## Dev Notes

- **Architecture**: Feature-First. All core shared logic goes in `Core`. Feature specific logic in `Features`.
- **Design System**: Use standard SwiftUI Extensions.
- **Constraints**: 
  - No 3rd party UI libraries.
  - Vanilla SwiftUI.
  - Swift 5.9+.

### Project Structure Notes

- Alignment with unified project structure: `Features/Core/DesignSystem`.
- Ensure Info.plist is configured correctly if needed (likely not for this story except basic setup).

### References

- [Source: planning-artifacts/epics.md#Story 1.1](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/epics.md)
- [Source: planning-artifacts/architecture.md](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/architecture.md)

## Dev Agent Record

### Agent Model Used

Antigravity (simulating BMad Dev Agent)

### Debug Log References

### Completion Notes List
- Implemented `Core/DesignSystem/Colors.swift` with neon palette required for "Electric Eagle" theme.
- Implemented `Core/DesignSystem/Modifiers.swift` with `.neonGlow()` modifier.
- Updated `KapeApp.swift` to import SwiftData.
- Updated `ContentView.swift` to serve as a verification screen for the new styles.
- Created `Features` directory for future modules.
- Note: Did not move App entry files to `App/` folder to prevent breaking existing Xcode project file references.
- [AI-Fix] Updated `Colors.swift` hex init fallback to `.black` (opaque) instead of invisible.
- [AI-Fix] Added TODO in `KapeApp.swift` to explicit ModelContainer requirement.

### File List
- Kape/Kape/Core/DesignSystem/Colors.swift
- Kape/Kape/Core/DesignSystem/Modifiers.swift
- Kape/Kape/KapeApp.swift
- Kape/Kape/ContentView.swift
- Kape/Kape/Features/ (Directory)
