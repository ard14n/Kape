# Lokale Stabilisierung vom 05.09.2026

Dieser Entwicklungsstand bereitet die Abnahme auf einem echten iPhone vor. Er ist keine App-Store-Freigabe.

## Aenderungen

- Bewegung: Kalibrierung und Kippgesten verwenden den geraetefesten Schwerkraftvektor. Beide Landscape-Seiten werden beruecksichtigt; Portrait, flach liegende Geraete und ungueltige Messwerte werden bei der Kalibrierung abgelehnt.
- Pause/Unterbrechung: neue Kalibrierung vor dem Fortsetzen, pausierte Zeit wird nicht abgezogen. Verlassen einer Runde stoppt Sensor und Tasks; Abschluss-Callbacks erfolgen einmal.
- Folgerunden: eigener Eingabekanal pro Runde, keine alten Countdown-Ereignisse, Ergebnis- und Spielansicht wechseln nach abgeschlossenem Schliessen der vorherigen Ansicht.
- Store: Stream wird synchron registriert, erneutes Laden unterbricht den Listener nicht, keine dauerhafte starke Referenz vom Listener auf das ViewModel. Ein Store-Service gehoert genau einem ViewModel.
- Aeltere iOS-Versionen: explizite nichtisolierte Destruktoren vermeiden den reproduzierten Swift-Runtime-Fehler #88036. Die Aenderung greift nicht auf Actor-Zustand aus dem Destruktor zu.
- Bedienbarkeit: Kalibrierung ist abbrechbar und scrollbar; obere und untere Bedienbereiche reservieren Platz. Kategorienbeschreibungen duerfen bei Accessibility-Schrift vollstaendig umbrechen.

## Reproduzierbare Pruefung

Xcode 26.5, iOS-26.2-Simulatoren. Genau einen Simulator gleichzeitig starten. Eine vorhandene Simulator-ID mit `xcrun simctl list devices available` waehlen.

```sh
xcodebuild -project Kape/Kape.xcodeproj -scheme Kape \
  -destination 'platform=iOS Simulator,id=SIMULATOR_ID' \
  -derivedDataPath /tmp/kape-qa \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -only-testing:KapeTests -only-testing:KapeUITests/SmokeTests \
  -only-testing:KapeUITests/UILayoutTests CODE_SIGNING_ALLOWED=NO test

xcodebuild -project Kape/Kape.xcodeproj -scheme Kape \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/kape-release CODE_SIGNING_ALLOWED=NO build
```

Die UI-Smokes starten den Prozess explizit mit `--kape-ui-tests`: synthetischer Schwerkraft-Sensor, kurze Testdauer. Dieser Einstieg wird nur unter DEBUG kompiliert. Er ersetzt weder echte Kippbewegungen noch StoreKit-Sandbox, Audio- oder Haptikabnahme.

Auf iPhone 17 Pro, 17 Pro Max und SE 3 jeweils Kategorie waehlen, kalibrieren, pausieren, fortsetzen, beenden, Ergebnis verlassen und zweite Runde pruefen. Mindestens ein Profil mit maximaler Dynamic-Type-Schrift und beiden System-Farbschemata pruefen. Das App-Design verwendet weiterhin bewusst Dark Mode.

## Vor einer Veroeffentlichung offen

- Eigene echte iPhone-Abnahme: beide Querlagen, mehrere Kippgesten mit Neutral-Rueckkehr, Ton, Haptik, Sperren/Appwechsel, zweite Runde.
- Turnier-UI und mehrfache Spielerwechsel auf dem Geraet. Insbesondere Auswahl aus kostenfreien/freigeschalteten Decks im Turnier gesondert pruefen; der bestehende Turniercode waehlt noch aus allen Decks.
- Echte StoreKit-Sandbox-Pruefung fuer Kauf, Abbruch, ausstehende Zahlung, Wiederherstellung und Entzug. Keine echten Kauefe im lokalen Test.
- Albanische Sprache/Inhalte und Asset-Rechte, aktuelle Support-/Datenschutzseiten, Bundle-ID/Signierung, Store-Metadaten, Produkt-/Preisentscheidung und persoenliche Veroeffentlichungsfreigabe.
