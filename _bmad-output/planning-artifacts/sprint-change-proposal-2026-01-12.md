# Sprint Change Proposal: Missing Navigation Flows

**Date:** 2026-01-12
**Author:** PM Agent (John)
**Trigger:** User Feedback / Usability Defect

## 1. Issue Summary
A "Dead End" was identified in the user flow on the `ResultScreen` and `LeaderboardView`. Once a game or tournament ends, the user is forced to either "Play Again" or "Share", with no option to return to the Main Menu without killing the app. This was an intentional "Viral Loop" design choice that negatively impacts usability.

## 2. Impact Analysis
*   **Epics Affected:**
    *   **Epic 3 (Social & Viral):** `ResultScreen` requires a secondary exit action.
    *   **Epic 6 (Tournament):** `LeaderboardView` requires a close/exit action.
*   **Artifacts Affected:**
    *   **Epics:** Acceptance criteria for Story 3.2 and Story 6.3 need updates.
    *   **UX Specification:** The "Infinite Loop" pattern needs to be softened to allow user control.
*   **Technical Impact:** minor UI changes (adding buttons), no major architectural shifts.

## 3. Recommended Approach & Rationale
**Approach:** Direct Adjustment (Incremental).
**Rationale:** The fix is low-effort and high-value. It corrects a frustrating usability issue without compromising the viral loop significantly, provided the "Exit" buttons are secondary/less prominent than "Play Again".

## 4. Detailed Change Proposals

### Epic 3: Result Screen (Story 3.2)
**Modification to Acceptance Criteria:**
```diff
  **And** the "Play Again" button must be the most prominent Element
  **And** it must have a "Share" button
+ **And** It must have a "Home" / "Exit" button (Small, Secondary) to return to the main menu
```

### Epic 6: Tournament Leaderboard (Story 6.3)
**Modification to Acceptance Criteria:**
```diff
  **And** show a "New Tournament" button to restart with same or new players
  **And** allow sharing the "Podium" view to social media
+ **And** It must provide a "Close" option to exit the tournament and return to main menu
```

### UX Specification
**Modification to Patterns:**
```diff
- *   **The "Infinite Loop" (TikTok):** "Play Again" isn't a question; it's the default state.
+ *   **The "Infinite Loop" (TikTok):** "Play Again" is the default highly-prominent state, but a secondary "Exit" path ensures user control.
```

## 5. Implementation Handoff
*   **Scope:** Minor.
*   **Route To:** Development Team (via Action Items or direct Story update).
*   **Success Criteria:** User can navigate from Result Screen back to Main Menu.

---
**Approval Status:** Pending User Review
