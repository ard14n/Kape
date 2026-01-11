---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
inputDocuments:
  - _bmad-output/planning-artifacts/product-brief-Kape-2026-01-09.md
workflowType: 'prd'
lastStep: 0
documentCounts:
  briefs: 1
  research: 0
  brainstorming: 0
  projectDocs: 0
---

# Product Requirements Document - Kape

**Author:** Ardian
**Date:** 2026-01-09

## Executive Summary

**Kape!** is a viral iOS party game that culturally adapts the successful "Heads Up!" gameplay for the Albanian diaspora. By leveraging specific "inside jokes," culturally relevant content (like the "Gurbet" deck), and a viral-first design, it addresses the lack of emotional connection in generic party games.

### What Makes This Special

- **Cultural Resonance:** It's not just a game; it's a shared cultural experience. The "Gurbet" (Diaspora) content creates immediate emotional buy-in.
- **Viral Engine:** Designed for the "Network Effect" where every game played is an advertisement to observers, driving organic growth.
- **Native Quality:** Leveraging native iOS frameworks (CoreMotion, Haptics) for a precise, "instant fun" experience without the bloat of cross-platform wrappers.
- **Privacy First:** Detailed analytics are sacrificed for offline-first trust, crucial for the target audience.

## Project Classification

**Technical Type:** mobile_app
**Domain:** entertainment / cultural
**Complexity:** medium
**Project Context:** Greenfield - new project

## Success Criteria

### User Success
Success is defined by the "Vibe" of the party. We measure this through behavioral proxies that indicate engagement and social interaction.
- **The Vibe Check:** Users immediately start a new game (>30% Immediate Replay Rate).
- **The Post-Game Debate:** Users dwell on the results screen to laugh/discuss scores (>10s Avg Duration).
- **The Emotional Hook:** Users capture the moment (Screenshot Rate on results).

### Business Success
Primary focus is Viral User Acquisition, secondary is Monetization.
- **Viral Growth:** High organic share rate driving new users (K-Factor > 1.0).
- **Conversion:** Validating the willingness to pay for premium culture content (>2% conversion).

### Technical Success
The app must be "Party Proof" - instant, crash-free, and reliable in chaotic environments.
- **Zero Friction:** App ready to play in < 2 seconds.
- **Trustworthy AI:** False positive motion detection < 5% (users must trust the judge).
- **Stability:** Crash rate < 0.1% (never kill the vibe).

### Measurable Outcomes
- **Viral Acquisition:** 10,000 organic downloads in Month 1.
- **Engagement:** >80% Game Completion Rate.
- **Replayability:** >30% Immediate Replay Rate.
- **Social Proof:** >10% Share Rate (Result Screen).

## Product Scope

### MVP - Minimum Viable Product
The "Instant Fun" version.
- **Core Gameplay:** 60s Timer, Tilt Control (Motion Manager), Haptic Feedback.
- **Content:** 3 Free Decks (Mix, Ushqim, Gurbet), 1 Paid Deck (VIP & Muzikë).
- **UI:** Landscape-only, High-Contrast "Neon" Dark Mode, Large Typography.
- **Tech:** Offline-first, Local JSON data, In-App Purchase logic (StoreKit).

### Growth Features (Post-MVP)
Features that fuel the viral loop but are too complex for V1.
- **Video Recording:** Capturing the player's reaction (requires AVFoundation & Permission flow).
- **Social Sharing:** Native share sheet integration for recorded videos.

### Vision (Future)
Community and Competition.
- **Community Decks:** User-generated content submission pipeline.
- **Battle Mode:** Team vs. Team score tracking for tournaments.
- **Android Port:** Expanding to the rest of the diaspora.

## User Journeys

**Journey 1: Ardi's "Vibe Shift" (The Catalyst)**
*Scenario:* A family gathering in Zurich is getting quiet after dinner. The cousins are on their phones.
*Action:* Ardi pulls out Kape! and selects the "Gurbet" deck.
*Climax:* The prompt "Western Union" appears. Uncle Besim jumps up and shouts "Money for the house in Kosovo!" Everyone explodes in laughter. The vibe shifts instantly from boring to electric.
*Resolution:* Ardi is the hero of the night. He immediately buys the "VIP" deck to keep the momentum going.

**Journey 2: Lisa's "Inclusion" (The Bridge)**
*Scenario:* Lisa is at the same party, feeling a bit left out because she doesn't speak fluent Albanian.
*Action:* Ardi switches to "Mix Shqip" mode (bilingual).
*Climax:* Lisa gets the card "Qebapa". She describes it as "Those little meat fingers we ate in Prishtina!" Ardi guesses correctly.
*Resolution:* Lisa feels proud and part of the "inside" group. She downloads the app to play with her own friends later.

**Journey 3: Aunt Shpresa's "Relatability" (Accessibility)**
*Scenario:* Ardi hands the phone to Aunt Shpresa (55). She usually refuses tech games ("I can't see small letters").
*Action:* She holds the phone. The text is HUGE and high-contrast.
*Climax:* She sees "Ajvar". She doesn't need to read instructions; she just plays. She gestures wildly.
*Resolution:* She asks Ardi to install it on her iPad so she can play with her grandkids.

