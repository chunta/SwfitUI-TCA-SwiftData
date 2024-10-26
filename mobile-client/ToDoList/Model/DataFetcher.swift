import Foundation

/// Protocol defining a data fetching interface for making network requests.
protocol DataFetcherProtocol {
    /// Performs a data request and returns the resulting data and response.
    ///
    /// - Parameter request: The URL request to be executed.
    /// - Returns: A tuple containing the retrieved `Data` and `URLResponse`.
    /// - Throws: An error if the data request fails.
    func dataRequest(from request: URLRequest) async throws -> (Data, URLResponse)
}

/// Concrete implementation of `DataFetcherProtocol` using `URLSession`
/// to perform network requests.
final class URLSessionDataFetcher: DataFetcherProtocol {
    /// Executes a network request using `URLSession.shared` and returns
    /// the data and response.
    ///
    /// - Parameter request: The URL request to be executed.
    /// - Returns: A tuple containing the retrieved `Data` and `URLResponse`.
    /// - Throws: An error if the request fails.
    func dataRequest(from request: URLRequest) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(for: request)
    }
}
