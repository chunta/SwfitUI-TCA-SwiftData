import Foundation

protocol DataFetcher {
    func dataRequest(from request: URLRequest) async throws -> (Data, URLResponse)
}

final class URLSessionDataFetcher: DataFetcher {
    func dataRequest(from request: URLRequest) async throws -> (Data, URLResponse) {
        return try await URLSession.shared.data(for: request)
    }
}
