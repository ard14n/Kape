# Klassische Scharade – lokaler Entwicklungsstand

Datum: 05.09.2026. Nutzerfreigabe: warmes Korallrot ohne Glow, helle und dunkle Darstellung, verständliche Einführung sowie gleichzeitige Überarbeitung des Personenturniers.

## Verhalten

Die darstellende Person übernimmt das Handy, öffnet den geheimen Begriff und verbirgt ihn mit „Gati“. Nach drei Sekunden zum Ablegen beginnt die 60-Sekunden-Zeit. Die Person stellt den Begriff ohne Sprechen dar; die Gruppe rät. „U gjet“ und „Nuk u gjet“ erfassen das Ergebnis. Eine Korrektur ist bis zum nächsten Zug möglich.

Gemeinsamer Modus: ein Punkt für jede vom Kreis erratene Wortkarte. Turnier: 2–5 Personen und 1, 3 oder 5 Züge pro Person. Ein Begriff pro Zug, ein Punkt für die darstellende Person bei erratenem Begriff, sonst null. Gleiche Punktzahlen teilen denselben Rang. Bei vorzeitig leerem Wortpool wird kein vollständiger Turnierabschluss oder Sieger behauptet.

Neue kostenlose Kategorie „Pantomimë“: 60 Begriffe. Die sieben bisherigen Kategorien mit 270 Begriffen bleiben erhalten; die vorhandene VIP-Kategorie Muzikë wird auch im Turnier nur mit aktuellem Zugang freigegeben. Es gibt keinen Sensor-/Stirnmodus in der Navigation.

## Architektur und Unterbrechungen

Features/Charades enthält den neuen Einstieg, Einführung, Kategorienwahl, Einstellungen, Kaufansicht, Turnierkonfiguration, Spielansicht und den Zustandsautomaten. StoreKit-, Audio- und Haptikdienste werden weiterverwendet. ContentView öffnet ausschließlich den neuen Einstieg.

- Der MainActor-Automat bewertet einen Zug genau einmal; Punkte werden aus abgeschlossenen Ergebnissen berechnet.
- Ein abbrechbarer View-Task aktualisiert einen monotonen Zeitendpunkt. Unterbrechungen frieren die Restzeit ein.
- Wortanzeige existiert nur in der privaten Lesephase. Ergebniskarten dürfen den bereits gespielten Begriff zeigen.
- Bei Inaktivität verdeckt UIKit das Fenster synchron; zugleich wechselt der Automat in Pause.
- Lokaler, versionierter Spielstand; Wiederaufnahme erfordert einen ausdrücklichen Tastendruck und beginnt verdeckt. Kaufrechte werden aus dem Store-Dienst gelesen.
- Bei einem Prozessende ohne vorherigen Unterbrechungs-Callback ist nur der letzte gespeicherte Zustandswechsel wiederherstellbar.
- Display-Wachhalten nur während Countdown und Darstellung, Rücksetzung beim Verlassen und bei Inaktivität.
- iPhone im Hochformat. Großschrift erhält verkürzte, weiterhin skalierende Spielhinweise; Timer und Wertung haben Vorrang. Einführung und Spielaktionen stehen in einem eigenen unteren Bedienbereich.

Die alten Motion-, Turnier-, Ergebnis- und Neon-Komponenten sind noch als unverbundener Altcode vorhanden. Ihre bestehenden Unit-Tests bleiben als Regression erhalten. Die alten UI-Suiten für die entfernte Navigation wurden durch CharadesUITests ersetzt; es wird kein geheimer Testzugang zum alten Spiel eingebaut.

## Prüfung

Finaler lokaler Stand: 271/271 Unit-Tests und 24/24 UI-Prüfungen (acht pro Geräteprofil), jeweils ohne Überspringen; Release-iPhoneOS-Build erfolgreich.

