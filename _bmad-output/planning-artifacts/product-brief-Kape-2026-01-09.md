---
stepsCompleted: [1, 2, 3, 4, 5]
inputDocuments: []
date: 2026-01-09
author: Ardian
project_name: Kape
---

# Product Brief: Kape!

## Executive Summary

**Kape!** ist ein virales iOS Party-Spiel, das das erfolgreiche "Heads Up!"-Spielprinzip für die albanische Diaspora kulturell adaptiert. Mit "Inside Jokes", kulturspezifischem Content und einem Freemium-Modell zielt die App darauf ab, viral in der albanischen Community zu wachsen.

**Timeline:** MVP Launch in unter 4 Wochen  
**Plattform:** iOS 17+ (SwiftUI)  
**Business Model:** Freemium mit In-App Purchases für Premium Content

---

## Core Vision

### Problem Statement

Die albanische Diaspora – Millionen Menschen weltweit – hat keinen kulturell relevanten Zugang zu Party-Spielen, die ihre einzigartigen Erfahrungen widerspiegeln. Existierende Apps wie "Heads Up!" bieten generische Begriffe, die keine emotionale Resonanz erzeugen und die spezifischen "Inside Jokes" der Diaspora-Erfahrung nicht abbilden.

### Problem Impact

- **Kulturelle Lücke:** Keine Party-Spiele verstehen die Diaspora-Erfahrung (Grenzübertritt, Western Union-Besuche, "Gurbet"-Leben, Baustellenjobs)
- **Verpasste Viralität:** Ein Markt von Millionen albanischstämmiger Menschen weltweit bleibt unerschlossen
- **Emotionale Verbindung fehlt:** Generische Begriffe schaffen keine Lacher wie kulturell relevante Referenzen

### Why Existing Solutions Fall Short

| Lösung | Problem |
|--------|---------|
| **Heads Up!** | Generischer Content, keine albanischen Begriffe, keine kulturelle Relevanz |
| **Andere Party-Apps** | Übersetzungen statt echter kultureller Adaptation |
| **Physische Kartenspiele** | Nicht mobil, nicht viral teilbar, keine Updates möglich |

Die Konkurrenz versteht nicht, was die albanische Diaspora zum Lachen bringt.

### Proposed Solution

**Kape!** liefert:

1. **Motion-controlled Gameplay:** Handy an die Stirn, Nicken = Richtig, Kopf in Nacken = Passen
2. **Kultureller Content:** 
   - "Mix Shqip" (Allgemein Free)
   - "Ushqim & Sofra" (Essen Free)  
   - "Gurbet/Diaspora" (Viral-Key Free)
   - "VIP & Muzikë" (Paid IAP)
3. **High-Energy Design:** Dark Mode, Neon-Akzente (Rot/Schwarz), Slang-Labels
4. **Technische Exzellenz:** Zero-Latency Audio, Sensor Fusion (CoreMotion), Haptic Feedback
5. **Privacy First:** Offline-only, keine Datenerhebung

### Key Differentiators

| Differentiator | Vorteil |
|----------------|---------|
| 🇦🇱 **Albanische Inside Jokes** | Emotionale Resonanz, die Viralität antreibt |
| 🔥 **"Gurbet" Deck** | Der virale Trigger – jeder Albaner kennt diese Erfahrungen |
| ⚡ **Sensor Fusion** | Präzise Nickenerkennung mit Debounce-Logic |
| 🎨 **High-Energy Design** | Jugendsprache ("Bishë", "Legjendë") + Neon-Ästhetik |
| 🔒 **Privacy First** | Offline-only = Vertrauen in der Community |

---

## Target Users

### Primary User: "The Diaspora Kid" 🇦🇱

**Persona: Ardi, 22, lebt in Zürich**

| Attribut | Details |
|----------|---------|
| **Alter** | 16-35 Jahre |
| **Standort** | DACH-Region (DE/AT/CH) |
| **Sprache** | Bilingual – Code-Switching zwischen Deutsch und Albanisch |
| **Tech-Status** | iPhone-Besitzer, "Tech-Beauftragter" der Familie |
| **Rolle** | Lädt Apps, zeigt Eltern WhatsApp, richtet das Smart-TV ein |

**Motivation:**
- Will Stimmung auf Partys bringen
- Zelebriert kulturelle Identität ("Stolz auf die Wurzeln")
- Sucht Verbindung zwischen zwei Welten (Diaspora-Erfahrung)

**Day in the Life:**
> Ardi arbeitet unter der Woche in Zürich. Am Wochenende fährt er zur Familie oder trifft Freunde in der Shisha-Bar. Er scrollt TikTok und teilt albanische Memes. Bei Familienfeiern ist er derjenige, der das Spiel rausholt und alle zum Lachen bringt.

### Play Contexts: "Die Ndenja" 🎉

#### Szenario A: Friends Mode
| Setting | Beispiele |
|---------|-----------|
| **Orte** | Shisha-Bar, Café, Auto-Fahrt |
| **Atmosphäre** | Entspannt, viel Slang, "unter uns" |
| **Bevorzugter Content** | Gurbet-Deck, Inside Jokes, Jugendsprache |
| **Spieler** | 3-6 Freunde, alle 18-30 |

#### Szenario B: Family Mode
| Setting | Beispiele |
|---------|-----------|
| **Ort** | Familienfeier, nach dem Essen |
| **Atmosphäre** | Generationen-übergreifend, 👵 bis 👶 |
| **Spieler** | Eltern, Onkel, Tanten (40-60 Jahre) spielen mit |
| **Design-Implikation** | ⚠️ Große Schrift für ältere Mitspieler! |

