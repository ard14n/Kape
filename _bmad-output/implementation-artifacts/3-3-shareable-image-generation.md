# Story 3.3: Shareable Image Generation

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **Player**,
I want **to generate a cool image of my score**,
so that **I can post it to Instagram/TikTok**.

## Acceptance Criteria

1. **Given** a Score and Rank
   - **When** "Share" is tapped
   - **Then** the app must generate a `UIImage` (1080x1920 portrait, 9:16 Instagram Story format)
   - **And** the generation must use the "Electric Eagle" theme (per UX spec)
   - **And** if generation fails, must show user-friendly error alert

2. **Given** the Generated Image
   - **When** verified
   - **Then** it must include:
     - **Kape Logo** (top) - Use `AppIcon` or SF Symbol placeholder
     - **Score** (e.g., "9/10") in 96pt `.heavy` `.rounded` font
     - **Rank Badge** (reusing `RankBadge` component from Story 3.2)
     - **Footer** "kape.app" in 20pt for viral attribution
   - **And** use `RadialGradient` background matching rank color (`.neonGreen`/`.neonOrange`/`.white.opacity(0.6)`)
   - **And** apply `.neonGlow()` modifier to score and badge for premium "Tirana Night" aesthetic

3. **Given** the technical execution
   - **When** generating
   - **Then** it must use `ImageRenderer` (available iOS 16+, project targets iOS 17+)
   - **And** run on `@MainActor` (SwiftUI requirement)
   - **And** show loading indicator to prevent UI freeze (per NFR6: Thermal Comfort)
   - **And** return `UIImage?` (nil on failure)

## Tasks / Subtasks

- [x] **Task 1: Design `ShareLayoutView`** (AC: 1, 2)
  - [x] Create `Features/Summary/Views/ShareLayoutView.swift`
  - [x] Fixed frame: `1080x1920` (internal render size)
  - [x] Background: `.trueBlack` + `RadialGradient` using `result.rank.color`
  - [x] Logo: Use existing `AppIcon` asset or create placeholder
  - [x] Score: `.font(.system(size: 96, weight: .heavy, design: .rounded))`
  - [x] Reuse `RankBadge(rank: result.rank)` component (do NOT duplicate)
  - [x] Footer: "kape.app" in `.font(.system(size: 20, weight: .bold))`
  - [x] Apply `.neonGlow(color: result.rank.color)` to score and badge
  - [x] Support Dynamic Type (`@ScaledMetric` for accessibility, learned from Story 3.2 review)

- [x] **Task 2: Implement `ResultImageGenerator` Service** (AC: 3)
  - [x] Create `Features/Summary/Logic/ResultImageGenerator.swift`
  - [x] Method: `@MainActor static func generate(for result: GameResult) async -> UIImage?`
  - [x] Use `ImageRenderer(content: ShareLayoutView(result: result))`
  - [x] Set `renderer.scale = 3.0` (high-res for Instagram)
  - [x] Return `renderer.uiImage` (nil-safe)
  - [x] Handle errors gracefully (return nil if render fails)

- [x] **Task 3: Integrate with `ResultScreen`**
  - [x] Add loading state (`isGeneratingImage: Bool`) in `ResultScreen`
  - [x] On "Share" tap: Show `.progressView()` overlay
  - [x] Call `await ResultImageGenerator.generate(for: result)`
  - [x] If success: Store image (Story 3.4 will use it for Share Sheet)
  - [x] If failure: Show alert "Could not create image. Try again?"
  - [x] For now: Print success or show image in preview (Story 3.4 adds actual sharing)

- [x] **Task 4: Unit/UI Tests**
  - [x] `ResultImageGeneratorTests`: Verify non-nil image for valid `GameResult`
  - [x] Test all rank levels: `.legjende`, `.shqipe`, `.mishIHuaj` (ensure colors/layout correct)
  - [x] Use SwiftUI Preview to visually verify 1080x1920 layout

## Dev Notes

### Business Context (Viral Loop Priority)

**CRITICAL:** This image is the **primary growth engine** for Kape. PRD Success Metric: **K-Factor > 1.0** (viral growth) depends on users sharing premium-looking results to Instagram/TikTok. This feature directly drives:
- 10,000 organic downloads in Month 1
- >10% Share Rate target

