import Foundation

struct CardPrice: Codable, Identifiable {
    let id: String
    let name: String
    let setName: String
    let marketPrice: Double?
    let lowPrice: Double?
    let highPrice: Double?
    let imageURL: URL?
    let updatedAt: Date?

    var displayPrice: Double? { marketPrice ?? lowPrice }
}

private struct PokemonTCGResponse: Decodable { let data: [PokemonTCGCard] }
private struct PokemonTCGCard: Decodable {
    let id: String
    let name: String
    let set: PokemonTCGSet
    let images: PokemonTCGImages?
    let tcgplayer: PokemonTCGPlayer?
}
private struct PokemonTCGSet: Decodable { let name: String }
private struct PokemonTCGImages: Decodable { let small: URL?; let large: URL? }
private struct PokemonTCGPlayer: Decodable { let prices: [String: PokemonTCGPrice]? }
private struct PokemonTCGPrice: Decodable { let low: Double?; let market: Double?; let high: Double? }

struct CardLookupService {
    // Test-build endpoint. Production should proxy this through CardFlipPro's backend
    // for caching, provider compliance, rate limiting, and any required API key.
    private let endpoint = URL(string: "https://api.pokemontcg.io/v2/cards")!

    func lookup(query: String) async throws -> [CardPrice] {
        let cleaned = query
            .split(whereSeparator: { $0.isWhitespace })
            .prefix(5)
            .joined(separator: " ")
        guard !cleaned.isEmpty else { return [] }

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        let escaped = cleaned.replacingOccurrences(of: "\"", with: "")
        components.queryItems = [
            URLQueryItem(name: "q", value: "name:\(escaped)"),
            URLQueryItem(name: "pageSize", value: "12")
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(PokemonTCGResponse.self, from: data)
        return decoded.data.map { card in
            let prices = card.tcgplayer?.prices?.values ?? []
            return CardPrice(
                id: card.id,
                name: card.name,
                setName: card.set.name,
                marketPrice: prices.compactMap(\.market).max(),
                lowPrice: prices.compactMap(\.low).min(),
                highPrice: prices.compactMap(\.high).max(),
                imageURL: card.images?.large ?? card.images?.small,
                updatedAt: nil
            )
        }.sorted { ($0.displayPrice ?? 0) > ($1.displayPrice ?? 0) }
    }
}
