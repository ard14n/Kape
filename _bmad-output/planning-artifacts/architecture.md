---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7]
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/product-brief-Kape-2026-01-09.md
  - _bmad-output/planning-artifacts/ux-design-specification.md
workflowType: 'architecture'
project_name: 'Kape'
user_name: 'Ardian'
date: '2026-01-09'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
The system must support a high-frequency (60hz) game loop driven by hardware sensor data. Key functional blocks include:
*   **Game Engine:** State machine managing Time(60s) -> Input(Tilt) -> Score.
*   **Deck System:** Content delivery engine capable of handling localized strings and "Inside Joke" metadata.
*   **Result Generation:** Logic to calculate "Legjendë" status and generate shareable media assets.

**Non-Functional Requirements:**
*   **Latency:** Input-to-Feedback latency must be near-zero (<16ms) for the "physical prop" illusion.
*   **Resilience:** The app must not crash or stutter even if the user shakes the device violently (Input Debouncing).
*   **Battery:** Efficient use of sensors to avoid draining battery during long parties.

**Scale & Complexity:**
*   **Primary domain:** Mobile (iOS Native)
*   **Complexity level:** Medium (Due to hardware integration logic)
*   **Estimated architectural components:** ~12-15 (GameManager, MotionService, AudioService, HapticService, Router, etc.)

### Technical Constraints & Dependencies

*   **Platform:** iOS 17+ (SwiftUI).
*   **Hardware:** iPhone Only (Requires Accelerometer/Gyro).
*   **Permissions:** Motion & Fitness (Critical path).
*   **No Third-Party UI:** All visual components must be built in-house using standard SwiftUI modifiers.

### Cross-Cutting Concerns Identified

1.  **Motion Input Pipeline:** Raw sensor data -> Filtering/Debounce -> Game Action. This affects every gameplay screen.
2.  **Sensory Feedback:** Validating that every state change has an accompanying Haptic+Audio response.
3.  **Navigation State:** Managing the "Sheet Overlay" architecture defined in UX without creating "Modal Hell."

## Starter Template Evaluation

### Primary Technology Domain
**Native iOS (SwiftUI)** - Chosen for direct access to `CoreMotion` and `Haptics`.

### Starter Options Considered
1.  **The Composable Architecture (TCA):** powerful state management, but adds significant dependency weight and learning curve.
2.  **SwiftUI-MVVM-C:** Good for complex navigation, but Kape uses a simple "Sheet" architecture.
3.  **Vanilla SwiftUI (Xcode Default):** Cleanest slate, zero overhead, maximum sensor performance.

### Selected Starter: Vanilla SwiftUI (Standard Xcode App)

**Rationale for Selection:**
*   **Performance:** Direct control over the `MotionManager` loop without intermediate abstraction layers is critical for the "Instant Fun" requirement.
*   **Dependencies:** Adheres to the "No Third-Party UI" rule. Keeps the project "boring" and stable.
*   **Flexibility:** Allows us to build the custom "Neon" modifier system without fighting a template's existing styles.

**Initialization Command:**
*(Manual Setup required as no CLI exists for standard Xcode templates)*
1.  Open Xcode -> Create New Project -> App
2.  Product Name: `Kape`
3.  Interface: `SwiftUI`, Language: `Swift`

**Architectural Decisions Provided by Starter:**

**Language & Runtime:**
*   **Swift 5.9+**: Leveraging modern concurrency (`async/await`) for the Motion Service.
*   **SwiftData**: utilizing the modern persistence layer for User Decks and Game History (if needed).

**Code Organization (Proposed Structure):**
*   `/App`: App entry point, Main wrapper.
*   `/Features`: Modular features (e.g., `/GameLoop`, `/DeckBuilder`, `/Onboarding`).
*   `/Core`: Shared services (`MotionService`, `HapticEngine`, `GameState`).
*   `/DesignSystem`: The "Neon" UI modifiers and atoms.

**Development Experience:**
*   **Linting:** implementation of `SwiftLint` build phase recommended.
*   **Previews:** use of `#Preview` macros for rapid UI iteration.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
*   **Persistence Strategy:** Hybrid Data Model (SwiftData + JSON Bundle).
*   **State Management:** `@Observable` Macro (Swift 5.9+).
*   **Motion Pipeline:** Direct CoreMotion integration (60Hz) with Debounce logic.

**Important Decisions (Shape Architecture):**
*   **Audio/Haptics:** AVFoundation + UIKit Haptic Engine (Native).
*   **Navigation:** Sheet Coordinator (Zero-Nav overlay architecture).

### Data Architecture

**1. Content Persistence Strategy: Hybrid**
*   **Static Content (The Decks):** JSON-in-Bundle (`decks.json`).
    *   **Rationale:** "Source of Truth" is an easily editable file. Decouples content creation from code. Easy to update via OTA or app updates.
    *   **Mechanism:** `DeckService` loads JSON into memory struct models at startup. Using `Codable` for parsing.
*   **User Data (The History):** SwiftData (iOS 17+).
    *   **Rationale:** Efficient handling of Highscores, Game History, and unlocked achievements.
    *   **Mechanism:** `modelContainer` injected into environment.

