---
stepsCompleted: [1, 2, 3, 4]
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/ux-design-specification.md
---

# Kape - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Kape, decomposing the requirements from the PRD, UX Design if it exists, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: User can start a game with a selected deck (60s timer).
FR2: User can "Tilt Down" to mark an answer as Correct (triggers success sound + haptic).
FR3: User can "Tilt Up" to Pass (triggers pass sound + haptic).
FR4: System enforces "Debounce Logic" (must return to neutral before next card).
FR5: User receives a "10s Warning" (audio/haptic) before timer ends.
FR6: System loads decks from a local JSON file (Offline).
FR7: User can browse decks with metadata (Title, Description, Icon, Difficulty).
FR8: System randomizes card order for every session.
FR9: System filters "Forbidden Words" to prevent duplication in later rounds.
FR10: User sees a "Result Screen" with Score, Rank (e.g., "Legjendë"), and accuracy.
FR11: User can tap "Share" to generate a branded image (Score + Rank + Eagle Icon).
FR12: User can share this image via native iOS Share Sheet (Instagram/WhatsApp).
FR13: User can see locked "VIP" decks.
FR14: User can purchase "VIP Access" via In-App Purchase.
FR15: System restores purchases for existing VIP users.
FR16: User can toggle Sound on/off (Haptics remain on).
FR17: User sees high-contrast text (White on Black/Red) by default.
FR18: System displays a "Place on Forehead" buffer state with 3-second countdown before game start.
FR19: System explicitly prompts for CoreMotion permissions on first use; if denied, shows a "Game Blocked" state with settings link.

### NonFunctional Requirements

NFR1: Instant Launch: App must be playable (< 500ms) from cold launch.
NFR2: Fluidity: UI and Motion Feedback must maintain 60fps (or 120fps).
NFR3: Latency: Audio/Haptic feedback must play < 50ms after motion trigger.
NFR4: Offline Guarantee: App must function 100% without internet.
NFR5: Interruption Safety: Game must pause gracefully if interrupted.
NFR6: Thermal Comfort: Prevent device from becoming noticeably hot.
NFR7: Accessibility: Text defaults to "Large" and high contrast.
NFR8: Motion Default: Algorithm must work for 95% of users without manual sensitivity settings.
NFR9: Audio Ambience: Audio Session Category must be set to `.ambient`.
NFR10: Orientation Lock: Hard-locked to Landscape Left/Right.
NFR11: Battery Efficiency: 1 hour gameplay < 10% battery.

### Additional Requirements

**Architecture Requirements:**
- Starter Template: Vanilla SwiftUI (Standard Xcode App).
- Stack: Swift 5.9+, iOS 17+, SwiftData + JSON Hybrid Persistence.
- No Third-Party UI dependencies.
- Direct CoreMotion integration (no wrappers) in `/Core`.
- Architecture: Feature-First folder structure.
- Design System: "Neon" modifiers (not separate views).

**UX Requirements:**
- **Start Flow:** "Instant Party" flow - minimize time-to-laughter.
- **Feedback:** "Bone Conduction" effect (Haptic + Audio sync).
- **Visuals:** "Electric Eagle" theme (Black/Red/Neon Green).
- **Typography:** SF Pro Rounded (Heavy/Bold).
- **Legibility:** Dynamic Type support with huge fonts (80pt+) for cards.
- **Orientation:** **Landscape Only** (Resolved: Landscape is correct, ignoring UX doc error).

### FR Coverage Map

FR1: Epic 1 - Game Timer & Start
FR2: Epic 1 - Tilt Down (Correct)
FR3: Epic 1 - Tilt Up (Pass)
FR4: Epic 1 - Debounce Logic
FR5: Epic 1 - 10s Warning
FR6: Epic 2 - JSON Deck Loading
FR7: Epic 2 - Deck Browser
FR8: Epic 2 - Card Randomization
FR9: Epic 2 - Forbidden Words
FR10: Epic 3 - Result Screen
FR11: Epic 3 - Share Image Gen
FR12: Epic 3 - Native Share
FR13: Epic 4 - Locked Decks UI
FR14: Epic 4 - In-App Purchase
FR15: Epic 4 - Restore Purchase
FR16: Epic 1 - Sound Toggle
FR17: Epic 1 - High Contrast
FR18: Epic 1 - Buffer State
FR19: Epic 1 - Permissions

