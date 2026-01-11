# Story 1.2: Core Motion Service

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a Player,
I want my head movements to be detected accurately as game inputs,
so that I can play the game without looking at the screen or touching buttons.

## Acceptance Criteria

1. **Given** the `MotionManager` service
   **When** the device is tilted down (Pitch < -35 degrees)
   **Then** it must emit a `.correct` event
   **And** it must lock input (Debounce) until the device returns to Neutral (-10 to 10 degrees)

2. **Given** the `MotionManager` service
   **When** the device is tilted up (Pitch > 35 degrees)
   **Then** it must trigger a `.pass` event
   **And** it must lock input until return to Neutral

3. **Given** permission is denied or restricted
   **When** the service starts
   **Then** it must report a `.permissionDenied` error state (via AsyncStream or Observable state)

4. **Given** `Info.plist`
   **When** the app is built
   **Then** it must contain `NSMotionUsageDescription` key with a user-facing explanation

## Tasks / Subtasks

- [x] Configure Permissions
  - [x] Add `NSMotionUsageDescription` to Project Build Settings (Migrated from Info.plist to resolve build collision)
  - [x] Add `MotionUsageDescription` string: "Kape uses your movement to detect correct answers and passes."
- [x] Implement `Core/Motion/MotionManager.swift`
  - [x] Create `MotionManager` class (Singleton/Actor) adhering to `@Observable` (or publishing updates)
  - [x] Implement `startMonitoring()` and `stopMonitoring()`
  - [x] Implement `CMMotionManager` integration (DeviceMotion)
  - [x] Implement Pitch calculation logic
- [x] Implement Input Logic & Debounce
  - [x] Define Threshold Constants (`-35` and `35` degrees)
  - [x] Define Neutral Zone (`-10` to `10`)
  - [x] Implement State Machine: `neutral` -> `triggered` -> `waitingForNeutral` -> `neutral`
  - [x] Expose `AsyncStream<GameInputEvent>` or similar public stream
- [x] Create Debug/Test View
  - [x] Create a temporary view to visualize Pitch and State (e.g., Text showing Angle and State color) for verification

## Dev Notes

- **Architecture Compliance**:
  - **Location**: `Core/Motion/MotionManager.swift`.
  - **Pattern**: Manager should manage its own `CMMotionManager` instance.
  - **Thread Safety**: Ensure updates are published on `MainActor` if driving UI, or handle concurrency correctly.
  - **Performance**: Use appropriate update interval (e.g., `1.0/60.0` for 60Hz).

- **Technical Specifics**:
  - Use `CMDeviceMotion` -> `attitude` -> `pitch`.
  - Check `isDeviceMotionAvailable` before specific calls.
  - **Debounce**: This is CRITICAL. The system must NOT emit multiple `.correct` events for one nod. It must wait for the head to come back up.

- **Dependencies**:
  - `CoreMotion` framework.
  - No 3rd party wrappers.

### Project Structure Notes

- New File: `Core/Motion/MotionManager.swift`
- Update: `Info.plist` (in `App/` or root `Kape/`) via Project Settings or direct plist edit.

### References

- [Source: epics.md#Story 1.2](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/epics.md)
- [Source: prd.md#FR2, FR3, FR4](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/prd.md)
- [Source: architecture.md#Core Architectural Decisions](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/architecture.md)
- [Source: ux-design-specification.md#2.5 Experience Mechanics](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/ux-design-specification.md)

## Dev Agent Record

### Agent Model Used

Antigravity (simulating BMad Scrum Master)

### Debug Log References

### Completion Notes List
- Implemented `Core/Motion/MotionManager.swift` using `CMDeviceMotion` monitoring **Roll** (Rotation around Y-axis) for Landscape orientation support.
- Added strict Debounce state machine to prevent rapid firing of events.
- Created `Features/Debug/MotionDebugView.swift` for manual verification of thresholds and state transitions.
- Added `NSMotionUsageDescription` to `Info.plist`.
- **Engineering Decision**: Switched from Pitch to Roll based on corrected physics for landscape orientation.

### File List
- Kape/Kape/Kape/Core/Motion/MotionManager.swift
- Kape/Kape/Kape/Features/Debug/MotionDebugView.swift
- Kape/Kape/KapeTests/Core/Motion/MotionManagerTests.swift
