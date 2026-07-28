# RecoveryLens – Projektkontext

Stand: 28. Juli 2026

## Produktziel

RecoveryLens ist eine iOS-App, die ausgewählte Apple-Health-Daten der letzten
Tage verständlich und datensparsam zusammenfasst. Die App unterstützt die
persönliche Reflexion, erstellt aber keine medizinische Bewertung, Diagnose
oder konkrete Gesundheitsempfehlung.

Der Portfolio-Fokus liegt auf HealthKit, Datenschutz, nachvollziehbarer
Datenaufbereitung, Swift Charts, SwiftData und testbarem State-Management.

## Zielgruppe

Menschen, die Schritte, aktive Energie, Schlaf und Trainingseinheiten aus
Apple Health in einer ruhigen Wochenübersicht betrachten und optional einen
manuellen Tages-Check-in ergänzen möchten.

## MVP 0.1

- verständlicher Einstieg vor der HealthKit-Berechtigungsanfrage
- ausschließlich lesender HealthKit-Zugriff auf:
  - Schritte
  - aktive Energie
  - Schlafanalyse
  - Trainingseinheiten
- heutige Werte für Schritte, aktive Energie und Schlafdauer
- Trainingseinheiten der letzten sieben Kalendertage
- Wochenübersicht mit Swift Charts
- ein manueller Check-in pro Kalendertag
- lokale Speicherung eigener Check-ins mit SwiftData
- reproduzierbare Mock- und Demo-Daten für Tests, Previews und Screenshots
- sichtbarer Hinweis, dass RecoveryLens keine medizinische Bewertung vornimmt
- explizite Berechtigungs-, Lade-, Inhalts-, Empty- und Fehlerzustände

## Bewusste Grenzen

RecoveryLens interpretiert Messwerte nicht als „gut“, „schlecht“, „gesund“,
„bereit“, „erholt“, „überlastet“ oder „riskant“. Das MVP enthält insbesondere:

- keinen Recovery-, Readiness- oder Health-Score
- keine Diagnose oder Risikoeinschätzung
- keine konkreten Gesundheits-, Schlaf- oder Trainingsempfehlungen
- keine individuellen Ziele oder Zielerreichungsbewertung
- keine Langzeittrends über den Sieben-Tage-Zeitraum hinaus
- keinen Export
- kein Widget und keinen App Intent
- keine zusätzlichen HealthKit-Werte
- kein Benutzerkonto und keine Cloud-Synchronisierung
- keine Werbung, Analytik oder Drittanbieter-SDKs
- keine Schreibzugriffe auf HealthKit

Diese Punkte gehören nicht stillschweigend in MVP 0.1. Änderungen am Umfang
werden vor der Implementierung ausdrücklich vereinbart.

## Nutzerfluss

1. Beim ersten Start erklärt die App knapp Zweck, Datenumfang und lokale
   Verarbeitung.
2. Die Person startet die HealthKit-Berechtigungsanfrage bewusst.
3. Das Dashboard zeigt den aktuellen Zustand und, falls verfügbar, die
   heutigen Kennzahlen.
4. Die Wochenansicht zeigt sieben Kalendertage und die zugehörigen
   Trainingseinheiten.
5. Der Tages-Check-in kann erstellt oder für denselben Tag bearbeitet werden.
6. Eine Infoansicht dokumentiert Datenschutz, Datenquellen und fachliche
   Grenzen.

Eine abgelehnte Berechtigung blockiert den manuellen Check-in nicht.

## Screens

### Einstieg und Berechtigung

- Zweck und gelesene Datenarten
- Hinweis auf freiwillige Freigabe und Änderbarkeit in den Systemeinstellungen
- Schaltfläche zum Starten der Systemanfrage
- eigener Zustand für nicht verfügbares HealthKit

### Dashboard

- Schritte heute
- aktive Energie heute in Kilokalorien
- Schlafdauer des relevanten Schlafzeitraums
- klar getrennte Lade-, Inhalts-, Empty- und Fehlerdarstellung
- Einstieg in Wochenübersicht und Check-in

### Wochenübersicht

- sieben Kalendertage einschließlich heute
- Charts für die aufbereiteten Tageswerte
- Liste der Trainingseinheiten im selben Zeitraum
- fehlende Werte werden als fehlend behandelt, nicht als gemessene Null

### Tages-Check-in

- Energieempfinden von 1 bis 5
- Stimmung von 1 bis 5
- optionale kurze Notiz
- genau ein Eintrag pro lokalem Kalendertag
- Validierung vor dem Speichern

### Info und Datenschutz

