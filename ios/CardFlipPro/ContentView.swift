import SwiftUI

struct ContentView: View {
    @State private var search = ""
    @State private var showingScanner = false
    @State private var selectedTab = 0
    @State private var watchlist: Set<String> = []

    private let cards = Card.samples

    var filteredCards: [Card] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return cards }
        return cards.filter { $0.name.localizedCaseInsensitiveContains(q) || $0.set.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        hero
                        searchBar
                        stats
                        dealList
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationTitle("CardFlipPro")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showingScanner = true } label: { Image(systemName: "camera.viewfinder") } } }
            }
            .tabItem { Label("Deals", systemImage: "flame.fill") }
            .tag(0)

            NavigationStack {
                CollectionView(watchlist: $watchlist)
            }
            .tabItem { Label("Collection", systemImage: "square.stack.3d.up.fill") }
            .tag(1)

            NavigationStack {
                ToolsView()
            }
            .tabItem { Label("Tools", systemImage: "slider.horizontal.3") }
            .tag(2)
        }
        .tint(.blue)
        .sheet(isPresented: $showingScanner) {
            ScannerScreen { _ in showingScanner = false }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("⚡ Pokémon card intelligence")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.blue.opacity(0.12), in: Capsule())
                .foregroundStyle(.blue)
            Text("Find the flip before the market catches up.")
                .font(.system(size: 32, weight: .black, design: .rounded))
            Text("Scan a card, identify the set, see market pricing, calculate take-home profit, and decide BUY, MAYBE, or PASS.")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search Charizard, Pikachu, Umbreon…", text: $search)
            Button { showingScanner = true } label: { Image(systemName: "camera.fill") }
        }
        .padding(13)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.quaternary))
    }

    private var stats: some View {
        HStack(spacing: 10) {
            Stat(title: "Best upside", value: "$22")
            Stat(title: "Buy score", value: "86")
            Stat(title: "Watchlist", value: "\(watchlist.count)")
        }
    }

    private var dealList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best opportunities").font(.title3.bold())
            ForEach(filteredCards) { card in
                CardRow(card: card, isWatched: watchlist.contains(card.id)) {
                    if watchlist.contains(card.id) { watchlist.remove(card.id) } else { watchlist.insert(card.id) }
                }
            }
        }
    }
}

struct Stat: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct CardRow: View {
    let card: Card
    let isWatched: Bool
    let toggleWatch: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray.opacity(0.12))
                    .frame(width: 66, height: 92)
                    .overlay(Image(systemName: "rectangle.portrait.on.rectangle.portrait") .font(.title2).foregroundStyle(.secondary))
                VStack(alignment: .leading, spacing: 5) {
                    Text(card.name).font(.headline)
                    Text(card.set).font(.caption).foregroundStyle(.secondary)
                    Text(card.marketPrice, format: .currency(code: "USD"))
                        .font(.title3.bold()).foregroundStyle(.green)
                    Text("Buy target \(card.buyTarget, format: .currency(code: "USD"))  •  \(card.profit, format: .currency(code: "USD")) upside")
                        .font(.caption.weight(.semibold)).foregroundStyle(.blue)
                }
                Spacer()
                Button(action: toggleWatch) { Image(systemName: isWatched ? "star.fill" : "star") }
                    .buttonStyle(.plain)
                    .foregroundStyle(isWatched ? .yellow : .secondary)
            }
            HStack {
                Label("BUY \(card.score)", systemImage: "checkmark.seal.fill")
                    .font(.caption.bold()).foregroundStyle(.green)
                Spacer()
                Text("Gross margin \(card.margin, format: .percent)").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.quaternary))
    }
}

struct CollectionView: View {
    @Binding var watchlist: Set<String>
    var body: some View {
        List {
            Section("My collection") {
                Label("Add cards after scanning", systemImage: "plus.circle")
                Label("Track cost basis and current value", systemImage: "chart.line.uptrend.xyaxis")
                Label("See total profit and ROI", systemImage: "dollarsign.circle")
            }
            Section("Watchlist") { Text("\(watchlist.count) saved opportunities") }
        }
        .navigationTitle("Collection")
    }
}

struct ToolsView: View {
    @State private var buyPrice = 50.0
    @State private var sellPrice = 72.0
    @State private var fees = 0.13
    var profit: Double { sellPrice * (1 - fees) - buyPrice }
    var body: some View {
        Form {
            Section("Profit calculator") {
                TextField("Buy price", value: $buyPrice, format: .currency(code: "USD"))
                TextField("Expected sale price", value: $sellPrice, format: .currency(code: "USD"))
                TextField("Marketplace fee", value: $fees, format: .percent)
                LabeledContent("Estimated take-home") { Text(profit, format: .currency(code: "USD")).foregroundStyle(profit >= 0 ? .green : .red).bold() }
            }
            Section("CardFlipPro edge") {
                Text("Deal score combines upside, margin, liquidity, confidence, and your buy target.")
            }
        }
        .navigationTitle("Tools")
    }
}

struct Card: Identifiable {
    let id: String
    let name: String
    let set: String
    let marketPrice: Double
    let buyTarget: Double
    let score: Int
    let margin: Double
    var profit: Double { marketPrice - buyTarget }

    static let samples = [
        Card(id: "charizard-ex", name: "Charizard ex", set: "Scarlet & Violet", marketPrice: 45, buyTarget: 30, score: 86, margin: 0.33),
        Card(id: "pikachu-vmax", name: "Pikachu VMAX", set: "Vivid Voltage", marketPrice: 72, buyTarget: 50, score: 91, margin: 0.31),
        Card(id: "mewtwo-vstar", name: "Mewtwo VSTAR", set: "Crown Zenith", marketPrice: 38, buyTarget: 25, score: 84, margin: 0.34)
    ]
}

#Preview { ContentView() }
