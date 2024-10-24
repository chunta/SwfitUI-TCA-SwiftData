import Foundation

protocol DataFetcherProtocol {
    func dataRequest(from request: URLRequest) async throws -> (Data, URLResponse)
}

final class URLSessionDataFetcher: DataFetcherProtocol {
    func dataRequest(from request: URLRequest) async throws -> (Data, URLResponse) {
        return try await URLSession.shared.data(for: request)
    }
}