**2. Data Validation**
*   **Content:** Schema validation via comprehensive Codable Unit Tests (Fails build if JSON is broken).

### Authentication & Security

**1. Authentication Method: None (MVP)**
*   **Rationale:** Frictionless entry ("Instant Fun"). No User Accounts required for V1.
*   **Future Proofing:** Design `UserSession` to be nullable for future Apple Sign-In support.

### API & Communication Patterns

**1. API Strategy: Local-First**
*   **Rationale:** The game must work 100% offline (Basement Party scenario).
*   **Updates:** Content updates delivered via App Store release initially.

### Frontend Architecture

**1. State Management: @Observable**
*   **Rationale:** Modern, performant observation tracking. Crucial for the high-frequency game loop to prevent over-rendering of the view hierarchy.

**2. Component Architecture: Modifier-First**
*   **Rationale:** Adopting the "Neon" design system via custom ViewModifiers (e.g., `.neonGlow()`, `.tiltReactive()`) to keep View code clean.

### Infrastructure & Deployment

**1. CI/CD: Manual -> Xcode Cloud**
*   **Rationale:** Start with manual TestFlight uploads. Migrate to Xcode Cloud once the project structure is stabilized.

### Decision Impact Analysis

**Implementation Sequence:**
1.  **Project Setup:** Standard SwiftUI App.
2.  **Core Services:** `MotionManager`, `AudioService`, `HapticService`.
3.  **Data Layer:** JSON Parser for Decks + SwiftData Model for History.
4.  **Game Loop:** The "Engine" linking Motion to Game State.
5.  **UI Construction:** Implementing the "Neon" modifiers.

## Implementation Patterns & Consistency Rules

### Naming Patterns
*   **Swift Code:** Standard `camelCase` for all properties/methods.
*   **JSON Content:** `snake_case` (e.g., `inside_joke_id`).
    *   *Rule:* All Codable structs MUST implement `CodingKeys` to map snake_case -> camelCase.
*   **Asset Catalog:** `kebab-case` (e.g., `icon-party-mode`).
*   **Modifiers:** `camelCase` verbs (e.g., `.neonGlow()`, `.tiltReactive()`).

### Structure Patterns
*   **Feature-First:**
    *   `/Features/Game/Views/GameScreen.swift`
    *   `/Features/Game/Logic/GameEngine.swift` (State Machine)
*   **Core Services:**
    *   `/Core/Motion/MotionManager.swift` (Singleton/Actor)
    *   `/Core/Audio/AudioService.swift`
*   **Design System:**
    *   `/DesignSystem/Atoms/NeonText.swift`
    *   `/DesignSystem/Modifiers/View+Glow.swift`

### Communication Patterns
*   **Services -> ViewModels:** `async/await` streams or `@Published` properties.
*   **Input Pipeline:**
    *   `MotionManager` stream -> `GameEngine` (Reduces to Action) -> `GameState` (Updates UI).
*   **Error Handling:**
    *   **Silent Failures:** For non-critical assets (missing haptic).
    *   **User Facing:** Alert for critical data failure (Corrupt Decks).

### Enforcement Guidelines
*   **All Agents MUST:**
    *   Use `CodingKeys` for external data.
    *   Isolate `CoreMotion` code in `/Core`.
    *   Never put game logic inside a SwiftUI `View` body.

## Project Structure & Boundaries

### Complete Project Directory Structure

```text
Kape/
├── App/
│   ├── KapeApp.swift            # Entry Point (main)
│   ├── Assets.xcassets          # Global Assets (AppIcon, Colors)
│   └── Info.plist
├── Core/                        # Shared Infrastructure
│   ├── Motion/
│   │   └── MotionManager.swift  # Raw Sensor Handler (CoreMotion)
│   ├── Audio/
│   │   └── AudioService.swift   # AVFoundation Wrapper
│   └── Haptics/
│       └── HapticService.swift  # CHHapticEngine Wrapper
├── Data/
│   ├── Models/
│   │   ├── Deck.swift           # Content Model (Codable)
│   │   └── GameResult.swift     # User Data Model (SwiftData)
│   ├── State/
│   │   └── AppState.swift       # Global Coordinator (Observable)
│   └── Resources/
│       └── decks.json           # Content Source of Truth
├── Features/                    # Feature Modules
│   ├── Onboarding/
│   │   └── Views/
│   │       └── TiltTutorialView.swift
│   ├── Game/
│   │   ├── Logic/
│   │   │   └── GameEngine.swift # The 60hz Loop State Machine
│   │   └── Views/
│   │       └── GameScreen.swift
│   └── Summary/
│       └── Views/
│           └── ResultView.swift
├── DesignSystem/                # "Neon" UI Kit
    ├── Modifiers/
    │   ├── NeonGlow.swift
    │   └── TiltReactive.swift
    └── Components/
        ├── KapeCard.swift
        └── NeonButton.swift
```

### Architectural Boundaries

