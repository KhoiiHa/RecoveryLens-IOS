import SwiftUI

struct InfoView: View {
    var body: some View {
        List {
            introduction
            dataSources
            storageAndTransfer
            permissions
            boundaries
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

                Text("RecoveryLens MVP 0.1")
                    .font(.title2.bold())

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
                detail: "Bleiben lokal auf diesem Gerät, bis die App entfernt wird. Ein Eintrag kann für denselben Tag überschrieben werden.",
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
                detail: "Die Freigabe ist freiwillig und für jede Datenart einzeln wählbar. Änderungen sind später in Apple Health oder den Systemeinstellungen möglich.",
                systemImage: "hand.raised.fill",
                tint: .blue
            )

            InfoRow(
                title: "Nicht eindeutig erkennbar",
                detail: "Apple Health teilt Apps nicht mit, ob Lesezugriff verweigert wurde. Fehlende Werte können daher auch fehlende Messungen bedeuten.",
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
                detail: "Gezählt werden nur von Apple Health als Schlaf markierte Zeiträume. Überlappungen verschiedener Quellen werden nicht doppelt gezählt; Bett- und Wachzeiten zählen nicht als Schlaf.",
                systemImage: "bed.double.fill",
                tint: .indigo
            )

            InfoRow(
                title: "Begrenzter Zeitraum",
                detail: "Das MVP betrachtet ausschließlich die letzten sieben Kalendertage einschließlich heute.",
                systemImage: "calendar",
                tint: .teal
            )
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
