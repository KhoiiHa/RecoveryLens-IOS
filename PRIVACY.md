# Datenschutzerklärung für RecoveryLens

Stand: 4. August 2026

RecoveryLens ist eine lokal arbeitende iPhone-App zur übersichtlichen
Darstellung ausgewählter Apple-Health-Daten. Die App erstellt keine
medizinischen Bewertungen, Diagnosen oder Gesundheitsempfehlungen.

## Verarbeitete Daten

RecoveryLens kann nach deiner ausdrücklichen Freigabe ausschließlich lesend
auf folgende Daten aus Apple Health zugreifen:

- Schritte
- aktive Energie
- Schlafanalyse
- Trainingseinheiten

Diese Daten werden nur auf deinem Gerät für Dashboard, Wochenübersicht und die
auf höchstens 30 Kalendertage begrenzte Reflexionsansicht verarbeitet.
Trainingseinheiten werden ausschließlich für die Sieben-Tage-Übersicht
abgefragt; die 30-Tage-Reflexion liest nur Schritte, aktive Energie und Schlaf.
RecoveryLens kopiert HealthKit-Daten nicht in die eigene SwiftData-Datenbank
und überträgt sie nicht an den Entwickler oder Dritte.

Zusätzlich kannst du freiwillig einen täglichen Check-in mit
Energieempfinden, Stimmung und einer optionalen Notiz speichern. RecoveryLens
speichert diese Check-ins lokal im geschützten App-Container und betreibt dafür
keine eigene Übertragung oder Cloud-Synchronisierung.

Die 30-Tage-Reflexion kann vorhandene Schritte, aktive Energie oder Schlafdauer
dem manuell eingegebenen Energieempfinden desselben Kalendertages
gegenüberstellen. Diese Zuordnung wird nur auf dem Gerät berechnet, nicht
gespeichert oder übertragen und nicht als Ursache, Wirkung oder medizinische
Bewertung interpretiert. Stimmung und Check-in-Notiz werden dafür nicht
verwendet.

## Speicherung und Löschung

HealthKit-Daten werden von RecoveryLens nicht dauerhaft gespeichert. Lokale
Check-ins bleiben in der App erhalten, bis du sie durch Entfernen der App
löschst; ein erneuter Check-in am selben Kalendertag überschreibt den
vorhandenen Eintrag. Abhängig von deinen iOS- und Backup-Einstellungen können
App-Daten Bestandteil eines verschlüsselten Geräte- oder iCloud-Backups sein.
RecoveryLens steuert oder betreibt diese Systembackups nicht.

Die Freigabe einzelner HealthKit-Datentypen kannst du jederzeit in Apple Health
oder den iOS-Systemeinstellungen ändern. Apple Health kann außerdem anbieten,
den Lesezugriff auf einen begrenzten historischen Zeitraum zu beschränken.
RecoveryLens behandelt außerhalb dieses Zeitraums fehlende Werte nicht als
gemessene Null und leitet daraus keine konkrete Ablehnung ab.

## Keine Übertragung und kein Tracking

RecoveryLens verwendet:

- kein Benutzerkonto und keinen eigenen Server
- keine Cloud-Synchronisierung
- keine Analytik oder Werbung
- kein Tracking
- keine Drittanbieter-SDKs

Damit werden durch RecoveryLens keine personenbezogenen Daten vom Gerät an den
Entwickler oder an Dritte übertragen.

## Apple-Dienste

Apple verarbeitet Daten im Zusammenhang mit Apple Health, dem App Store und
dem Betriebssystem nach den eigenen Datenschutzbestimmungen. RecoveryLens hat
keinen Zugriff auf Daten, die Apple unabhängig von der App verarbeitet.

Weitere Informationen zu iCloud-Backups stellt Apple in der
[iCloud-Datensicherheit](https://support.apple.com/de-de/102651) bereit.

## Änderungen

Wenn sich Funktionen oder Datenflüsse von RecoveryLens ändern, wird diese
Datenschutzerklärung vor einer Veröffentlichung entsprechend aktualisiert.

## Kontakt

Fragen zum Datenschutz können vertraulich per E-Mail an
[hakhoi@gmx.de](mailto:hakhoi@gmx.de) gestellt werden. Bitte sende keine
HealthKit-Werte, Check-in-Notizen oder anderen sensiblen Gesundheitsdaten mit.

Allgemeine technische Hinweise stehen auf der
[Supportseite](SUPPORT.md). Öffentliche GitHub-Issues sind ausschließlich für
Fehlerberichte ohne persönliche oder gesundheitliche Angaben vorgesehen.
