import SwiftUI

struct ShareExtensionView: View {
    let image: UIImage
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var notes = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 3)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)

                        TextField("What did you spot?", text: $notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("Save to Spot47")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        isSaving = true
                        onSave(notes)
                    }
                    .bold()
                    .disabled(isSaving)
                }
            }
        }
    }
}