## Epic List

### Epic 1: The Core Vibe Engine
Goal: Enable users to play a complete 60-second round with motion controls and sensory feedback.
**User Value:** "I can play a seamless, bug-free game with my friends immediately."
**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR16, FR17, FR18, FR19

### Epic 2: Cultural Content System
Goal: Enable users to explore, select, and play different cultural decks with randomized content.
**User Value:** "I can choose the specific 'vibe' (Gurbet vs Mix) for my party."
**FRs covered:** FR6, FR7, FR8, FR9

### Epic 3: Social & Viral Validation
Goal: Enable users to view their "Legjendë" status and share it socially to drive growth.
**User Value:** "I can prove to my friends that I am the best."
**FRs covered:** FR10, FR11, FR12

### Epic 4: The Monetization Layer
Goal: Enable users to purchase and unlock premium content (VIP Decks).
**User Value:** "I can access exclusive content to keep the game fresh."
**FRs covered:** FR13, FR14, FR15

## Epic 1: The Core Vibe Engine

Goal: Enable users to play a complete 60-second round with motion controls and sensory feedback.

### Story 1.1: Project Initialization & Design System

As a Developer,
I want to initialize the project with the correct structure and design tokens,
So that we can build features with a consistent and premium "Electric Eagle" aesthetic.

**Acceptance Criteria:**

**Given** a clean Xcode workspace
**When** the project is initialized
**Then** it must use the "App" template with SwiftUI and no or SwiftData (via ModelContainer)
**And** the folder structure must match the `Features/Core/DesignSystem` architecture defined
**And** `Color+DesignSystem.swift` must include `.neonRed`, `.neonGreen`, `.trueBlack`
**And** a `.neonGlow()` ViewModifier must be available for testing

### Story 1.2: Core Motion Service

As a Player,
I want my head movements to be detected accurately as game inputs,
So that I can play the game without looking at the screen or touching buttons.

**Acceptance Criteria:**

**Given** the `MotionManager` service
**When** the device is tilted down (Pitch < -35 degrees)
**Then** it must emit a `.correct` event
**And** it must lock input (Debounce) until the device returns to Neutral (-10 to 10 degrees)

**Given** the `MotionManager` service
**When** the device is tilted up (Pitch > 35 degrees)
**Then** it must emit a `.pass` event
**And** it must lock input until return to Neutral

**Given** permission is denied
**When** the service starts
**Then** it must report a `.permissionDenied` error state

### Story 1.3: Game Loop State Machine

As a Player,
I want the game to follow a structured 60-second timer with clear states,
So that the gameplay is fair and predictable.

**Acceptance Criteria:**

**Given** `GameEngine`
**When** a game starts
**Then** it must enter `buffer` state (3 seconds) before `playing`

**Given** `playing` state
**When** the 60-second timer expires
**Then** it must transition to `finished` state

**Given** `playing` state
**When** 10 seconds remain
**Then** it must emit a `warning` event for audio/haptic sync

**Given** the app is backgrounded
**When** in `playing` state
**Then** the game must pause or end gracefully

### Story 1.4: Haptic & Audio Feedback System

As a Player,
I want to feel and hear my actions instantaneously,
So that I confirm my guesses without visual feedback (Bone Conduction).

**Acceptance Criteria:**

**Given** `HapticService`
**When** a `.correct` event occurs
**Then** it must play a `.heavy` impact haptic AND the "Success" sound

**Given** `HapticService`
**When** a `.pass` event occurs
**Then** it must play a `.rigid` impact haptic AND the "Whoosh" sound

**Given** Sound is toggled OFF
**When** an event occurs
**Then** Haptics must still play, but Audio is silenced

### Story 1.5: Gameplay UI (The Card Screen)

As a Guesser,
I want the game screen to be highly legible and reactive,
So that my friends can read the words easily while I hold the phone.