**API Boundaries (Internal):**
*   **Motion Service:** Exposes an `AsyncStream<MotionData>` or `@Published` property. Does NOT know about `GameEngine`.
*   **Game Engine:** Consumes Motion Data, emits `GameAction` (Score, Pass, Fail). Does NOT touch UIKit/View code.
*   **Views:** Only observe `AppState` or Feature ViewModels. Never talk to `CoreMotion` directly.

**Data Boundaries:**
*   **Static Content:** Read-only from `decks.json`.
*   **User Persistence:** Read/Write via `SwiftData` context.

### Requirements to Structure Mapping

**Feature/Epic Mapping:**
*   **Epic: Core Gameplay** -> `/Features/Game/` + `/Core/Motion/`
*   **Epic: Content System** -> `/Data/Resources/decks.json` + `/Data/Models/Deck.swift`
*   **Epic: Design System** -> `/DesignSystem/`

**Cross-Cutting Concerns:**
*   **Haptics:** `/Core/Haptics/` (Injected into GameEngine)
*   **Sound:** `/Core/Audio/` (Injected into GameEngine)

### Integration Points

**Internal Communication:**
*   **Motion -> Engine:** High-frequency polling (60Hz).
*   **Engine -> Audio/Haptic:** Event-triggered (e.g., `onTiltSuccess`).
*   **Engine -> View:** State-driven (`@Observable` properties).

### File Organization Patterns

**Source Organization:**
*   **Features:** Grouped by Domain (Game, Onboarding), not Type (Views, VMs).
*   **Core:** Grouped by Technology (Motion, Audio).

**Asset Organization:**
*   **JSON:** `/Data/Resources/`
*   **Images/Colors:** `Assets.xcassets`

## Architecture Validation Results

### Coherence Validation ✅
*   **Decision Compatibility:** SwiftData + JSON + @Observable work seamlessly together.
*   **Pattern Consistency:** `CodingKeys` defined as the bridge between JSON `snake_case` and Swift `camelCase`.

### Requirements Coverage ✅
*   **Latency:** <16ms ensured by direct CoreMotion usage.
*   **Offline:** 100% Offline capability via Bundle JSON.
*   **Design:** "Neon" system architected as reusable Modifiers.

### Readiness Assessment
**Status:** READY FOR IMPLEMENTATION
**Confidence:** HIGH

**First Step:** Initialize Xcode Project structure.

## Architecture Completion Summary

### Workflow Completion

**Architecture Decision Workflow:** COMPLETED ✅
**Total Steps Completed:** 8
**Date Completed:** 2026-01-09
**Document Location:** _bmad-output/planning-artifacts/architecture.md

### Final Architecture Deliverables

**📋 Complete Architecture Document**

- All architectural decisions documented with specific versions
- Implementation patterns ensuring AI agent consistency
- Complete project structure with all files and directories
- Requirements to architecture mapping
- Validation confirming coherence and completeness

**🏗️ Implementation Ready Foundation**

- 10 key architectural decisions made (Stack, Data, State, Motion, Audio, etc.)
- 4 comprehensive pattern categories (Naming, Structure, Communication, Enforcement)
- 5 main architectural components specified (App, Core, Data, Features, DesignSystem)
- All Functional & Non-Functional requirements fully supported

**📚 AI Agent Implementation Guide**

- Technology stack with verified versions (Swift 5.9+, iOS 17+)
- Consistency rules that prevent implementation conflicts
- Project structure with clear boundaries
- Integration patterns and communication standards

### Implementation Handoff

**For AI Agents:**
This architecture document is your complete guide for implementing Kape. Follow all decisions, patterns, and structures exactly as documented.

**First Implementation Priority:**
Initialize Xcode Project with Vanilla SwiftUI template.

**Development Sequence:**

1. Initialize project using documented starter template
2. Set up development environment per architecture
3. Implement core architectural foundations (MotionManager, AudioService)
4. Build features following established patterns (GameLoop)
5. Maintain consistency with documented rules

### Quality Assurance Checklist

**✅ Architecture Coherence**

- [x] All decisions work together without conflicts
- [x] Technology choices are compatible
- [x] Patterns support the architectural decisions
- [x] Structure aligns with all choices

**✅ Requirements Coverage**

- [x] All functional requirements are supported
- [x] All non-functional requirements are addressed
- [x] Cross-cutting concerns are handled
- [x] Integration points are defined

**✅ Implementation Readiness**

- [x] Decisions are specific and actionable
- [x] Patterns prevent agent conflicts
- [x] Structure is complete and unambiguous
- [x] Examples are provided for clarity

### Project Success Factors

**🎯 Clear Decision Framework**
Every technology choice was made collaboratively with clear rationale, ensuring all stakeholders understand the architectural direction.

**🔧 Consistency Guarantee**
Implementation patterns and rules ensure that multiple AI agents will produce compatible, consistent code that works together seamlessly.

**📋 Complete Coverage**
All project requirements are architecturally supported, with clear mapping from business needs to technical implementation.

**🏗️ Solid Foundation**
The chosen starter template and architectural patterns provide a production-ready foundation following current best practices.

---

**Architecture Status:** READY FOR IMPLEMENTATION ✅

**Next Phase:** Begin implementation using the architectural decisions and patterns documented herein.

**Document Maintenance:** Update this architecture when major technical decisions are made during implementation.
