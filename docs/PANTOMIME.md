# Kape: Spielweisen und lokale Prüfung

Stand: 05.09.2026. Native Erweiterung des Korall-Redesigns um Erklären und freie Wahl.

## Spielprinzip

Die aktive Person liest einen geheimen Begriff, verbirgt ihn mit „Gati – fshihe fjalën“ und hat drei Sekunden, das Handy abzulegen. Die Gruppe hat anschließend bis zu 60 Sekunden zum Raten. Ein Begriff wird einmal bewertet; vor der Weitergabe kann das Ergebnis korrigiert werden. Unbekannte Begriffe lassen sich vor dem Timer ohne Punkt-/Zugverlust ersetzen und wiederholen sich innerhalb derselben Sitzung nicht.

Vor Spielbeginn wird eine gemeinsame Regel gewählt:

| Albanische Auswahl | Regel |
| --- | --- |
| Zgjedhje e lirë | Standard: pro Begriff selbst zwischen Gesten und Erklären entscheiden, ohne zusätzliche Auswahlmaske. |
| Pantomimë | Nur Gesten, ohne Sprechen oder Geräusche. |
| Shpjegim | Umschreiben, ohne den Begriff oder Teile davon zu nennen. |

Die Regel wird in Übergabe, Geheimansicht und Spiel angezeigt. Die Einführung erklärt beide Spielweisen und freie Wahl; sie wird nach dem Update einmal neu gezeigt und bleibt über die Hilfe erreichbar. Kategorien sind unabhängig von der Spielweise. Der Starter „Për të filluar“ enthält 60 Begriffe, die sieben ursprünglichen Kategorien weitere 270. Seine interne ID pantomime bleibt aus Kompatibilitätsgründen erhalten.

Gemeinsames Spiel sammelt Gruppentreffer. Das Personenturnier umfasst 2–5 Personen und 1, 3 oder 5 Züge je Person. Bei erratenem Begriff erhält die aktive Person einen Punkt, sonst null. Gleiche Punktzahlen teilen denselben Rang. Ein vorzeitig leerer Wortpool führt zu einem unvollständigen Turnier ohne Siegerbehauptung.

## Umsetzung

Features/Charades enthält den aktuellen Einstieg, Regeln, Kategorien, Einstellungen, Kaufansicht, Turnier, Spielansicht und Zustandsautomaten. Die alten Motion-, Turnier- und Neon-Komponenten bleiben unverbundener Altcode; ContentView öffnet ausschließlich den neuen Ablauf.

- Spielweise und Wertungsmodus sind getrennte Typen. Die Regel einer laufenden Sitzung ist unveränderlich; eine spätere Startpräferenz ändert sie nicht.
- Snapshot v1 erhält ein optionales playStyle-Feld. Fehlendes Feld alter Archive bedeutet Pantomime. Neue Sitzungen speichern eine ausdrückliche Regel, unbekannte Enum-Werte werden abgelehnt.
- Der MainActor-Automat verarbeitet genau ein Ergebnis pro Zug. Punkte werden aus Ergebnissen berechnet; Korrekturen sind nur vor der Weitergabe möglich.
- Ein abbrechbarer View-Task verwendet eine monotone Deadline. Inaktivität pausiert die Uhr; Wiederaufnahme erfordert eine ausdrückliche Eingabe.
- CharadesPrivacyCover ist am Elternview des Spiels montiert und verdeckt das Fenster bei Inaktivität synchron. Der Begriff wird ausschließlich in der privaten Lesephase gezeigt; eine Ergebniskarte darf den gespielten Begriff nennen.
- Store-Zugang wird vor Ausgabe einer VIP-Karte und beim erneuten Lesen eines gespeicherten VIP-Begriffs geprüft. Ein schon begonnener Zug darf nach Zugangsverlust beendet werden; weitere VIP-Ausgaben bleiben gesperrt.
- iPhone-Hochformat, System-/Hell-/Dunkel-Darstellung. Bei normaler Schrift stehen Starttasten unten, bei Accessibility-Schrift folgen sie der Auswahl im Scrollbereich. Spiel-/Ergebnistasten bleiben unten. Bei großen Accessibility-Schriften oder wenig vertikalem Platz entfallen die dekorativen Starttexte zugunsten der Auswahl. Alle Einstellungen und Regeln bleiben scrollbar erreichbar.
- Keine zusätzliche Spracheingabe, Bewegungserkennung oder Abhörfunktion. Die Gruppe setzt die Regeln selbst um.