**Quality Standard:** "Rolex of Party Games" - the image MUST look premium enough that users *want* to post it. Generic layouts will kill viral loop.

### Architecture Compliance

**Locations (per Feature-First structure):**
- Service: `Features/Summary/Logic/ResultImageGenerator.swift`
- View: `Features/Summary/Views/ShareLayoutView.swift` (rendering-only, not for display)

**Concurrency:** `ImageRenderer` requires `@MainActor`. Generation is typically fast (<100ms for vector layouts) but show loading indicator to respect NFR2 (Fluidity) and NFR6 (Thermal Comfort).

**iOS Version:** Project targets iOS 17+ (Architecture), `ImageRenderer` available iOS 16+. Use iOS 17+ APIs freely.

### Component Reuse (Anti-Duplication)

**MUST REUSE from Story 3.2:**
- `RankBadge` component: `Core/DesignSystem/Components/RankBadge.swift`
- `GameResult` model: `Data/Models/GameResult.swift` (has `score`, `total`, `rank`)
- Design tokens: `Core/DesignSystem/Colors.swift` (`.neonGreen`, `.neonOrange`, `.trueBlack`)
- Modifiers: `Core/DesignSystem/Modifiers.swift` (`.neonGlow(color:radius:)`)

**RadialGradient Pattern (from ResultScreen.swift):**
```swift
ZStack {
    Color.trueBlack.ignoresSafeArea()
    RadialGradient(
        colors: [result.rank.color, .trueBlack],
        center: .center,
        startRadius: 100,
        endRadius: 600
    )
}
```

### UX Design Specifications

