import Foundation
@testable import ToDoList

/// A mock implementation of the `DataFetcherProtocol` for testing purposes.
final class MockDataFetcher: DataFetcherProtocol {
    /// The result to be returned by the mock data fetcher.
    var result: (Data, URLResponse)?
    /// An error to be thrown by the mock data fetcher.
    var error: Error?

    /// Performs a data request using the provided URLRequest.
    /// - Parameter request: The URLRequest to perform.
    /// - Throws: An error if set; otherwise, returns the predefined result.
    /// - Returns: A tuple containing the response data and URLResponse.
    func dataRequest(from _: URLRequest) async throws -> (Data, URLResponse) {
        if let error {
            throw error
        }
        // Return the predefined result or default values
        return result ?? (Data(), URLResponse())
    }
}