**Acceptance Criteria:**

**Given** the Game View
**When** a card is displayed
**Then** the text must be White on Black, dynamically sized (min 80pt)

**Given** a `.correct` state trigger
**When** rendering
**Then** the background must flash Neon Green (`#39FF14`)

**Given** a `.pass` state trigger
**When** rendering
**Then** the background must flash Neon Orange (`#FF9500`)

## Epic 2: Cultural Content System

Goal: Enable users to explore, select, and play different cultural decks with randomized content.

### Story 2.1: Content Data Architecture

As a Developer,
I want a robust data layer for loading Decks and Cards,
So that the app can function offline with reliable content.

**Acceptance Criteria:**

**Given** the `Deck` and `Card` models
**When** `decks.json` is loaded from the Bundle
**Then** it must parse correctly into Swift structs
**And** it must fail gracefully (unit test) if required fields (id, title) are missing

**Given** the `DeckService`
**When** initialization occurs
**Then** all decks must be available in memory immediately (synchronous load allowed for local JSON)

### Story 2.2: Deck Browser UI

As a Player,
I want to browse and select a specific deck (e.g., "Gurbet"),
So that I can customize the game vibe for my current group.

**Acceptance Criteria:**

**Given** the Main Menu view
**When** the app launches
**Then** it must display a horizontal or vertical list of available decks
**And** each deck must show its Title, Icon, and Description

**Given** a selected Deck
**When** "Start" is tapped
**Then** it must navigate to the Game View and inject the selected Deck

### Story 2.3: Deck Logic & Randomization

As a Player,
I want the cards to appear in a random order and not repeat,
So that the game feels fresh every time.

**Acceptance Criteria:**

**Given** a Game Session
**When** initialized with a Deck
**Then** the card order must be randomized (shuffled)
**And** it must not contain cards used in the immediate previous session (if implementation allows simple history) OR just simple shuffle for MVP

**Given** the "Forbidden Words" list
**When** a card is selected
**Then** (Future verification only, for MVP just load valid cards)

### Story 2.4: Initial Content Population

As a Player,
I want meaningful, funny content right out of the box,
So that I understand the humor immediately.

**Acceptance Criteria:**

**Given** `decks.json`
**When** created
**Then** it must contain at least 2 Decks: "Mix Shqip" and "Gurbet"
**And** each deck must have at least 50 cards
**And** the `icon_name` field for each deck must be a valid **SF Symbol** string (e.g., "airplane.departure", "music.mic") to ensure Neon Glow compatibility

## Epic 3: Social & Viral Validation

Goal: Enable users to view their "Legjendë" status and share it socially to drive growth.

### Story 3.1: Result & Status Calculation Logic

As a Player,
I want to see my score and rank immediately after the game,
So that I know how well I performed compared to my friends.

**Acceptance Criteria:**

**Given** a finished game session
**When** the result is calculated
**Then** it must compute Score (Correct answers) and Accuracy (Correct / Total)
**And** it must assign a Rank Title based on score (e.g., 0-4 "Mish i Huaj", 5-9 "Shqipe", 10+ "Legjendë")

### Story 3.2: Result Screen UI

As a Player,
I want a high-energy result screen that celebrates my win,
So that I feel good and want to play again.

**Acceptance Criteria:**

**Given** the Result View
**When** displayed
**Then** it must show the Score in huge text
**And** it must animate the Rank Badge (Scale/Bounce)
**And** the "Play Again" button must be the most prominent Element
**And** it must have a "Share" button

### Story 3.3: Shareable Image Generation

As a Player,
I want to generate a cool image of my score,
So that I can post it to Instagram/TikTok.

**Acceptance Criteria:**

**Given** a Score and Rank
**When** "Share" is tapped
**Then** the app must generate a UIImage (1080x1920 portrait ideal for stories)
**And** the image must include: Kape Logo, The Score, The Rank Badge, and the "Electric Eagle" background
**And** this generation must happen on a background thread if heavy

### Story 3.4: Native Sharing Integration

