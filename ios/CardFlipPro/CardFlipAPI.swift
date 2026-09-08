import Foundation

struct CardPrice: Codable, Identifiable {
    let id: String
    let name: String
    let setName: String
    let marketPrice: Double?
    let lowPrice: Double?
    let highPrice: Double?
    let updatedAt: Date?
}

struct CardLookupService {
    // Production endpoint will live behind CardFlipPro's backend so API keys never ship inside the app.
    let baseURL = URL(string: "https://mike223t.github.io/Pokeflip.pro")!

    func lookup(query: String) async throws -> [CardPrice] {
        // This client is intentionally ready for the live backend contract.
        // Until the backend endpoint is deployed, the app uses its local deal examples.
        _ = query
        return []
    }
}
