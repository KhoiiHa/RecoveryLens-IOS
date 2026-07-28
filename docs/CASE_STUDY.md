# RecoveryLens – Case Study

## Ausgangslage

Gesundheits-Apps geraten schnell in einen problematischen Bereich: Eine
visuell attraktive Zusammenfassung kann wie eine medizinische Bewertung
wirken, obwohl Daten unvollständig, uneinheitlich oder nicht freigegeben sind.
RecoveryLens untersucht deshalb, wie sich HealthKit technisch sauber und
portfolio-tauglich integrieren lässt, ohne aus Messwerten Gesundheitsurteile
abzuleiten.

## Ziel und Umfang

MVP 0.1 konzentriert sich auf vier gelesene HealthKit-Datentypen: Schritte,
aktive Energie, Schlafanalyse und Trainingseinheiten. Das Dashboard zeigt
heutige Werte, die Wochenansicht genau sieben Kalendertage. Ein optionaler
Check-in ergänzt Energieempfinden, Stimmung und eine kurze Notiz als eigene
lokale App-Daten.

Bewusst ausgeschlossen sind Recovery-Scores, Ziele, Langzeittrends, Export,
WidgetKit, App Intents und zusätzliche HealthKit-Werte. Diese Begrenzung hält
Datennutzung, Testumfang und Produktaussage nachvollziehbar.

Das MVP unterstützt ausschließlich iPhone. Eine deklarierte iPad-Kompatibilität
ohne angepasste Navigation, Layoutprüfung und eigene UI-Tests wäre ein
irreführendes Qualitätsversprechen und wurde deshalb bewusst entfernt.

## Zentrale Entscheidungen

### HealthKit hinter einem Client

Views greifen nie direkt auf HealthKit zu. Ein kleines
`HealthKitClient`-Protokoll trennt Autorisierung und Abfragen von der
Darstellung. Der Live-Client verwendet HealthKit mit async/await; der
Mock-Client liefert definierte Snapshots und Fehler. Dadurch bleiben
ViewModel-Zustände ohne echte Gesundheitsdaten testbar.

### Fehlend ist nicht null

Schritte, Energie und Schlaf sind im Domänenmodell optional. Fehlende Werte
werden nicht als gemessene Null dargestellt. Das ist besonders wichtig, weil
HealthKit einer App nicht zuverlässig offenlegt, ob lesender Zugriff
verweigert wurde. Die Oberfläche kommuniziert daher nur beobachtbare
Zustände.

### Reine Aggregationslogik

Die sieben Tage werden mit injizierbarem Kalender und Referenzdatum gebildet.
Bei Schlaf zählen nur die HealthKit-Zustände `asleepUnspecified`,
`asleepCore`, `asleepDeep` und `asleepREM`; `inBed` und `awake` werden nicht
als Schlafdauer behandelt. Schlafintervalle werden vereinigt und
überlappende Wachintervalle abgezogen.

Mehrere Apps oder Geräte können dieselben Zeiträume liefern. Da HealthKit
keine allgemeine Qualitätsrangfolge für Quellen vorgibt, erfindet RecoveryLens
keine geräte- oder herstellerspezifische Priorität. Stattdessen werden
Intervalle quellenneutral als Zeitunion zusammengeführt. So entstehen keine
Doppelzählungen und die App behauptet keine nicht belegbare Messqualität.

Trainingseinheiten werden anhand ihres Startdatums einem lokalen Kalendertag
zugeordnet. Diese Regeln liegen außerhalb der Views und sind mit
deterministischen Daten getestet.

### SwiftData nur für eigene Daten

HealthKit-Werte werden nicht gespiegelt oder dauerhaft zwischengespeichert.
SwiftData speichert ausschließlich manuelle Check-ins. Pro lokalem
Kalendertag existiert höchstens ein Eintrag; erneutes Speichern aktualisiert
diesen Eintrag.

## Datenschutz und Produktgrenzen

RecoveryLens besitzt kein Konto, keine Cloud-Synchronisierung, keine
Analytik, keine Werbung und keine Drittanbieter-SDKs. Berechtigungen sind
freiwillig und pro Datenart wählbar. Der manuelle Check-in bleibt auch ohne
HealthKit-Zugriff nutzbar.

Die App erstellt keine Diagnose, Risikoeinschätzung oder konkrete
Gesundheitsempfehlung. Messwerte werden nicht als gesund, ungesund, erholt
oder überlastet interpretiert. Diese Grenze ist im Einstieg, Dashboard und in
der Infoansicht sichtbar, statt nur in Repository-Dokumentation zu stehen.

## Teststrategie

HealthKit selbst wird nicht nachgebaut. Unit-Tests prüfen die eigene
Aggregation, Schlafüberlappungen, fehlende Daten, Check-in-Validierung,
SwiftData-Speicherung und ViewModel-Zustände. UI-Tests starten die App über
deterministische DEBUG-Szenarien und prüfen Berechtigung, Laden, Inhalt,
Empty-, Partial- und Fehlerdarstellung.

Der Screenshot-Test verwendet ausschließlich `DemoData` mit festem Kalender
und Referenzdatum. Dadurch lassen sich Portfolio-Aufnahmen ohne persönliche
Health-Daten reproduzieren.

## Ergebnis

Das MVP demonstriert HealthKit, Swift Charts, SwiftData, async/await und
MVVM, ohne eine unnötig breite Architektur einzuführen. Die wichtigsten
Portfolio-Artefakte sind im Repository nachvollziehbar: Quellcode, Tests,
synthetische Demo-Daten, Screenshot-Automation, App Icon sowie dokumentierte
Datenschutz- und Produktgrenzen.

## Offene Verifikation

Simulator und Mocks ersetzen keinen Lauf auf einem realen iPhone. Vor einem
Release müssen der Live-Berechtigungsdialog, einzelne verweigerte Datentypen,
reale Schlafquellen und Trainingseinheiten ohne Energieangabe auf Hardware
geprüft werden.

Vor einem späteren Widget wird erneut anhand der dann aktuellen
Apple-Dokumentation geprüft, welche HealthKit-Daten eine Extension zuverlässig
lesen darf. Falls nötig, stellt nur die Haupt-App einen minimalen,
datensparsamen Snapshot bereit.
