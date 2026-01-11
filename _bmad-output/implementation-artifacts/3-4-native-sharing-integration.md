# Story 3.4: Native Sharing Integration

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a **Player**,
I want **to share the generated image to my preferred social app**,
so that **I don't have to take a manual screenshot**.

## Acceptance Criteria

1. **Given** a generated UIImage (from Story 3.3)
   - **When** generation is complete
   - **Then** the native iOS Share Sheet (`UIActivityViewController` or `ShareLink` in SwiftUI) must present
   - **And** the image must be attached
   - **And** user can share to Instagram, WhatsApp, TikTok, or any app supporting image sharing

2. **Given** the Share Sheet is presented
   - **When** user selects a destination app
   - **Then** the image must be passed correctly without corruption or quality loss
   - **And** the share sheet must dismiss cleanly after completion/cancellation

3. **Given** a share attempt
   - **When** sharing is successful OR cancelled
   - **Then** the UI must return to normal state without errors
   - **And** no memory leaks from holding `UIImage` references

## Tasks / Subtasks

- [x] **Task 1: Integrate Share Sheet in ResultScreen** (AC: 1, 2)
  - [x] Modify `ResultScreen.swift` to present share sheet after image generation
  - [x] Use `ShareLink` (SwiftUI iOS 16+) with generated `UIImage`
  - [x] OR use UIKit `UIActivityViewController` wrapped in `UIViewControllerRepresentable`
  - [x] Ensure share sheet appears automatically after successful image generation
  - [x] Pass `generatedImage` from state to share component
  - [x] **Critical:** Verify `Info.plist` contains `NSPhotoLibraryAddUsageDescription` if "Save Image" is supported

- [x] **Task 2: Create Shareable Data Wrapper** (AC: 1, 2)
  - [x] Create `Features/Summary/Logic/ShareableImage.swift` if needed
  - [x] Conform to `Transferable` protocol (iOS 16+ ShareLink requirement)
  - [x] **Critical:** Import `UniformTypeIdentifiers` to prevent compiler errors
  - [x] Implement `static var transferRepresentation: some TransferRepresentation`
  - [x] Support PNG export for lossless quality

- [x] **Task 3: Handle Share Completion/Cancellation** (AC: 3)
  - [x] Clean up `generatedImage` state after share completes
  - [x] Handle user cancellation gracefully (dismiss sheet, no error)
  - [x] Reset `isGeneratingImage` and button states

- [x] **Task 4: Add Unit/UI Tests**
  - [x] Test share sheet presentation with mock image
  - [x] Test completion callback cleanup
  - [x] Test cancellation handling

## Review Follow-ups (AI)

- [x] [AI-Review][High] Add `NSPhotoLibraryAddUsageDescription` to Target Info settings (Required for "Save Image" to prevent crash)
- [x] [AI-Review][Medium] Added `ResultScreenShareTests.swift` to File List (Fixed)

## Dev Notes

### Business Context (Viral Loop Critical Path)

**CRITICAL:** This is the FINAL STEP in the viral loop. PRD Success Metric: **K-Factor > 1.0** depends on FRICTIONLESS sharing. Users must go from "See Score" → "Image Shared to Instagram" in < 3 seconds.

**Quality Standard:** Zero friction. The share sheet appearing feels like "magic" - no extra taps after "Share" button.

### Architecture Compliance

**Locations (per Feature-First structure):**
- Primary: `Features/Summary/Views/ResultScreen.swift` (integrate share sheet)
- Optional: `Features/Summary/Logic/ShareableImage.swift` (if Transferable wrapper needed)

**SwiftUI Sharing Options (iOS 17+):**

1. **ShareLink (Recommended):**
```swift
ShareLink(item: image, preview: SharePreview("My Kape Score", image: Image(uiImage: image))) {
    Label("Share", systemImage: "square.and.arrow.up")
}
```

2. **UIActivityViewController (Fallback):**
```swift
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
}
```

**iOS Version Context:** Project targets iOS 17+ (per Architecture). Both `ShareLink` and `UIActivityViewController` are available.

### Component Reuse from Story 3.3

**MUST REUSE:**
- `generatedImage: UIImage?` state variable in `ResultScreen.swift` (line 35)
- `ResultImageGenerator.generate(for:)` already called in `generateShareImage()` method (lines 169-187)
- Current flow: Share button → `generateShareImage()` → stores in `generatedImage` → calls `onShare?()` callback

**Current Integration Point (ResultScreen.swift:169-187):**
```swift
private func generateShareImage() async {
    isGeneratingImage = true
    defer { isGeneratingImage = false }
    
    if let image = await ResultImageGenerator.generate(for: result) {
        generatedImage = image  // <-- Image is stored here
        await MainActor.run {
            print("✅ Image generated: \(image.size)")
            onShare?()  // <-- Currently just prints, needs ShareLink integration
        }
    } else {
        showImageError = true
    }
}
```

### Implementation Strategy

**Primary Strategy: ShareLink (Recommended)**
The cleanest modern approach using SwiftUI native sharing.
```swift
// Replace current Share button with conditional ShareLink
if let image = generatedImage {
    ShareLink(
        item: Image(uiImage: image),
        preview: SharePreview("Kape Score", image: Image(uiImage: image))
    ) {
        HStack {
            Image(systemName: "square.and.arrow.up")
            Text("Share")
        }
    }
} else {
    // Existing generate button
}
```