**Journey 4: Ardi's "Digital Flex" (The Viral Loop)**
*Scenario:* Ardi and his cousins just crushed a round of "Gurbet", guessing 9 out of 10 words.
*Action:* The Result Screen flashes "9/10 - Legjendë 🦅". Ardi feels a surge of pride (Status).
*Climax:* He taps "Share". A sleek image with the double-headed eagle and the score is generated. He posts to Instagram: "Who can beat us? @CousinAli".
*Resolution:* His friend Dardan in Munich sees the story, laughs at the rank, and immediately downloads "Kape!" to challenge his own crew.

### Journey Requirements Summary
- **Content Engine:** Needs support for "Decks" with metadata (Language, Difficulty, Cultural Context).
- **Accessibility:** UI must use large dynamic type and high contrast by default.
- **Viral Features:** Result screen must generate shareable, culturally marked images (not just text).
- **Motion Logic:** Must distinguish between enthusiastic gestures and accidental slips.

## Innovation & Novel Patterns

### Detected Innovation Areas

#### 1. Interaction: The "Smart Tilt" Debounce
While using standard CoreMotion (Pitch) for detection, Kape! innovates on the **algorithm**.
- **Problem:** Standard implementations trigger too easily during enthusiastic play.
- **Solution:** A strict **Debounce Logic** that requires a return to "Neutral Position" before the next card can trigger. This prevents accidental skips during laughter.

#### 2. Immersion: The "Bone Conduction" Effect
Leveraging CoreHaptics specifically for the "Forehead Position".
- **The Mechanic:** Heavy haptic feedback triggers simultaneously with the "Success" sound.
- **The Innovation:** Because the device touches the skull, the user *feels* the success sound physically. This creates a deeply immersive, tactile feedback loop that web apps cannot replicate.

#### 3. Sociology: Identity as a Feature
Moving beyond "Content" to "Validation".
- **The Concept:** Standard games sell questions; Kape! sells belonging.
- **The Mechanism:** The "Gurbet" deck operates as a shibboleth—understanding the card "Western Union" isn't just a win, it's a validation of shared diaspora trauma/joy. The viral loop is built on *status signaling* (`Legjendë`) rather than just score.

### Market Context & Competitive Landscape
- **Heads Up! / Charades:** Generic content, weak connection to specific cultures.
- **Web-based Clones:** Lack access to high-fidelity CoreMotion and CoreHaptics (no bone conduction effect).
- **Physical Cards:** Lack the audio-visual feedback loop and viral sharing capability.

### Validation Approach
- **The "Vibe" Test:** User testing in loud party environments (simulated) to tune the Debounce threshold.
- **Haptic Tuning:** A/B testing vibration patterns to maximize the "Bone Conduction" sensation without being jarring.
- **Viral Proxy:** Measuring the "Screenshot Rate" of the Result Screen during beta.

### Risk Mitigation
- **Risk:** Motion sickness or neck strain.
    - **Mitigation:** Quick games (60s), ergonomic "Pass" gesture (Up) designed to be low-effort.
- **Risk:** Content fatigue.
    - **Mitigation:** High-frequency content updates via lightweight JSON delivery (no app update needed).

## Mobile App Specific Requirements

### Project-Type Overview
A native iOS application optimized for the "Party Context" - meaning speed, reliability, and respect for the environment (background music).

### Technical Architecture Considerations
- **Platform Support:**
  - **Target:** iPhone Only (Landscape Locked).
  - **Compatibility:** Runs on iPad in "iPhone Compatibility Mode" (2x scale).
  - **OS Version:** iOS 17.0+ (Leveraging `@Observable`, modern SwiftUI, and CoreHaptics).

- **Offline Strategy:**
  - **Architecture:** 100% Bundled.
  - **Data:** `decks.json` and assets are compiled into the binary.
  - **Network:** Zero-dependency for core gameplay. No "Initial Download" screen. Instant launch (< 0.5s).

### Implementation Considerations
- **Audio Session Policy:**
  - **Category:** `.ambient` (MixWithOthers).
  - **Behavior:** Respects hardware Silent Switch. Does NOT pause user's background music (Spotify/Apple Music).
  - **Implication:** Haptic feedback is elevated to "Critical" status as it may be the only feedback a user notices in varying noise/audio conditions.

- **Permissions Strategy:**
  - **CoreMotion:** Mandatory. Request clearly on first game start.
  - **Camera/Mic:** STRICTLY FORBIDDEN for MVP. No usage strings in Info.plist to avoid App Store questions.

- **Store Compliance:**
  - **In-App Purchase:** StoreKit 2 implementation for "VIP" deck validation.
  - **Privacy:** Offline-first design simplifies App Privacy labels (No Data Collected).

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP Approach:** Problem-Solving MVP (High Fidelity, Limited Scope).
**Philosophy:** "The Rolex of Party Games" - tiny scope, extreme polish.
**Resource Requirements:** 1 Senior iOS Dev (SwiftUI/CoreMotion expertise), 1 Product Designer.

