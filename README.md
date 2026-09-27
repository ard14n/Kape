# Kape! 🇦🇱

An Albanian-language party game: act out or explain a secret word while everyone else guesses. Read it privately, hide it and put the phone down.

## Playing

1. Choose a category and a play style, then **Luaj së bashku** (play together) or **Turne me pikë** (tournament).
2. Pass the phone to the next performer. **Shiko fjalën** reveals their word privately.
3. **Gati – fshihe fjalën** hides it and gives three seconds to put the phone down.
4. Act out or explain the word according to the selected rule, for up to 60 seconds. Mark **U gjet** (guessed) or **Nuk u gjet** (not guessed).
5. Correct the result if necessary, then pass the phone to the next person.

The introductory instructions are available again from the question-mark button. The app uses the Kuq e Flakë palette: a dark background, red accents, warm yellow actions, neon outlines and a glowing timer. Found and not-found results use green and red. The app has a dedicated dark appearance. iPhone play uses portrait orientation.

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

The free **Sa për fillim** starter contains 57 everyday actions and animals. Eleven themed categories contain another 395 cards: Mix Shqip, Diaspora, Muzikë, Sport, Humor & TV, Social Media, Dasma & Tradita, Fëmijëria, Nana shqiptare, Historia and Politikë. All twelve categories and 452 cards are free and work with every play style. The Albanian wording uses the Gheg dialect of Kosovo. A tournament needs one card per turn; setup explains when a category cannot cover the selected number of players and rounds.

The September 12 revision removed 24 distinct cards, renamed Diaspora and the starter, corrected selected card text and replaced the app icon with the selected party-card design. Retained card IDs are stable. Existing saved games keep their original card snapshot; start a new game to use the revised catalog.

### Mixed categories (iOS 1.2)

**Krejt kategoritë** is the initial selection at the top of the category picker and plays with all twelve categories. The current catalog contributes 443 distinct words from 452 cards; words shared by several categories appear only once. Individual categories remain available, and continuing a saved game preserves its original category.

Each reveal or replacement randomly chooses an available category other than the previous one. Categories have equal selection probability regardless of their remaining size. If only one category still has words, play continues from it. The source category is shown only during private reading, then hidden together with the word.

Words are consumed when revealed, including skipped, missed and timed-out words. The same history applies to all players and rounds in a game, survives saving and relaunching, and is reset only by starting a new game (including Play Again). Capitalization, whitespace, Unicode composition and curly/straight apostrophes do not create separate words; distinct Albanian letters remain distinct. Single-category games use the same duplicate protection. Older saves infer seen and skipped words from their remaining pool. Exhausted pools end explicitly without refilling or declaring an incomplete tournament winner.

## Free release and saved games

The first public release has no purchases, subscription or advertising. The active Charades flow does not initialize StoreKit or check entitlements. Legacy store code and its regression tests remain unconnected; old saved games with a paid-category flag remain readable and playable.

Game content is bundled. A current game is stored locally, including completed results and the paused turn. Leaving the app pauses the timer and hides private content; resuming requires a tap. The app-switcher cover is synchronous UIKit UI. The display stays awake only during countdown and acting. Settings provide sound, help and privacy links.

Store/account, privacy/support disclosures, real-device behavior and distribution are separate release checks. A simulator pass is not a real StoreKit purchase or App Store approval.

## Privacy declaration

`Kape/Kape/PrivacyInfo.xcprivacy` declares app-local UserDefaults storage (CA92.1) and monotonic timer calculations using systemUptime (35F9.1). The release bundle includes the manifest. It declares no developer data collection or tracking for the current implementation. Reassess these declarations if networking, SDKs or data processing change. A public privacy policy and an accessible in-app link remain separate App Store requirements.

## Development

- iOS 17+, SwiftUI, Observation, AVFoundation.
- Development checks used Xcode 26.5, Swift language mode 5. The shared `Kape` scheme includes both test targets and archives in Release configuration.
- App Store archives require a supported **released macOS and Xcode combination**. Xcode 26.5 on macOS 27 beta produced build 18, which Apple rejected with ITMS-90111 despite successful upload and initial review submission. Do not submit archives from that host or edit their build-provenance metadata.
- The successful first release used Xcode Cloud with Xcode 26.6 (17F113) on macOS 26.6.2 (25G83), App Store Connect distribution preparation and build 20. Version 1.1 (22) was released on September 13. The iOS 1.2 update adds mixed categories as the default selection and prevents repeated words within a game. Its source build number is prepared as 24. Xcode Cloud replaces the build number with its run counter; verify the current Apple maximum and Cloud counter before starting the next run. The same App Store-eligible build is intended for internal TestFlight and the subsequent App Store update. Do not use an Internal Only workflow for that candidate.
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
