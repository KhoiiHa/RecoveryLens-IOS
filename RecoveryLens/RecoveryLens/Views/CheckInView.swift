import SwiftUI

struct CheckInView: View {
    @Bindable var viewModel: CheckInViewModel

    var body: some View {
        Form {
            statusSection
            ratingSection(
                title: "Energieempfinden",
                systemImage: "bolt.fill",
                selection: $viewModel.energyLevel
            )
            ratingSection(
                title: "Stimmung",
                systemImage: "face.smiling",
                selection: $viewModel.moodLevel
            )
            noteSection
            medicalNotice
        }
        .navigationTitle("Tages-Check-in")
        .safeAreaInset(edge: .bottom) {
            saveButton
        }
        .task {
            guard viewModel.state == .idle else {
                return
            }

            viewModel.load()
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text(
                    viewModel.date.formatted(
                        .dateTime
                            .weekday(.wide)
                            .day()
                            .month(.wide)
                            .locale(Locale(identifier: "de_DE"))
                    )
                )
                .font(.headline)

                switch viewModel.state {
                case .idle, .loading:
                    Label("Check-in wird geladen", systemImage: "clock")
                        .foregroundStyle(.secondary)
                case .ready where viewModel.isExistingCheckIn:
                    Label(
                        "Für diesen Tag bereits gespeichert",
                        systemImage: "checkmark.circle"
                    )
                    .foregroundStyle(.secondary)
                case .saved:
                    Label("Check-in gespeichert", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case let .failed(message):
                    Label(message, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                default:
                    Text("Wie fühlst du dich heute?")
                        .foregroundStyle(.secondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func ratingSection(
        title: String,
        systemImage: String,
        selection: Binding<Int>
    ) -> some View {
        Section {
            Picker(title, selection: selection) {
                ForEach(1...5, id: \.self) { value in
                    Text(value.formatted()).tag(value)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        } header: {
            Label(title, systemImage: systemImage)
        } footer: {
            HStack {
                Text("Niedrig")
                Spacer()
                Text("Hoch")
            }
        }
    }

    private var noteSection: some View {
        Section {
            TextEditor(text: $viewModel.note)
                .frame(minHeight: 96)
                .accessibilityLabel("Optionale Notiz")
        } header: {
            Label("Notiz", systemImage: "square.and.pencil")
        } footer: {
            HStack {
                Text("Optional")
                Spacer()
                Text("\(viewModel.remainingNoteCharacters) Zeichen")
                    .foregroundStyle(
                        viewModel.remainingNoteCharacters < 0
                            ? Color.red
                            : Color.secondary
                    )
            }
        }
    }

    private var medicalNotice: some View {
        Section {
            Label {
                Text(
                    "Der Check-in dient nur deiner persönlichen Reflexion und ist keine medizinische Bewertung."
                )
            } icon: {
                Image(systemName: "info.circle")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private var saveButton: some View {
        Button {
            viewModel.save()
        } label: {
            Label(
                viewModel.isExistingCheckIn
                    ? "Änderungen speichern"
                    : "Check-in speichern",
                systemImage: "checkmark"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!viewModel.canSave)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

#if DEBUG
@MainActor
final class PreviewCheckInService: CheckInService {
    private var checkIn: DailyCheckIn?

    func checkIn(for date: Date) throws -> DailyCheckIn? {
        checkIn
    }

    func save(
        date: Date,
        energyLevel: Int,
        moodLevel: Int,
        note: String?
    ) throws -> DailyCheckIn {
        let timestamp = DemoData.referenceDate
        let savedCheckIn = DailyCheckIn(
            date: date,
            energyLevel: energyLevel,
            moodLevel: moodLevel,
            note: note,
            createdAt: timestamp,
            updatedAt: timestamp
        )
        checkIn = savedCheckIn
        return savedCheckIn
    }
}
#Preview {
    NavigationStack {
        CheckInView(
            viewModel: CheckInViewModel(
                checkInService: PreviewCheckInService(),
                date: DemoData.referenceDate
            )
        )
    }
}
#endif