- verwendete Datenquellen
- lokale Speicherung eigener Check-ins
- keine Übertragung oder Nutzung zu Werbezwecken
- keine medizinische Bewertung
- bekannte fachliche und technische Grenzen

## Architektur

RecoveryLens verwendet eine kleine MVVM-Struktur:

- SwiftUI-Views rendern Zustand und leiten Nutzeraktionen weiter.
- ViewModels koordinieren Laden, Zustandsübergänge und Präsentationsdaten.
- Ein kleines `HealthKitClient`-Protokoll kapselt Autorisierung und Abfragen.
- Der Live-Client verwendet HealthKit mit async/await.
- Ein Mock-Client liefert deterministische Daten und Fehlerfälle.
- SwiftData speichert ausschließlich eigene Check-ins.
- Reine Mapper und Aggregationsfunktionen bereiten HealthKit-Ergebnisse auf.

HealthKit- oder SwiftData-Abfragen erfolgen nicht direkt in Views. Es werden
keine zusätzlichen Architektur-Frameworks oder Drittanbieter-Abhängigkeiten
eingeführt.

## Kleinste Domänenmodelle

### DailyHealthSummary

- `date: Date`
- `steps: Int?`
- `activeEnergyKilocalories: Double?`
- `sleepMinutes: Int?`
- `workouts: [WorkoutSummary]`

### WorkoutSummary

- `id: UUID`
- `startDate: Date`
- `durationMinutes: Int`
- `activityName: String`
- `activeEnergyKilocalories: Double?`

### DailyCheckIn

- `date: Date`
- `energyLevel: Int`
- `moodLevel: Int`
- `note: String?`
- `createdAt: Date`
- `updatedAt: Date`

Optionale Health-Werte sind Absicht: fehlende Daten sind ein normaler Zustand
und dürfen nicht automatisch als Null interpretiert werden.

## Zeit- und Aggregationsregeln

- „Heute“ und die sieben Tage richten sich nach lokalem Kalender und Zeitzone.
- Der Wochenzeitraum umfasst heute plus die sechs vorherigen Kalendertage.
- Schritte und aktive Energie werden pro Kalendertag summiert.
- Trainingseinheiten werden nach ihrem Startdatum einem Tag zugeordnet.
- Schlaf wird aus relevanten Schlaf-Samples aufbereitet.
- Überlappende Schlafintervalle dürfen nicht doppelt gezählt werden.
- Wachphasen zählen nicht zur Schlafdauer.
- Quellenpriorisierung und genaue Schlafkategorien werden vor dem
  HealthKit-Block anhand aktueller Apple-Dokumentation festgelegt und getestet.
- Kalender- und Zeitzonenabhängigkeiten müssen injizierbar oder anderweitig
  deterministisch testbar sein.

## App-Zustände

Der Präsentationszustand muss mindestens unterscheiden:

- HealthKit auf dem Gerät nicht verfügbar
- Berechtigung noch nicht angefragt
- Berechtigung angefragt oder Zugriff nicht ermittelbar
- Laden
- Inhalt vorhanden
- keine Daten im Zeitraum
- partiell fehlende Daten
- Abfrage fehlgeschlagen

HealthKit gibt aus Datenschutzgründen nicht für jeden Lesetyp zuverlässig
Auskunft, ob ein Nutzer den Lesezugriff verweigert hat. Die App darf daher aus
einem leeren Ergebnis keine konkrete Ablehnung ableiten und kommuniziert nur
beobachtbare Zustände.

## Datenschutz

- Es werden nur die für MVP 0.1 genannten HealthKit-Typen angefragt.
- HealthKit-Daten werden ausschließlich gelesen und für die aktuelle
  Darstellung verarbeitet.
- HealthKit-Daten werden nicht in SwiftData gespiegelt.
- Persistiert werden nur manuell eingegebene Check-ins.
- Es gibt keine externe Übertragung, Analytik, Werbung oder Profilbildung.
- Purpose Strings benennen Zweck und Umfang in verständlicher Sprache.
- Logs dürfen keine sensiblen Gesundheitswerte oder Check-in-Notizen enthalten.
- Demo-Daten sind synthetisch und eindeutig als Demo-Daten erkennbar.

Vor einer späteren Widget-Implementierung wird erneut geprüft, welche
HealthKit-Daten eine Extension aktuell und zuverlässig lesen darf. Falls nötig,
stellt nur die Haupt-App einen minimalen, nicht sensibleren Snapshot in einem
App-Group-Container bereit.

## Risiken