### MVP Feature Set (Phase 1)
**Timeline:** < 4 Weeks

**Core User Journeys Supported:**
- Journey 1: Vibe Shift (Core Loop)
- Journey 4: Digital Flex (Viral Loop - Static)

**Must-Have Capabilities:**
- **iPhone Only:** Landscape locked interface.
- **Offline Engine:** Bundled JSON data, no network dependencies.
- **Motion Logic:** Debounced Tilt/Nod detection (High Precision).
- **Haptic Immersion:** Bone conduction feedback on success/pass.
- **Content:** 3 Free Decks, 1 Paid Deck (StoreKit 2).
- **Silent Mode Safety:** App respects hardware switch (Ambient Audio).

### Post-MVP Features

**Phase 2 (Growth - V1.1):**
- **Video Recording:** Capturing reaction videos (requires AVFoundation & Permissions).
- **Social Sharing:** Sharing video clips directly to Instagram/TikTok.

**Phase 3 (Expansion - V1.2+):**
- **Community Decks:** User submission pipeline.
- **Android Port:** FOMO marketing strategy initially; Android version follows once iOS viral loop is established.

### Risk Mitigation Strategy

**Technical Risks:** "Flaky" Motion Detection.
- **Mitigation:** Prototype `MotionManager` immediately with hard-coded debounce logic to ensure it feels "magical" before building UI.

**Market Risks:** Missing Android users (50% of market).
- **Mitigation:** Leverage "FOMO" as a status feature. "Get an iPhone or find a friend who has one." reinforcing the "Legend" status of the game.

**Resource Risks:** Timeline slippage.
- **Mitigation:** Ruthless cut of "Video Recording" from V1 to guarantee launch stability.

## Functional Requirements

### 1. Game Mechanics (The "Vibe" Engine)
- **FR1:** User can start a game with a selected deck (60s timer).
- **FR2:** User can "Tilt Down" to mark an answer as Correct (triggers success sound + haptic).
- **FR3:** User can "Tilt Up" to Pass (triggers pass sound + haptic).
- **FR4:** System enforces "Debounce Logic" (must return to neutral before next card).
- **FR5:** User receives a "10s Warning" (audio/haptic) before timer ends.
- **FR18:** System displays a "Place on Forehead" buffer state with 3-second countdown before game start.

### 2. Content Engine (The "Culture" Core)
- **FR6:** System loads decks from a local JSON file (Offline).
- **FR7:** User can browse decks with metadata (Title, Description, Icon, Difficulty).
- **FR8:** System randomizes card order for every session.
- **FR9:** System filters "Forbidden Words" to prevent duplication in later rounds.

### 3. Viral Loop (The "Status" System)
- **FR10:** User sees a "Result Screen" with Score, Rank (e.g., "Legjendë"), and accuracy.
- **FR11:** User can tap "Share" to generate a branded image (Score + Rank + Eagle Icon).
- **FR12:** User can share this image via native iOS Share Sheet (Instagram/WhatsApp).

### 4. Monetization (The "Premium" Validatior)
- **FR13:** User can see locked "VIP" decks.
- **FR14:** User can purchase "VIP Access" via In-App Purchase.
- **FR15:** System restores purchases for existing VIP users.

### 5. Settings & Accessibility
- **FR16:** User can toggle Sound on/off (Haptics remain on).
- **FR17:** User sees high-contrast text (White on Black/Red) by default.

### 6. System & Permissions
- **FR19:** System explicitly prompts for CoreMotion permissions on first use; if denied, shows a "Game Blocked" state with settings link.

## Non-Functional Requirements

### Performance
- **Instant Launch:** App must be playable (< 500ms) from cold launch to respect the "Party Context".
- **Fluidity:** UI and Motion Feedback must maintain 60fps (or 120fps on ProMotion) to prevent motion sickness during rapid head movements.
- **Latency:** Audio/Haptic feedback must play < 50ms after motion trigger to ensure the user feels the "Bone Conduction" effect properly.

### Reliability
- **Offline Guarantee:** App must function 100% without internet.
- **Interruption Safety:** Game must pause gracefully (saving state) if a phone call or system alert interrupts gameplay.
- **Thermal Comfort:** Optimization must prevent the device from becoming noticeably hot to touch, preventing "sweaty forehead" discomfort during gameplay.

### Accessibility
- **Visuals:** Text defaults to "Large" and high contrast (White on Black) to ensure legibility in dim environments (clubs/bars) for older relatives.
- **Motion Default:** The "Gold Standard" motion algorithm must work for 95% of users without manual sensitivity settings (Apple-like simplicity).

### System Integration
- **Audio Ambience:** Audio Session Category must be set to `.ambient` (MixWithOthers) to ensure Kape! NEVER interrupts the user's background music (Spotify/Apple Music).
- **Orientation Lock:** App must be hard-locked to Landscape Left/Right via `UIInterfaceOrientationMask`, overriding system rotation behavior where possible to prevent UI layout breaks during head movement.
- **Battery Efficiency:** 1 hour of continuous gameplay should consume < 10% battery.
