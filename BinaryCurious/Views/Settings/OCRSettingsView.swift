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
                Toggle("Fast Mode", isOn: $useFastMode)
                Toggle("Language Correction", isOn: $useLanguageCorrection)
            } header: {
                Text("Recognition Quality")
            } footer: {
                Text(useFastMode
                     ? "Fast mode processes images quicker but may miss some numbers. Also applies to library scanning."
                     : "Accurate mode finds more numbers but takes longer to process.")
                + Text("\n")
                + Text(useLanguageCorrection
                       ? "Language correction uses context to resolve ambiguous characters. Helps with messy handwriting but may occasionally correct numbers away."
                       : "Language correction is off. More reliable for printed numbers.")
            }

            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Scan Rate")
                        Spacer()
                        Text("\(throttleInterval, specifier: "%.1f")s")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $throttleInterval, in: 0.2...2.0, step: 0.1)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Cooldown")
                        Spacer()
                        Text("\(cooldownDuration, specifier: "%.1f")s")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $cooldownDuration, in: 1.0...10.0, step: 0.5)
                }

                Stepper("Confirmation Frames: \(confirmationFrames)",
                        value: $confirmationFrames, in: 1...5)
            } header: {
                Text("Live Detection")
            } footer: {
                Text("Scan rate controls how often frames are analyzed. Lower values use more battery. Cooldown pauses after an auto-capture. Confirmation frames is how many consecutive detections trigger auto-capture.")
            }

            Section {
                Button("Reset to Defaults") {
                    useFastMode = Constants.OCR.useFastMode
                    useLanguageCorrection = Constants.OCR.useLanguageCorrection
                    throttleInterval = Constants.LiveDetector.throttleInterval
                    cooldownDuration = Constants.LiveDetector.cooldownDuration
                    confirmationFrames = Constants.LiveDetector.confirmationFrames
                }
            }
        }
        .navigationTitle("Detection")
        .navigationBarTitleDisplayMode(.inline)
    }
}