As a Player,
I want to share the generated image to my preferred social app,
So that I don't have to take a manual screenshot.

**Acceptance Criteria:**

**Given** a generated UIImage
**When** generation is complete
**Then** the native iOS Share Sheet (`UIActivityViewController` or `ShareLink` in SwiftUI) must present
**And** the image must be attached

## Epic 4: The Monetization Layer

Goal: Enable users to purchase and unlock premium content (VIP Decks).

### Story 4.1: StoreKit Service Strategy (Mock-First)

As a Developer,
I want to establish the `StoreServiceProtocol` and a robust `MockStoreService`,
So that we can build and test the entire UI flow without waiting for App Store Connect.

**Acceptance Criteria:**

**Given** `StoreServiceProtocol`
**When** defined
**Then** it must abstract `fetchProducts()`, `purchase()`, and `listenForTransactions()`

**Given** `MockStoreService`
**When** initialized
**Then** it must return configured mock products immediately
**And** allow simulating `.success`, `.failed`, and `.cancelled` purchase results via a developer toggle
**And** allow resetting purchase state for testing

### Story 4.2: Locked Content UI Strategy

As a Player,
I want to clearly see which decks are premium and locked,
So that I feel the desire to unlock them (Upsell).

**Acceptance Criteria:**

**Given** the Deck Browser
**When** a deck is PRO (VIP) and NOT purchased
**Then** it must show a "Lock" icon overlay
**And** the tap action must trigger the Purchase Sheet instead of starting the game
**And** the visuals should be slightly dimmed to indicate "unavailable"

### Story 4.3: Purchase Flow & State Management

As a Player,
I want to buy a deck and play it immediately,
So that there is no friction in the party flow.

**Acceptance Criteria:**

**Given** the Purchase Sheet
**When** the user confirms purchase via FaceID
**Then** the app must wait for the StoreKit `.success` result
**And** crucially, it must UNLOCK the deck immediately in the UI without app restart
**And** it must handle `.userCancelled` or `.error` states gracefully (Alerts)

### Story 4.4: Restore Purchases

As a Player,
I want to restore my previously bought decks after reinstalling the app,
So that I don't lose money.

**Acceptance Criteria:**

**Given** the Settings Modal
**When** "Restore Purchases" is tapped
**Then** it must call `AppStore.sync()` or check current entitlements
**And** it must update the local locked/unlocked state based on the result
**And** it must show a success/failure alert to the user

### Story 4.5: Production StoreKit Integration

As a Developer,
I want to swap the Mock Service for the real StoreKit 2 implementation,
So that we can process real money transactions on the App Store.

**Acceptance Criteria:**

**Given** the production app
**When** configured
**Then** `StoreService` must use real `Product.products(for:)`
**And** fetch real identifiers from App Store Connect
**And** verify transaction validity (JWS validation logic if needed, or rely on StoreKit 2 default)

## Epic 5: Visual Experience Upgrade

Goal: Modernize the UI to improve readability, contrast, and overall aesthetic quality while maintaining the core "vibe".

### Story 5.1: UI Polish & Modernization

As a User,
I want a modern, legible, and premium UI,
So that the game feels high-quality and is easy to use.

**Acceptance Criteria:**

**Given** the Main Menu and Game Views
**When** displayed
**Then** text contrast must be WCAG AA compliant (no low-contrast green-on-green or grey-on-black)
**And** the "glow" effects must be subtle and not reduce readability
**And** the "Start Game" button must look premium without overbearing effects
**And** "VIP Decks" label must be readable (adjust red color)
**And** the overall aesthetic should feel "cleaner" and less "dated neon"
**And** gradients must be smoother

### Story 5.3: UI Albanian Localization

As a Player,
I want the entire game interface to be in Albanian,
So that the experience feels fully authentic to the cultural theme.

**Acceptance Criteria:**

**Given** the App Interface
**When** displayed
**Then** all buttons and labels must be in Albanian
**And** "Play" must be "Luaj"
**And** "Settings" must be "Cilësimet"
**And** "Restore Purchases" must be "Rikthe Blerjet"
**And** "Back" must be "Mbrapa"