Bei Prozessende ohne vorherigen Inaktivitäts-Callback ist nur der letzte gespeicherte Zustandswechsel wiederherstellbar. Reale App-Vorschau, Haptik, Sperre und StoreKit bleiben eigene Geräteprüfungen.

## Prüfung

275/275 Unit-Tests bestanden. Die zehn UI-Fälle sind auf iPhone 17 Pro, iPhone 17 Pro Max mit maximaler Dynamic-Type-Stufe sowie iPhone SE 3 abgedeckt. Nach konkreten Befunden wurden betroffene Fälle gezielt wiederholt; initiale Fehlversuche bleiben dokumentiert. Release-iPhoneOS-Build erfolgreich und unsigniert.

Die 21 CharadesSessionTests prüfen unter anderem freie Wahl und feste Regeln in beiden Wertungsmodi, Migration eines JSON-Archivs ohne Spielweise, fehlerhafte Archive, private Wiederaufnahme, VIP-Gates, Zeitgrenzen, Doppeltaps, korrigierbare Ergebnisse, 25 gleichmäßig verteilte Turnierzüge und geteilte Ränge. Ein zusätzlicher Randfall stellt sicher, dass beim freiwilligen Gruppenabschluss ein überholter VIP-Hinweis verschwindet.

Die zehn UI-Fälle bedienen die tatsächliche Oberfläche: Einführung und Hilfe, alle Spielweisen, gemeinsame Runde, Turnier mit Gleichstand, fünf Personen, Ergebniskorrektur, Hintergrund/Neustart mit gespeicherter Erklärregel und Punkten, Zeitende sowie Hell/Dunkel und simulierte VIP-Kauf-/Restore-Aktionen. Screenshots und Accessibility-Bäume werden als Anhänge gespeichert. Debug verwendet den bestehenden Mock-Store, Release StoreKit 2. Testargumente und verkürzte Zeiten sind nicht im Release-Binary enthalten.

~~~sh
xcodebuild -project Kape/Kape.xcodeproj -scheme Kape \
  -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_UDID' \
  -parallel-testing-enabled NO -resultBundlePath /tmp/Kape-Spielweisen.xcresult \
  CODE_SIGNING_ALLOWED=NO test

xcrun xcresulttool get test-results summary --path /tmp/Kape-Spielweisen.xcresult
xcrun xcresulttool export attachments --path /tmp/Kape-Spielweisen.xcresult \
  --output-path /tmp/Kape-Spielweisen-Images
~~~

## Gegenchecks und Grenzen

Regulärer Erstcheck, gezielter Diff-Schlusscheck und vollständiger Kerncheck über Claude Code, explizit opus, tatsächliches Antwortmodell claude-opus-5. Übersetzten VoiceOver-Wert und überholten VIP-Hinweis korrigiert. Ein vermuteter fehlender PrivacyCover wurde anhand des Elternviews widerlegt. Gesperrter VIP-Zugang mit dokumentiertem Speichern-/Verlassen-Weg ist keine unauflösbare Sackgasse; ein vorgeschlagener weiterer Aufdeckknopf wurde nicht ergänzt.

Visueller Erstcheck und gezielte Schlusschecks über Antigravity CLI, vor jedem Lauf agy models geprüft und explizit gemini-3.1-pro-high/high gesetzt. Konkrete Max-Befunde zu Wortumbrüchen und verdrängter Auswahl korrigiert; aktueller Schlusscheck bestätigt die behobenen Befunde. Aussagen aus Bildern sind auf diese Bilder begrenzt; die eigenen UI-Tests liefern den Funktionsnachweis.

Die früheren begrenzten Modellausfälle im Pantomime-Meilenstein bleiben historische Befunde; keine nachträgliche Umdeutung. Echte Gruppen-/Sprachabnahme, Inhalte, reale Geräte-/Kaufprüfung und Store-/Support-/Datenschutzvorbereitung stehen weiterhin aus. Kein Push, keine Veröffentlichung und keine App-Store-Verteilung in diesem Entwicklungsschritt.