**Fallback Strategy: UIActivityViewController (UIKit)**
Use only if ShareLink fails. **CRITICAL:** You MUST handle iPad Popover or the app will CRASH.
```swift
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // CRITICAL IPAD CRASH FIX
        // On iPad, this must be presented as a popover.
        // The coordinator must configure `.sourceView` or `.sourceRect`
        // prior to presentation.
        
        return controller
    }
}
```

**Modified Flow:**
1. User taps "Share" button
2. `isGeneratingImage = true`, show loading spinner
3. Generate image via `ResultImageGenerator`
4. On success: `generatedImage = image`, trigger ShareLink presentation
5. On dismiss: `generatedImage = nil` (cleanup)

### Technical Requirements

**Permissions Check:**
Check `Info.plist` for `NSPhotoLibraryAddUsageDescription` ("Privacy - Photo Library Additions Usage Description"). Even if system handles it, this prevents potential crashes on "Save Image".

**Transferable Protocol (for ShareLink with UIImage):**
```swift
import UniformTypeIdentifiers // <-- Required for UTType

extension UIImage: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { image in
            image.pngData() ?? Data()
        }
    }
}
```

**Or create wrapper:**
```swift
struct ShareableImage: Identifiable, Transferable {
    let id = UUID()
    let uiImage: UIImage
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { shareableImage in
            shareableImage.uiImage.pngData() ?? Data()
        }
    }
}
```

### UX Requirements

**Share Sheet Behavior:**
- Present modally over ResultScreen
- Dismiss returns to ResultScreen (no navigation)
- Standard iOS share sheet appearance (per HIG)

**Timing:**
- Generation: < 500ms (typically ~100ms)
- Share sheet presentation: Immediate after generation
- Total user-perceived: "Tap Share → Sheet appears" < 1 second

### Previous Story Learnings (Story 3.3)

**Code Review Fixes Applied:**
- CR-05: Race condition in callback timing fixed (ensure state updates before callback)
- Always `await MainActor.run {}` for UI updates after async work

**Testing Pattern:**
- Test all rank levels to ensure image variations share correctly
- Verify image quality after share (PNG, not compressed JPEG)

### Testing Strategy

**Unit Tests:**
```swift
func testShareSheet_WithGeneratedImage_Presents() {
    // Given: Generated image exists
    // When: Share action triggered  
    // Then: Share sheet should present
}

func testShareSheet_OnDismiss_ClearsImage() {
    // Given: Share sheet presented with image
    // When: User dismisses without sharing
    // Then: generatedImage should be nil
}
```

**Manual Verification:**
- Generate image for each rank
- Share to Files app (available on all devices)
- Verify image is 1080x1920, PNG format, no quality loss
- Test cancel flow - sheet dismisses, no error

### Cross-Story Context

**Completes Epic 3:** This is the final story in Epic 3: Social & Viral Validation. After this:
- User can play game (Epic 1)
- User can select decks (Epic 2)  
- User sees results, generates branded image, shares to social media (Epic 3 complete)

**Next Epic:** Epic 4: The Monetization Layer (StoreKit integration)

### Performance Considerations

**NFR2 (Fluidity):** Share sheet is native iOS, inherently 60fps
**NFR6 (Thermal Comfort):** No additional CPU work, sheet is system-managed

### References

- [ResultScreen.swift](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Features/Summary/Views/ResultScreen.swift) - Integration point
- [ResultImageGenerator.swift](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Features/Summary/Logic/ResultImageGenerator.swift) - Image source
- [Story 3.3](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/implementation-artifacts/3-3-shareable-image-generation.md) - Previous story with image generation
- [Epics: Story 3.4](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/epics.md#L335-L347) - Original requirements
- [Apple ShareLink Docs](https://developer.apple.com/documentation/swiftui/sharelink) - SwiftUI sharing API
- [Apple Transferable Docs](https://developer.apple.com/documentation/coretransferable/transferable) - Data transfer protocol

## Dev Agent Record

### Agent Model Used

Gemini 2.5 Pro

### Debug Log References

- Build succeeded on iPhone 17 Pro Simulator
- All 5 ShareableImageTests passed
- 3 pre-existing failures in DeckBrowserViewTests (unrelated to Story 3.4)

### Completion Notes List

- Created `ShareableImage.swift` with `Transferable` protocol for PNG export
- Added `ShareSheetView` in `ResultScreen.swift` with image preview and ShareLink
- Integrated auto-presenting share sheet after image generation via `.sheet()` modifier
- Added `showShareSheet` state and cleanup in `onDismiss` handler (AC 3)
- ShareLink uses `ShareableImage` wrapper for lossless PNG sharing
- Created `ShareableImageTests.swift` with 5 unit tests for Transferable conformance

### File List

- [NEW] `Kape/Features/Summary/Logic/ShareableImage.swift`
- [NEW] `KapeTests/Features/Summary/ShareableImageTests.swift`
- [MODIFIED] `Kape/Features/Summary/Views/ResultScreen.swift`
- [NEW] `KapeTests/Features/Summary/ResultScreenShareTests.swift`
