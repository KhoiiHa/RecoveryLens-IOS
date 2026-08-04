import SwiftUI

struct InfoView: View {
    var body: some View {
        List {
            introduction
            dataSources
            storageAndTransfer
            permissions
            boundaries
            privacyPolicy
            support
        }
        .navigationTitle("Info & Datenschutz")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var introduction: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)

                Text("RecoveryLens 0.2")
                    .font(.title2.bold())
                    .accessibilityIdentifier("app-version-summary")

                Text(
                    "RecoveryLens fasst ausgewählte Aktivitätsdaten zur persönlichen Reflexion zusammen."
                )
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)
        }
    }

    private var dataSources: some View {
        Section("Datenquellen") {
            InfoRow(
                title: "Apple Health",
                detail: "Schritte, aktive Energie, Schlaf und Trainingseinheiten werden ausschließlich gelesen.",
                systemImage: "heart.fill",
                tint: .red
            )

            InfoRow(
                title: "Tages-Check-in",
                detail: "Energieempfinden, Stimmung und optionale Notiz werden manuell eingegeben.",
                systemImage: "checkmark.circle.fill",
                tint: .blue
            )
        }
    }

    private var storageAndTransfer: some View {
        Section("Speicherung und Weitergabe") {
            InfoRow(
                title: "Health-Daten",
                detail: "Werden nicht in SwiftData kopiert und nur für die aktuelle Darstellung verarbeitet.",
                systemImage: "heart.text.clipboard",
                tint: .pink
            )

            InfoRow(
                title: "Eigene Check-ins",
                detail: "RecoveryLens speichert sie lokal im App-Container und synchronisiert sie nicht selbst. Abhängig von deinen iOS-Einstellungen können sie Bestandteil eines Systembackups sein.",
                systemImage: "iphone",
                tint: .indigo
            )

            InfoRow(
                title: "Keine Übertragung",
                detail: "Kein Konto, keine Cloud-Synchronisierung, keine Analytik, keine Werbung und keine Drittanbieter-SDKs.",
                systemImage: "network.slash",
                tint: .green
            )
        }
    }

    private var permissions: some View {
        Section("Berechtigungen") {
            InfoRow(
                title: "Deine Entscheidung",
                detail: "Die Freigabe ist freiwillig und für jede Datenart einzeln wählbar. Apple Health kann zusätzlich einen begrenzten historischen Zeitraum anbieten. Änderungen sind später in Apple Health oder den Systemeinstellungen möglich.",
                systemImage: "hand.raised.fill",
                tint: .blue
            )

            InfoRow(
                title: "Nicht eindeutig erkennbar",
                detail: "Apple Health teilt Apps nicht mit, ob Lesezugriff verweigert wurde. Fehlende Werte können daher aus fehlenden Messungen, verweigerten Datenarten oder einem begrenzten historischen Zeitraum entstehen.",
                systemImage: "questionmark.circle.fill",
                tint: .orange
            )
        }
    }

    private var boundaries: some View {
        Section("Fachliche Grenzen") {
            InfoRow(
                title: "Keine medizinische Bewertung",
                detail: "RecoveryLens erstellt keine Diagnose, Risikoeinschätzung oder Gesundheitsempfehlung.",
                systemImage: "cross.case",
                tint: .red
            )

            InfoRow(
                title: "Keine Interpretation",
                detail: "Werte werden nicht als gut, schlecht, gesund, erholt oder überlastet eingestuft.",
                systemImage: "chart.bar.xaxis",
                tint: .purple
            )

            InfoRow(
                title: "Schlafdauer",
                detail: "Gezählt werden nur von Apple Health als Schlaf markierte Zeiträume. Ein Schlaftag reicht von 12 Uhr des Vortags bis 12 Uhr des angezeigten Tages, damit eine Nacht nicht an Mitternacht geteilt wird. Überlappungen werden nicht doppelt gezählt; Bett- und Wachzeiten zählen nicht als Schlaf.",
                systemImage: "bed.double.fill",
                tint: .indigo
            )

            InfoRow(
                title: "Begrenzte Zeiträume",
                detail: "Dashboard und Wochenübersicht betrachten sieben Kalendertage. Die Reflexionsansicht betrachtet höchstens 30 Kalendertage einschließlich heute.",
                systemImage: "calendar",
                tint: .teal
            )
            .accessibilityIdentifier("health-data-periods")

            InfoRow(
                title: "Keine Kausalität",
                detail: "Die Gegenüberstellung mit dem Energieempfinden zeigt nur Werte desselben Tages. Sie belegt keine Ursache oder Wirkung.",
                systemImage: "circle.grid.cross",
                tint: .teal
            )
        }
    }

    private var privacyPolicy: some View {
        Section("Datenschutzerklärung") {
            Link(
                destination: URL(
                    string: "https://github.com/KhoiiHa/RecoveryLens-IOS/blob/main/PRIVACY.md"
                )!
            ) {
                Label(
                    "Datenschutzerklärung öffnen",
                    systemImage: "doc.text"
                )
            }
            .accessibilityIdentifier("privacy-policy-link")
        }
    }

    private var support: some View {
        Section("Kontakt") {
            Link(
                destination: URL(string: "mailto:hakhoi@gmx.de")!
            ) {
                Label("Support per E-Mail", systemImage: "envelope")
            }
            .accessibilityIdentifier("support-email-link")

            Text(
                "Bitte sende keine HealthKit-Werte, Check-in-Notizen oder anderen sensiblen Gesundheitsdaten mit."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}

private struct InfoRow: View {
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        InfoView()
    }
}