- HealthKit ist nicht in jeder Laufzeitumgebung verfügbar.
- Simulator-Daten ersetzen keine Prüfung auf einem realen iPhone.
- Nutzer können einzelne Datentypen freigeben, verweigern oder später ändern.
- Leere Ergebnisse können fehlende Messungen oder fehlenden Zugriff bedeuten.
- Schlafdaten können über Mitternacht reichen, sich überlappen und aus mehreren
  Quellen stammen.
- Trainingseinheiten können ohne Energieangabe vorliegen.
- Zeitzonenwechsel und Sommerzeit beeinflussen Tagesgrenzen.
- UI-Tests und Screenshots dürfen nicht von persönlichen Health-Daten abhängen.

## Teststrategie

HealthKit selbst wird nicht nachgebaut. Getestet werden eigene Logik und
Zustandsübergänge:

- Mapping von Client-Ergebnissen auf Dashboard-Daten
- Aggregation der letzten sieben Kalendertage
- Schlafaggregation ohne doppelte Überlappungen
- fehlende und partiell fehlende Daten
- nicht verfügbares HealthKit, Berechtigungsfluss und Abfragefehler
- ViewModel-Verhalten mit Mock-Client
- Check-in-Validierung und genau ein Eintrag pro Tag
- Erstellen und Aktualisieren eines Check-ins mit In-Memory-SwiftData
- deterministische Demo-Daten

Jeder Implementierungsblock endet mit den dazu passenden automatisierten Tests
oder einer dokumentierten manuellen Verifikation.

## Portfolio-Abschlusskriterien

MVP 0.1 ist erst abgeschlossen, wenn:

- App und Tests lokal erfolgreich bauen
- alle relevanten Unit- und UI-Tests grün sind
- HealthKit auf einem realen Gerät geprüft wurde
- Empty-, Fehler- und Berechtigungszustände sichtbar geprüft wurden
- ein eigenes App Icon vorhanden ist
- Screenshots reproduzierbar aus Demo-Daten erzeugt werden können
- das README Architektur, Setup, Datenschutz und Teststrategie erklärt
- eine kurze Case Study Entscheidungen und Trade-offs dokumentiert
- Grenzen der Gesundheitsauswertung klar dokumentiert sind

## Implementierungsblöcke

Jeder Block entspricht genau einem erklärbaren, testbaren und revertierbaren
Commit:

1. Projektvertrag und Bestandsaufnahme
2. Domänenmodelle, Demo-Daten und reine Aggregationslogik
3. HealthKit-Client-Protokoll, Live-Client und Mock-Client
4. Dashboard-ViewModel und Zustandsübergänge
5. Berechtigungsfluss und Dashboard-Oberfläche
6. SwiftData-Check-in mit ViewModel und Tests
7. Wochencharts und Trainingseinheiten
8. Infoansicht, Datenschutztexte und UI-Zustände
9. Demo-Screenshots, App Icon, README und Case Study
10. Abschlussprüfung auf Simulator und realem Gerät

Vor jedem Block werden die konkret betroffenen Dateien benannt. Es werden nur
diese Dateien geändert. Große Refactorings, neue Abhängigkeiten und
Umfangserweiterungen benötigen eine separate Freigabe.

## Technische Ausgangslage

- SwiftUI-App mit App-, Unit-Test- und UI-Test-Target
- SwiftData-Xcode-Template als aktueller Ausgangspunkt
- iOS Deployment Target 26.5
- Swift 5 Build-Einstellung
- keine Drittanbieter-Abhängigkeiten

Die Template-Typen `Item`, `ContentView` und die initiale
`ModelContainer`-Konfiguration sind noch keine fachliche Architektur und werden
erst in den jeweils freigegebenen Implementierungsblöcken ersetzt.

## Verbindliche Apple-Referenzen

Vor HealthKit-Änderungen werden mindestens diese aktuellen Primärquellen
geprüft:

- HealthKit: Authorizing access to health data
  <https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data>
- HealthKit: `HKHealthStore.isHealthDataAvailable()`
  <https://developer.apple.com/documentation/healthkit/hkhealthstore/ishealthdataavailable()>
- HealthKit: Running queries with Swift concurrency
  <https://developer.apple.com/documentation/healthkit/running-queries-with-swift-concurrency>
- Swift Charts
  <https://developer.apple.com/documentation/charts>
- SwiftData
  <https://developer.apple.com/documentation/swiftdata>
- App Review Guidelines
  <https://developer.apple.com/app-store/review/guidelines/>

Der Dokumentationsstand wird beim jeweiligen Implementierungsblock erneut
verifiziert, weil Plattformverhalten und Review-Anforderungen veränderlich
sind.
