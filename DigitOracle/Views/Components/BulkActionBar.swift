import SwiftUI

struct BulkActionBar: View {
    let actions: [BulkAction]

    struct BulkAction: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        var tint: Color? = nil
        var isDisabled: Bool = false
        let action: () -> Void
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                ForEach(actions) { bulkAction in
                    Button {
                        bulkAction.action()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: bulkAction.icon)
                                .font(.title3)
                            Text(bulkAction.label)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(bulkAction.isDisabled)
                    .tint(bulkAction.tint)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
        }
        .background(.bar)
    }
}
