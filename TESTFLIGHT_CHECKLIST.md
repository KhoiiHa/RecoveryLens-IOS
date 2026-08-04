# TestFlight-Checkliste

Diese Checkliste trennt den lokal verifizierten Release-Stand von Schritten,
die ein Apple-Developer-Konto, App Store Connect oder ein physisches iPhone
benötigen.

## Release-Kandidat

- Version: `0.2.0`
- Build: `2`
- Bundle Identifier: `de.KhoiiHa.RecoveryLens`
- Plattform: iPhone
- Deployment Target: iOS 26.0
- Signierung: automatisch

Jeder erneute Upload benötigt eine höhere Build-Nummer. Die Marketing-Version
bleibt für weitere Builds dieses Umfangs bei `0.2.0`.

## Lokal verifiziert

- [x] Release-Konfiguration baut als unsigniertes iOS-Archive
- [x] Archive enthält App-Binary, App Icon und `PrivacyInfo.xcprivacy`
- [x] App Icon ist 1024 x 1024 Pixel groß und hat keinen Alphakanal
- [x] Privacy Manifest und öffentliche Datenschutzerklärung sind vorhanden
- [x] Keine Drittanbieter-SDKs, Analytik, Werbung oder Netzwerkübertragung
- [x] Keine eigene oder nicht ausgenommene Verschlüsselung
- [x] Reproduzierbare Demo-Daten und Portfolio-Screenshots sind vorhanden
- [x] Screenshots liegen im akzeptierten 6,9-Zoll-iPhone-Format vor
- [x] 61 Unit- und UI-Tests (64 Ausführungen) sind auf iOS 26.4.1 grün
- [x] Xcode 26.6 und iOS-26-SDK erfüllen die Upload-Anforderung ab April 2026

Ein unsigniertes Archive belegt nur die lokale Release-Baubarkeit. Es ist kein
an App Store Connect übertragbarer Build.

## Vor dem ersten Upload

- [ ] Apple-Developer-Team im App-Target auswählen
- [ ] Bundle Identifier im verwendeten Developer-Team registrieren
- [ ] App-Datensatz in App Store Connect anlegen oder prüfen
- [ ] Automatische Signierung ohne Fehler auflösen
- [ ] Verfügbarkeit auf Apple-Silicon-Macs in App Store Connect deaktivieren
- [ ] Live-HealthKit-Flow auf einem physischen iPhone prüfen
- [ ] Berechtigungsdialog und einzeln verweigerte Datentypen prüfen
- [ ] Reale Schlafdaten aus mehreren Quellen prüfen
- [ ] Trainingseinheiten ohne Energieangabe prüfen
- [ ] Release-Archive für `Any iOS Device (arm64)` signiert erstellen
- [ ] Archive im Organizer validieren
- [ ] Build über den Organizer hochladen und Verarbeitung abwarten

Auf diesem Entwicklungsrechner waren bei der letzten Prüfung kein physisches
iPhone und keine lokale Code-Signing-Identität verfügbar. Xcode kann abhängig
von Konto und Rolle eine cloudverwaltete Distribution-Signatur verwenden.
Ob das für dieses Team möglich ist, muss im Organizer geprüft werden.

## App Store Connect

- [ ] Support-URL hinterlegen:
      `https://github.com/KhoiiHa/RecoveryLens-IOS/blob/main/SUPPORT.md`
- [ ] Datenschutz-URL hinterlegen:
      `https://github.com/KhoiiHa/RecoveryLens-IOS/blob/main/PRIVACY.md`
- [ ] App-Privacy-Antworten anhand von `PRIVACY.md` ausfüllen
- [ ] Altersfreigabe-Fragen vollständig beantworten
- [ ] Export-Compliance-Angabe gegen den Build prüfen
- [ ] Beta-App-Beschreibung, Feedback-E-Mail und Kontakt hinterlegen
- [ ] Interne Testgruppe anlegen und Build zuweisen
- [ ] Für externe Tests Beta-App-Review einplanen

Die Antwort "Daten werden nicht erfasst" bleibt nur korrekt, solange
RecoveryLens keine Daten vom Gerät überträgt. HealthKit-Daten und lokale
Check-ins werden in diesem MVP ausschließlich auf dem Gerät verarbeitet.

## TestFlight-Texte

### Beta-Beschreibung

RecoveryLens bereitet ausgewählte Apple-Health-Daten der letzten 30 Tage
übersichtlich auf. Die App zeigt Schritte, aktive Energie, Schlafdauer und
Trainingseinheiten und stellt vorhandene Tageswerte neutral lokalen Check-ins
gegenüber. Sie gibt keine medizinischen Diagnosen, Kausalitätsaussagen oder
Gesundheitsempfehlungen.

### Was soll getestet werden?

Bitte prüfe den HealthKit-Berechtigungsfluss, fehlende oder teilweise
vorhandene Daten, die Wochen- und 30-Tage-Ansicht sowie das Erstellen und
Aktualisieren eines Tages-Check-ins. Melde insbesondere unplausible Schlafsummen,
unvollständige Trainingseinheiten und Darstellungsfehler.

## Referenzen

- [Builds hochladen](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [TestFlight-Uebersicht](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)
- [Cloudverwaltete Zertifikate](https://developer.apple.com/help/account/certificates/cloud-managed-certificates/)
- [Aktuelle Upload-Anforderungen](https://developer.apple.com/news/upcoming-requirements/)
