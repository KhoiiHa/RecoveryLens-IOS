import SwiftUI

struct HealthAuthorizationView: View {
    let onAuthorize: () async -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                dataTypes
                privacyNotice

                Button {
                    Task {
                        await onAuthorize()
                    }
                } label: {
                    Label(
                        "Mit Apple Health verbinden",
                        systemImage: "heart.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityHint(
                    "Öffnet die Apple-Health-Berechtigungsabfrage"
                )
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "heart.text.clipboard")
                .font(.system(size: 42))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text("RecoveryLens")
                .font(.largeTitle.bold())

            Text(
                "Betrachte deine letzten Tage anhand weniger verständlicher Werte aus Apple Health. RecoveryLens gibt keine medizinische Bewertung oder Gesundheitsempfehlung."
            )
            .font(.title3)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var dataTypes: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Diese Daten werden gelesen")
                .font(.headline)
                .padding(.bottom, 12)

            authorizationRow(
                title: "Schritte",
                systemImage: "figure.walk"
            )
            Divider()
            authorizationRow(
                title: "Aktive Energie",
                systemImage: "flame"
            )
            Divider()
            authorizationRow(
                title: "Schlafdauer",
                systemImage: "bed.double"
            )
            Divider()
            authorizationRow(
                title: "Trainingseinheiten",
                systemImage: "figure.run"
            )
        }
    }

    private var privacyNotice: some View {
        Label {
            Text(
                "Die Freigabe ist freiwillig und später in Apple Health oder den Systemeinstellungen änderbar. Health-Daten werden nicht dauerhaft gespeichert oder übertragen."
            )
            .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "lock.shield")
                .foregroundStyle(.green)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private func authorizationRow(
        title: String,
        systemImage: String
    ) -> some View {
        Label {
            Text(title)
                .font(.body)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
                .frame(width: 28)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 13)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    HealthAuthorizationView {}
}
