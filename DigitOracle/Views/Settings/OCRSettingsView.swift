import SwiftUI

struct OCRSettingsView: View {
    @AppStorage(Constants.OCR.useFastModeKey) private var useFastMode = Constants.OCR.useFastMode
    @AppStorage(Constants.OCR.useLanguageCorrectionKey) private var useLanguageCorrection = Constants.OCR.useLanguageCorrection
    @AppStorage(Constants.LiveDetector.throttleIntervalKey) private var throttleInterval = Constants.LiveDetector.throttleInterval
    @AppStorage(Constants.LiveDetector.cooldownDurationKey) private var cooldownDuration = Constants.LiveDetector.cooldownDuration
    @AppStorage(Constants.LiveDetector.confirmationFramesKey) private var confirmationFrames = Constants.LiveDetector.confirmationFrames

    var body: some View {
        Form {
            Section {
                Toggle("Hasty Gaze", isOn: $useFastMode)
                Toggle("Runic Interpretation", isOn: $useLanguageCorrection)
            } header: {
                Text("Clarity of Sight")
            } footer: {
                Text(useFastMode
                     ? "The Oracle's gaze sweeps swiftly but may overlook faint signs. This haste extends to archive scanning."
                     : "The Oracle studies each vision with care, revealing more signs at the cost of patience.")
                + Text("\n")
                + Text(useLanguageCorrection
                       ? "Runic interpretation channels ancient knowledge to decipher uncertain glyphs. It aids with scrawled markings but may occasionally transmute numbers."
                       : "Runic interpretation is dormant. The Oracle reads printed numerals with greater fidelity.")
            }

            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Gaze Tempo")
                        Spacer()
                        Text("\(throttleInterval, specifier: "%.1f")s")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $throttleInterval, in: 0.2...2.0, step: 0.1)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Rest Between Gazes")
                        Spacer()
                        Text("\(cooldownDuration, specifier: "%.1f")s")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $cooldownDuration, in: 1.0...10.0, step: 0.5)
                }

                Stepper("Certainty Threshold: \(confirmationFrames)",
                        value: $confirmationFrames, in: 1...5)
            } header: {
                Text("The Living Eye")
            } footer: {
                Text("Gaze Tempo governs how often the Oracle peers at the world. Swifter gazes drain more of the vessel's spirit. Rest Between Gazes is the pause after a capture. Certainty Threshold is how many consecutive signs are required before seizing a vision.")
            }

            Section {
                Button("Restore the Ancient Ways") {
                    useFastMode = Constants.OCR.useFastMode
                    useLanguageCorrection = Constants.OCR.useLanguageCorrection
                    throttleInterval = Constants.LiveDetector.throttleInterval
                    cooldownDuration = Constants.LiveDetector.cooldownDuration
                    confirmationFrames = Constants.LiveDetector.confirmationFrames
                }
            }
        }
        .navigationTitle("The Oracle's Eye")
        .navigationBarTitleDisplayMode(.inline)
    }
}