Die fachlichen Tests in CharadesSessionTests prüfen unter anderem doppelte Wertung, Korrekturfenster, 25 gleichmäßig verteilte Turnierzüge, Gleichstände, Wortverbrauch, Zeitende, Pause, verdeckte Wiederherstellung, lokale Speicherung, VIP-Sperre und Entzug während eines Zugs. Hinzu kommt die Unterscheidung zwischen erfolgreicher Store-Synchronisierung und tatsächlich wiederhergestelltem VIP-Zugang.

CharadesUITests bedient ausschließlich die echte neue Oberfläche. Die Fälle decken Einführung/Hilfe, geheimen Spielzug, Ergebniskorrektur, Hintergrund und Neustart, Timerende, Turnierabschluss, fünf Personen mit Entfernen/Hinzufügen, Hell/Dunkel sowie das simulierte VIP-Angebot ab. Screenshots und Accessibility-Bäume werden als Testanhänge gespeichert.

~~~sh
xcodebuild -project Kape/Kape.xcodeproj -scheme Kape \
  -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_UDID' \
  -parallel-testing-enabled NO -resultBundlePath /tmp/Kape-Pantomime.xcresult \
  CODE_SIGNING_ALLOWED=NO test

xcrun xcresulttool get test-results summary --path /tmp/Kape-Pantomime.xcresult
xcrun xcresulttool export attachments --path /tmp/Kape-Pantomime.xcresult \
  --output-path /tmp/Kape-Pantomime-Images
~~~

Profile nacheinander: iPhone 17 Pro, iPhone 17 Pro Max mit maximaler Dynamic-Type-Stufe, iPhone SE (3. Generation). Debug-Testargumente und verkürzte Testzeiten sind mit #if DEBUG auf Entwicklungsbuilds beschränkt. Debug-Käufe und -Wiederherstellungen sind Mock-Aktionen; der Release-Dienst bleibt StoreKit 2.

Textkontraste der verwendeten Hauptfarben rechnerisch geprüft: Primärbutton hell 6,34:1, dunkel 8,44:1; zwölf Text-/Flächenpaare jeweils mindestens 5,76:1. Dies ist keine vollständige Barrierefreiheitsabnahme.

## Gegenchecks und Grenzen

Regulärer Erstcheck: Claude Code, gesetzt opus, tatsächliches Antwortmodell claude-opus-5. Wertungs- und Wiederaufnahme-Risiken wurden berücksichtigt.

Regulärer Code-Schlusscheck: Claude Code nach 110 Sekunden ohne abgeschlossene Antwort; vorgesehener Copilot-CLI-Fallback mit explizitem claude-opus-5, high, ebenfalls nach 120 Sekunden ohne Antwort beendet. Dieser Schlusscheck ist offen und wird nicht als bestanden ausgegeben.

Visuelle Prüfung erfolgt getrennt über Antigravity CLI mit jeweils frisch geprüftem gemini-3.1-pro-high. Die eigene Renderprüfung hat ein fehlendes Symbol, die Platzierung der Einführungstaste sowie den bei maximaler Schrift teilweise verdeckten Timer korrigiert.

Der visuelle Schlusscheck ist offen: Antigravity erreichte nach 110 Sekunden das Zeitlimit; Copilot meldete Gemini 3.1 Pro Preview als nicht verfügbar. Im anschließend gelesenen aktuellen Copilot-Modellwähler war nur Gemini-Flash-Modelle (3.8, 3.7, 3.6 und 3.5) sichtbar. Kein anderer Modelltyp wurde stellvertretend eingesetzt. Eigene finale Renderprüfung und UI-Tests sind abgeschlossen.

Vor einer Veröffentlichung bleiben echte Gruppen-/Sprach- und Geräteabnahme, reale StoreKit-Prüfung, Inhaltsrechte und Store-/Support-/Datenschutzvorbereitung erforderlich. Keine Veröffentlichung, kein Push und keine App-Store-Verteilung in diesem Entwicklungsschritt.
