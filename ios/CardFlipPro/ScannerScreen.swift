import SwiftUI
import VisionKit

struct ScannerScreen: View {
    let onResult: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var recognizedText = "Point the camera at a Pokémon card"

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    LiveCardScanner { text in
                        recognizedText = text
                    }
                    .ignoresSafeArea()
                } else {
                    ContentUnavailableView("Camera scanning unavailable", systemImage: "camera.slash", description: Text("Use the card search instead on this device."))
                }

                VStack(spacing: 10) {
                    Text(recognizedText)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                    Button("Use this card") {
                        onResult(recognizedText)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom, 28)
            }
            .navigationTitle("Scan a card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } } }
        }
    }
}

struct LiveCardScanner: UIViewControllerRepresentable {
    let onText: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onText: onText) }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onText: (String) -> Void
        init(onText: @escaping (String) -> Void) { self.onText = onText }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            let strings = allItems.compactMap { item -> String? in
                if case .text(let text) = item { return text.transcript }
                return nil
            }
            guard !strings.isEmpty else { return }
            DispatchQueue.main.async { self.onText(strings.joined(separator: " ")) }
        }
    }
}
