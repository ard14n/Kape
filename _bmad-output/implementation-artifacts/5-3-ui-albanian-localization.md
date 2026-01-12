# Story 5.3: UI Albanian Localization

**Epic:** 5 - Visual Experience Upgrade
**Status:** review

## User Story
**As a** Player,
**I want** the entire game interface to be in Albanian,
**So that** the experience feels fully authentic to the cultural theme.

## Context
The game content (deck cards) is already in Albanian, but the UI chrome (buttons, labels, alerts) is in English. This creates a disconnected experience for the target audience (Kosovo/Albanian diaspora).

## Acceptance Criteria

### 1. Buffer & Game Flow
| File | Current Text | Albanian Translation |
|---|---|---|
| BufferView.swift | "Place on Forehead" | "Vendose mbi Ballë" |
| GameScreen.swift | "Ready to Play" | "Gati për Lojë" |
| GameScreen.swift | "Waiting for game to start..." | "Duke pritur..." |
| GameScreen.swift | "RESUME" | "VAZHDO" |
| GameScreen.swift | "End Game" | "Përfundo Lojën" |
| GameScreen.swift | "Time's Up!" | "Koha Mbaroi!" |
| GameScreen.swift | "Score:" | "Pikët:" |

### 2. Deck Browser
| File | Current Text | Albanian Translation |
|---|---|---|
| DeckBrowserView.swift | "Loading Store..." | "Duke ngarkuar..." |
| DeckBrowserView.swift | "Choose Your Vibe" | "Zgjidh Viben" |
| DeckBrowserView.swift | "VIP Decks" | "Decks VIP" |
| DeckBrowserView.swift | "START GAME" | "FILLO LOJËN" |
| DeckBrowserView.swift | "OK" | "OK" |
| DeckBrowserView.swift | "Success" (alert) | "Sukses" |
| DeckBrowserView.swift | "Store" (alert) | "Dyqani" |

### 3. Settings
| File | Current Text | Albanian Translation |
|---|---|---|
| SettingsView.swift | "Purchases" | "Blerjet" |
| SettingsView.swift | "Restore Purchases" | "Rikthe Blerjet" |
| SettingsView.swift | "About" | "Rreth" |
| SettingsView.swift | "Version" | "Versioni" |
| SettingsView.swift | "Settings" | "Cilësimet" |
| SettingsView.swift | "Done" | "Mbyll" |

### 4. Purchase Flow
| File | Current Text | Albanian Translation |
|---|---|---|
| PurchaseSheetView.swift | "Unlock VIP Content" | "Zhblloko VIP" |
| PurchaseSheetView.swift | "PURCHASE" | "BLEJ" |
| PurchaseSheetView.swift | "Maybe Later" | "Mbase më vonë" |

### 5. Result Screen
| File | Current Text | Albanian Translation |
|---|---|---|
| ResultScreen.swift | "CORRECT" | "SAKTË" |
| ResultScreen.swift | "Play Again" | "Luaj Përsëri" |
| ResultScreen.swift | "Please try again." | "Provo përsëri." |
| ResultScreen.swift | "Share to..." | "Shpërndaj..." |
| ResultScreen.swift | "Share Your Score" | "Shpërndaj Rezultatin" |
| ResultScreen.swift | "Could not create image" | "Nuk u krijua imazhi" |
| ResultScreen.swift | "Try Again" | "Provo Përsëri" |
| ResultScreen.swift | "Cancel" | "Anulo" |

### 6. Store Alerts (StoreViewModel.swift)
| Current Text | Albanian Translation |
|---|---|
| "Failed to load store:" | "Gabim në ngarkim:" |
| "Purchase is pending approval." | "Blerja po pritet." |
| "Purchase failed:" | "Blerja dështoi:" |
| "Purchases restored successfully!" | "Blerjet u rikthyen!" |
| "Restore failed:" | "Rikthimi dështoi:" |

## Technical Notes
- Simple find-and-replace in each Swift file.
- No `.strings` localization files needed (single-language app).
- Preserve string interpolation (e.g., `\(score)` must remain).

## Tasks

- [x] Update BufferView.swift (1 string) <!-- id: 0 -->
- [x] Update GameScreen.swift (6 strings) <!-- id: 1 -->
- [x] Update DeckBrowserView.swift (6 strings) <!-- id: 2 -->
- [x] Update SettingsView.swift (6 strings) <!-- id: 3 -->
- [x] Update PurchaseSheetView.swift (3 strings) <!-- id: 4 -->
- [x] Update ResultScreen.swift (8 strings) <!-- id: 5 -->
- [x] Update StoreViewModel.swift (5 alert strings) <!-- id: 6 -->
- [x] Build and verify no compile errors <!-- id: 7 -->
- [ ] Visual verification on simulator <!-- id: 8 -->

## Dev Agent Record

### Review Follow-ups (AI)

### Debug Log

### Completion Notes

## File List
- Kape/Kape/Features/Game/Views/BufferView.swift
- Kape/Kape/Features/Game/Views/GameScreen.swift
- Kape/Kape/Features/Game/Views/DeckBrowserView.swift
- Kape/Kape/Features/Settings/Views/SettingsView.swift
- Kape/Kape/Features/Store/Views/PurchaseSheetView.swift
- Kape/Kape/Features/Summary/Views/ResultScreen.swift
- Kape/Kape/Features/Store/Logic/StoreViewModel.swift
