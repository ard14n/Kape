# Kape! 🇦🇱

An Albanian-language party game: act out or explain a secret word while everyone else guesses. Read it privately, hide it and put the phone down.

## Playing

1. Choose a category and a play style, then **Luaj së bashku** (play together) or **Turne me pikë** (tournament).
2. Pass the phone to the next performer. **Shiko fjalën** reveals their word privately.
3. **Gati – fshihe fjalën** hides it and gives three seconds to put the phone down.
4. Act out or explain the word according to the selected rule, for up to 60 seconds. Mark **U gjet** (guessed) or **Nuk u gjet** (not guessed).
5. Correct the result if necessary, then pass the phone to the next person.

The introductory instructions are available again from the question-mark button. The app uses a warm coral palette, follows the phone's light/dark appearance and supports an explicit appearance preference. iPhone play uses portrait orientation.

## Play styles

Choose one rule for the whole game. It applies to everyone, including in tournaments:

- **Zgjedhje e lirë — Free choice** (default): choose gestures or explanation for each word, without another screen or button.
- **Pantomimë — Pantomime:** gestures only, without speech or sounds.
- **Shpjegim — Explanation:** describe the word without saying it or parts of it.

The selected rule appears during handoff, private reading and play. A game keeps its rule when paused or restored. Older saved games without a play-style field retain pantomime; newly started games use the selected preference. The updated introduction is shown once and can always be reopened.

## Modes and scoring

- **Together:** take turns, collect one group point per guessed word, and finish when the group wants.
- **Tournament:** 2–5 people, with 1, 3 or 5 turns each. Each turn has one word. The performer gets one point when the group guesses, otherwise zero. There are no speed bonuses or negative points. Equal scores share a rank.
- A result can be changed until advancing to the next turn. Repeated taps do not add points.
- Unknown words can be replaced before starting the timer. They consume no turn and do not reappear in that game.
- If the word pool runs out before all tournament turns, the game explicitly reports an incomplete tournament without declaring a winner.

## Categories

The new free **Për të filluar** starter contains 60 actions, animals and everyday activities. The original seven categories and their 270 words remain: Mix Shqip, Gurbet, Muzikë, Sport, Humor & TV, Historia, Politikë. All eight categories are free and can be used with any play style. The current TestFlight gameplay was accepted by a real group, as confirmed by the owner on 5 September 2026.

## Free release and saved games

The first public release has no purchases, subscription or advertising. The active Charades flow does not initialize StoreKit or check entitlements. Legacy store code and its regression tests remain unconnected; old saved games with a paid-category flag remain readable and playable.

Game content is bundled. A current game is stored locally, including completed results and the paused turn. Leaving the app pauses the timer and hides private content; resuming requires a tap. The app-switcher cover is synchronous UIKit UI. The display stays awake only during countdown and acting. Settings provide sound, appearance, help and privacy links.

Store/account, privacy/support disclosures, real-device behavior and distribution are separate release checks. A simulator pass is not a real StoreKit purchase or App Store approval.

## Privacy declaration

`Kape/Kape/PrivacyInfo.xcprivacy` declares app-local UserDefaults storage (CA92.1) and monotonic timer calculations using systemUptime (35F9.1). The release bundle includes the manifest. It declares no developer data collection or tracking for the current implementation. Reassess these declarations if networking, SDKs or data processing change. A public privacy policy and an accessible in-app link remain separate App Store requirements.

## Development

- iOS 17+, SwiftUI, Observation, AVFoundation.
- Current verified toolchain: Xcode 26.5, Swift language mode 5.
- `Kape/Kape/Features/Charades/` owns the current UI and testable session state machine.
- `ContentView` starts `CharadesHomeView`; there is no motion/forehead mode in navigation.
- Legacy Game, Tournament, Summary and neon components remain as unconnected code with regression tests. Removing that legacy code is a separate cleanup.
- Original audio and haptic services are reused; legacy Store services are not connected to the current UI.

```sh
xcodebuild -project Kape/Kape.xcodeproj -scheme Kape \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build

xcodebuild -project Kape/Kape.xcodeproj -scheme Kape \
  -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_UDID' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

Use one simulator at a time. Required profiles: iPhone 17 Pro, iPhone 17 Pro Max and iPhone SE (3rd generation); include maximum Dynamic Type and light/dark appearance. The current UI suite is `CharadesUITests`. It replaces tests that navigated the removed motion flow. Existing business-logic tests remain, alongside `CharadesSessionTests` for privacy, timer, scoring, persistence and migration of formerly restricted categories.

See [Implementation and QA](docs/PANTOMIME.md) for the current evidence and [earlier stabilization](docs/STABILISIERUNG.md) for the historical motion-based milestone.

## Ownership

Personal project by Ardian Jahja ([@ard14n](https://github.com/ard14n)), created January 2026. All rights reserved; proprietary software. Feedback can be reported through [GitHub Issues](https://github.com/ard14n/Kape/issues).