**Visual Theme:** "Tirana Night" (Cyberpunk Glow + Minimalist Legibility)
- Reference: [UX Spec - Visual Design](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/ux-design-specification.md#L160-L188)
- Reference: [UX Spec - RankBadge Component](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/ux-design-specification.md#L287-L290)

**Typography Scale (per UX spec):**
```swift
// Score
.font(.system(size: 96, weight: .heavy, design: .rounded))

// Rank Badge (inside RankBadge component)
.font(.system(size: 34, weight: .heavy, design: .rounded))

// Footer
.font(.system(size: 20, weight: .bold, design: .rounded))
```

**Neon Glow Effect:**
```swift
.shadow(color: result.rank.color.opacity(0.8), radius: 20, x: 0, y: 0)
// Or use existing modifier:
.neonGlow(color: result.rank.color, radius: 20)
```

**Layout Positioning:**
- Logo: Top, centered (24pt from safe area)
- Score: Center-top third (large, dominant)
- Rank Badge: Center (below score)
- Footer: Bottom, centered (16pt from edge)

### Technical Implementation

**Async Image Generation Pattern:**
```swift
@MainActor
struct ResultImageGenerator {
    static func generate(for result: GameResult) async -> UIImage? {
        let view = ShareLayoutView(result: result)
            .frame(width: 1080, height: 1920)
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0 // High-res for Instagram
        
        // ImageRenderer.uiImage is synchronous but we use async for future-proofing
        return renderer.uiImage
    }
}
```

**Error Handling:**
```swift
// In ResultScreen
do {
    if let image = await ResultImageGenerator.generate(for: result) {
        self.generatedImage = image // Store for Story 3.4
    } else {
        showErrorAlert = true
    }
} catch {
    showErrorAlert = true
}
```

### Previous Story Learnings (Story 3.2 Code Review)

**Accessibility Requirements (Applied):**
- Use `@ScaledMetric` for dynamic text scaling
- Add `.minimumScaleFactor(0.5)` to prevent text truncation
- Respect `@Environment(\.accessibilityReduceMotion)` if adding animations

**Testing Pattern:**
- Test all `Rank` enum cases (`.legjende`, `.shqipe`, `.mishIHuaj`)
- Verify color mapping matches `Rank.color` property
- Use boundary scores: 0, 4, 5, 9, 10, 15

### Asset Requirements

**Kape Logo:**
- Check `Kape/App/Assets.xcassets` for existing `AppIcon` or logo asset
- If missing: Use SF Symbol `app.badge` as placeholder OR add logo asset
- Logo should be monochrome white for "Electric Eagle" theme

### Cross-Story Context

**Story 3.4 Dependency:** Native Sharing Integration will consume the `UIImage` generated here. Task 3 is intentionally incomplete - we verify image generation but defer `ShareLink`/`UIActivityViewController` integration to Story 3.4.

**Integration Point:** Store generated image in `ResultScreen` state, pass to Story 3.4's share handler.

### Performance Considerations

**NFR2 (Fluidity):** Show loading indicator during generation to maintain 60fps perception
**NFR6 (Thermal Comfort):** Single image render is lightweight, but loading state prevents perceived freeze

### Testing Strategy

**Unit Tests (`ResultImageGeneratorTests.swift`):**
```swift
func testGenerate_WithValidResult_ReturnsNonNilImage() async {
    let result = GameResult(score: 10, passed: 2, date: Date())
    let image = await ResultImageGenerator.generate(for: result)
    XCTAssertNotNil(image)
}

func testGenerate_ForEachRank_ReturnsImage() async {
    let ranks: [(score: Int, rank: GameResult.Rank)] = [
        (4, .mishIHuaj), (5, .shqipe), (10, .legjende)
    ]
    for (score, expectedRank) in ranks {
        let result = GameResult(score: score, passed: 0, date: Date())
        XCTAssertEqual(result.rank, expectedRank)
        let image = await ResultImageGenerator.generate(for: result)
        XCTAssertNotNil(image, "Failed for rank \(expectedRank)")
    }
}
```

**Visual Verification:**
- Use `#Preview` macro to render `ShareLayoutView` at 1080x1920
- Export to simulator photo library and verify Instagram Story appearance

### References

- [GameResult Model](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Data/Models/GameResult.swift) - Source data
- [RankBadge Component](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Core/DesignSystem/Components/RankBadge.swift) - Reusable badge
- [ResultScreen](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Features/Summary/Views/ResultScreen.swift) - Integration point
- [Design System Colors](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Core/DesignSystem/Colors.swift) - Color tokens
- [Design System Modifiers](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Core/DesignSystem/Modifiers.swift) - `.neonGlow()`
- [UX Spec: Visual Design](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/ux-design-specification.md#L160-L188) - Theme details
- [UX Spec: RankBadge](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/ux-design-specification.md#L287-L290) - Component spec
- [Epics: Story 3.3](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/epics.md#L321-L334) - Original requirements
- [Story 3.2: Result Screen UI](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/implementation-artifacts/3-2-result-screen-ui.md) - Previous implementation
- [Story 3.4: Native Sharing](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/epics.md#L335-L347) - Next story

## Dev Agent Record

### Agent Model Used

Gemini 2.5 Pro

### Debug Log References

- Build succeeded on iPhone 17 Pro Simulator
- All 8 ResultImageGeneratorTests passed (including CR-04 precision tests)
- 3 pre-existing failures in DeckBrowserViewTests (unrelated to Story 3.3)

### Completion Notes List

- Created `ShareLayoutView.swift` with 1080x1920 portrait layout for Instagram Stories
- **CR-01 Fix:** Replaced `@ScaledMetric` with fixed sizes for consistent branded output
- **CR-02 Fix:** Aligned RadialGradient parameters with ResultScreen for brand consistency
- Created `ResultImageGenerator` service with `@MainActor` and `ImageRenderer` (scale 3.0)
- Integrated with `ResultScreen`: loading state, progress indicator, error alert
- **CR-04 Fix:** Added precise dimension and scale validation tests
- **CR-05 Fix:** Fixed race condition in callback timing
- Generated image stored in `generatedImage` state for Story 3.4 ShareLink integration
- Comprehensive test suite covers all 3 rank levels, boundary scores, dimensions, and aspect ratio

### File List

- [NEW] `Kape/Features/Summary/Views/ShareLayoutView.swift`
- [NEW] `Kape/Features/Summary/Logic/ResultImageGenerator.swift`
- [NEW] `KapeTests/Features/Summary/ResultImageGeneratorTests.swift`
- [MODIFIED] `Kape/Features/Summary/Views/ResultScreen.swift`
