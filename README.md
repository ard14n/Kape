# Kape! 🇦🇱

A viral iOS party game designed for the Albanian diaspora - culturally adapted motion-controlled charades with authentic Albanian content.

## Overview

**Kape!** (Albanian slang for "Got it!") is a fast-paced party game that brings the popular "Heads Up!"-style gameplay to the Albanian community with culturally relevant content. Players hold their iPhone to their forehead while friends give clues - tilt down for correct guesses, tilt up to pass.

### Key Features

- 🎮 **Motion-Controlled Gameplay** - Tilt mechanics using CoreMotion sensor fusion
- 🇦🇱 **Authentic Albanian Content** - Cultural references, inside jokes, and diaspora experiences
- 🎨 **Neon Dark UI** - High-energy design with Albanian youth slang
- 🔊 **Haptic & Audio Feedback** - Immersive feedback system with <50ms latency
- 🏆 **Tournament Mode** - Multi-player competitive gameplay
- 💎 **VIP Content** - Premium decks available via in-app purchase
- 🔒 **Privacy First** - Fully offline, no data collection

## Project Structure

```
Kape/
├── Kape/                          # Main app source
│   ├── Core/                      # Core systems
│   │   ├── Audio/                 # Audio service (success.wav, pass.wav, warning.wav)
│   │   ├── Haptics/              # Haptic feedback service
│   │   ├── Motion/               # Motion detection (tilt gestures)
│   │   ├── DesignSystem/         # Colors, components, modifiers
│   │   └── Store/                # In-app purchase integration
│   ├── Features/                  # Feature modules
│   │   ├── Game/                 # Main gameplay (GameScreen, DeckBrowser)
│   │   ├── Tournament/           # Tournament mode
│   │   ├── Summary/              # Result screen with share functionality
│   │   ├── Store/                # Purchase flow
│   │   └── Settings/             # App settings
│   └── Data/                      # Data layer
│       ├── Models/               # Deck, Card, GameResult
│       ├── Services/             # DeckService, StoreService
│       └── Resources/            # decks.json, sound files
├── KapeTests/                     # Unit tests
├── KapeUITests/                   # UI automation tests
└── _bmad-output/                  # Project documentation
    ├── planning-artifacts/        # PRD, architecture, UX specs
    └── implementation-artifacts/  # Technical documentation
```

## Decks

### Free Decks
- **Mix Shqip** 🌟 - General Albanian culture (food, music, cities, celebrities)
- **Gurbet** ✈️ - Diaspora life experiences (work abroad, visas, homesickness)

### VIP Decks (In-App Purchase)
- **Muzikë** 🎵 - Albanian music (from tallava to pop)

## Technical Details

### Requirements
- **Platform:** iOS 17.0+
- **Language:** Swift 6.0 (strict concurrency)
- **Framework:** SwiftUI
- **Architecture:** MVVM with feature-based organization

### Key Technologies
- **CoreMotion** - Sensor fusion for tilt detection with debounce logic
- **AVFoundation** - Audio playback with .ambient session
- **StoreKit 2** - Modern in-app purchases
- **CoreHaptics** - Tactile feedback
- **SwiftData** - Tournament persistence

### Design System
```swift
// Colors
Color.trueBlack          // #000000 - Pure black background
Color.neonGreen          // #39FF14 - Success actions
Color.neonRed            // #FF073A - Warnings/Pass
Color.neonBlue           // #00F0FF - Accents

// Components
KapeCard                 // Card display with neon glow
NeonButton               // Primary action buttons
VibeBackground           // Animated gradient backgrounds
```

## Building the Project

### Prerequisites
```bash
# Xcode 15.0 or later
xcode-select --install
```

### Build & Run
```bash
# Clone the repository
git clone https://github.com/ard14n/Kape.git
cd Kape

# Open in Xcode
open Kape/Kape.xcodeproj

# Build and run (⌘R)
# Or via command line:
xcodebuild -project Kape/Kape.xcodeproj -scheme Kape -configuration Debug
```

### Testing
```bash
# Run unit tests
xcodebuild test -project Kape/Kape.xcodeproj -scheme Kape -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -project Kape/Kape.xcodeproj -scheme Kape -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:KapeUITests
```

## Game Mechanics

### Motion Detection
- **Correct (Tilt Down):** Pitch < -30° = Success feedback + next card
- **Pass (Tilt Up):** Pitch > 30° = Pass feedback + next card
- **Debounce:** 400ms cooldown prevents double triggers

### Game Flow
1. **Deck Selection** - Choose from available decks
2. **Buffer (3-2-1)** - Countdown with haptic pulses
3. **Gameplay (60s)** - Guess as many cards as possible
4. **Warning (<10s)** - Red glow + pulsing timer + haptic pulses
5. **Results** - Score display with share functionality

### Tournament Mode
- **4-player rounds** - Each player gets one turn
- **Leaderboard** - Real-time rankings
- **Persistence** - Resume interrupted tournaments

## Store Integration

### Products
- **VIP Deck Bundle** (`com.kape.vip`) - $2.99
  - Unlocks all premium decks
  - Non-consumable purchase
  - Restore purchases supported

### Testing In-App Purchases
Configure StoreKit testing in Xcode:
1. Select `StoreKitConfiguration.storekit` in scheme settings
2. Run app in simulator/device
3. Test purchase flow without actual charges

## Content Guidelines

All cards follow cultural authenticity principles:
- ✅ Recognizable within Albanian diaspora
- ✅ Appropriate for family/friends contexts
- ✅ Bilingual where natural (German loan words accepted)
- ❌ No politics, religion, or offensive content

## Localization

Currently supports:
- **Albanian** (Gheg/Kosovar dialect) - Primary UI language
- Interface text uses colloquial Albanian ("Kape!", "Bishë", "Legjendë")

## Accessibility

- VoiceOver support with semantic labels
- Reduced motion support (disable card transitions)
- Dynamic Type for text scaling
- Persistent system overlays hidden during gameplay

## Performance

- **Target:** 60 FPS during gameplay
- **Audio Latency:** <50ms feedback response
- **Motion Latency:** <100ms from tilt to action
- **Memory:** <100MB typical usage

## Privacy & Security

- ✅ **No tracking** - Zero analytics or telemetry
- ✅ **Offline-first** - All content bundled locally
- ✅ **No accounts** - No sign-up required
- ✅ **Secure purchases** - StoreKit 2 transaction validation

## Contributing

This is a personal project by [@ard14n](https://github.com/ard14n). While not actively seeking external contributions, bug reports and feedback are welcome via GitHub Issues.

### Reporting Issues
Please include:
- iOS version
- Device model
- Steps to reproduce
- Expected vs actual behavior

## License

All rights reserved. This is proprietary software.

## Credits

**Developer:** Ardian Jahja ([@ard14n](https://github.com/ard14n))  
**Created:** January 2026

### Acknowledgments
- Sound effects: Custom recordings
- Design inspiration: Albanian diaspora culture
- Special thanks to the Albanian community for cultural validation

## Roadmap

### Planned Features
- [ ] Additional VIP decks (Movies, Sports, Albanian Celebrities)
- [ ] Social share enhancements (Instagram Stories, TikTok)
- [ ] Multiplayer modes (Pass & Play enhancements)
- [ ] Custom deck creation
- [ ] Statistics tracking (personal records)

### Known Issues
See [GitHub Issues](https://github.com/ard14n/Kape/issues) for current bugs and feature requests.

---

**Made with ❤️ for the Albanian diaspora** 🇦🇱

