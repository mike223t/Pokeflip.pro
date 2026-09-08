import SwiftUI
import VisionKit

struct ScannerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var recognizedText = "Point the camera at the card name and set number"
    @State private var results: [CardPrice] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    private let lookupService = CardLookupService()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    LiveCardScanner { text in
                        recognizedText = text
                    }
                    .ignoresSafeArea()
                } else {
                    ContentUnavailableView(
                        "Camera scanning unavailable",
                        systemImage: "camera.slash",
                        description: Text("Use card search instead on this device.")
                    )
                }

                VStack(spacing: 10) {
                    Text(recognizedText)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())

                    Button {
                        Task { await findPrices() }
                    } label: {
                        HStack {
                            if isSearching { ProgressView().tint(.white) }
                            Text(isSearching ? "Finding prices…" : "Find prices")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSearching || recognizedText.isEmpty)
                }
                .padding(16)
            }
            .navigationTitle("Scan a card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: Binding(
                get: { !results.isEmpty },
                set: { if !$0 { results = [] } }
            )) {
                ScanResultsView(results: results)
                    .presentationDetents([.medium, .large])
            }
            .alert("Couldn't find prices", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Try moving closer to the card name and set number.")
            }
        }
    }

    private func findPrices() async {
        isSearching = true
        defer { isSearching = false }
        do {
            let found = try await lookupService.lookup(query: recognizedText)
            if found.isEmpty {
                errorMessage = "No matching card was found. Try scanning again with the card name clearly visible."
            } else {
                results = Array(found.prefix(8))
            }
        } catch {
            errorMessage = "The price service is unavailable right now. Please try again."
        }
    }
}

struct ScanResultsView: View {
    let results: [CardPrice]

    var body: some View {
        NavigationStack {
            List(results) { card in
                HStack(spacing: 12) {
                    AsyncImage(url: card.imageURL) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8).fill(.quaternary)
                    }
                    .frame(width: 58, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(card.name).font(.headline)
                        Text(card.setName).font(.caption).foregroundStyle(.secondary)
                        if let price = card.displayPrice {
                            Text(price, format: .currency(code: "USD"))
                                .font(.title3.bold())
                                .foregroundStyle(.green)
                        } else {
                            Text("Price unavailable").font(.caption).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 8) {
                            if let low = card.lowPrice { Text("Low \(low, format: .currency(code: "USD"))") }
                            if let high = card.highPrice { Text("High \(high, format: .currency(code: "USD"))") }
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Card prices")
        }
    }
}

struct LiveCardScanner: UIViewControllerRepresentable {
    let onText: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onText: onText) }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
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

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            let strings = allItems.compactMap { item -> String? in
                if case .text(let text) = item { return text.transcript }
                return nil
            }
            guard !strings.isEmpty else { return }
            DispatchQueue.main.async { self.onText(strings.joined(separator: " ")) }
        }
    }
}