### Geographic Focus 🌍

| Priorität | Region | Grund |
|-----------|--------|-------|
| 🥇 **Primär** | DACH (DE/AT/CH) | Höchste Kaufkraft + höchste Diaspora-Dichte |
| 🥈 **Sekundär** | USA, UK | Große albanische Communities |
| 🥉 **Saisonal** | Balkan (KS/AL/MK) | Sommerurlaub = Peak-Nutzung |

### Secondary Users: "The Outsider" 👫

**Persona: Lisa, 24, Ardis Freundin (nicht-albanisch)**

- Versucht die Begriffe zu verstehen
- Fragt: "Wie spricht man 'Qebapa' aus?"
- Sorgt für zusätzliche Lacher durch kulturelle "Crashs"
- **Implikation:** Begriffe auf Albanisch, aber universell erklärbar

### User Journey

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. DISCOVERY                                                    │
│    "Ardi sieht TikTok von Kape!, tagged seinen Cousin"          │
├─────────────────────────────────────────────────────────────────┤
│ 2. DOWNLOAD                                                     │
│    "Lädt App, probiert Free-Decks alleine aus"                  │
├─────────────────────────────────────────────────────────────────┤
│ 3. FIRST PLAY (Aha-Moment!)                                     │
│    "Auf der Familienfeier: Onkel erklärt 'Bakllava' – alle      │
│     lachen sich kaputt"                                         │
├─────────────────────────────────────────────────────────────────┤
│ 4. VIRAL LOOP                                                   │
│    "Cousin lädt die App auch, teilt Video auf Instagram"        │
├─────────────────────────────────────────────────────────────────┤
│ 5. MONETIZATION                                                 │
│    "Ardi kauft VIP & Muzikë Deck für 2,99€"                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Success Metrics

### North Star Metric ⭐
**Viral User Acquisition (Downloads)**
- **Ziel:** 10.000 organische Downloads im ersten Monat
- **Strategie:** "Network Effect" – Jeder Nutzer bringt ~5 neue durch Social Sharing
- **Launch-Erfolg:** Ein TikTok-Video von Fremden sehen, die Kape! spielen.

### Business Objectives
1. **Reichweite vor Umsatz:** Fokus in Monat 1 liegt rein auf Verbreitung.
2. **Impulskauf-Monetarisierung:** 
   - Preis: 2,99€ (weniger als ein Red Bull in CH)
   - Strategie: 3 Free Decks (Over-delivery) senken Hürde, VIP-Deck monetarisiert Super-Fans.
3. **Technische Exzellenz:** App muss auf Partys sofort funktionieren ("Instant Fun").

### Key Performance Indicators (KPIs)

#### 1. Viralität & Growth
| KPI | Target | Messung |
|-----|--------|---------|
| **Downloads** | 10.000 (Monat 1) | App Store Connect |
| **Share Rate** | > 10% | Jeder 10. Spieler teilt Ergebnis |
| **K-Faktor** | > 1.0 | Jeder Nutzer bringt >1 neuen Nutzer |

#### 2. Engagement (The Fun Factor)
| KPI | Target | Messung |
|-----|--------|---------|
| **Completion Rate** | > 80% | Spiele, die bis zum Timer-Ende laufen |
| **Session Length** | > 5 Min | Indikator für mehrere Runden |

#### 3. Technical Performance (The Vibe Killers)
| KPI | Constraint | Messung |
|-----|------------|---------|
| **False Positives** | < 5% | Vertrauen in Motion-Detection |
| **App Startzeit** | < 2 Sek | "Instant" Spielbereitschaft |
| **Crash Rate** | < 0.1% | Keine Abstürze im Spiel! |

#### 4. Monetization (Secondary)
| KPI | Target | Messung |
|-----|--------|---------|
| **Conversion Rate** | > 2% | Kauf von "VIP & Muzikë" |

---

## MVP Scope

### Core Features (V1.0) 📦

#### 1. Game Mechanics (The Engine)
- **Timer:** 60s (Standard) & 30s ("Quick Game" Mode)
- **Motion Control:** Tilt Down (Richtig) / Tilt Up (Passen)
- **Feedback:** Haptic Feedback bei jeder Aktion (Erfolg/Pass)
- **Review:** "Review & Skip" Screen nach der Runde (Lerneffekt)

#### 2. Content System (No Backend)
- **Local Data:** JSON-basiertes Deck-Management
- **Decks:** 
  - 3x Free (Mix, Essen, Gurbet)
  - 1x Paid (VIP & Muzikë)
  - "Forbidden Words" Support im Datenmodell

#### 3. Minimal Viable Design (UI)
- **Landscape Only:** Erzwungene Orientierung für Gameplay
- **Accessibility:** Große, gut lesbare Schrift (für ältere Spieler)
- **High Energy:** Dark Mode mit Neon-Akzenten

### Out of Scope for MVP 🚫
- **Video Recording:** Zu komplex & Privacy-Risiko für V1.0
- **Online Multiplayer:** Killt die Timeline (Backend nötig)
- **Custom Decks:** Moderations-Aufwand zu hoch
- **Android Version:** Fokus 100% auf iOS Quality

### MVP Success Criteria ✅
- **Technical:** Launch im App Store ohne Critical Bugs
- **Functional:** Sensor-Erkennung funktioniert bei >95% der Spieler intuitiv
- **Timeline:** Submission bei Apple in < 30 Tagen

### Future Vision 🔮
- **V1.1:** Video Recording & Sharing (nach technischer Stabilisierung)
- **V1.2:** "Community Decks" (User reichen Begriffe ein)
- **V2.0:** "Battle Mode" (Team vs. Team Score Tracking)
