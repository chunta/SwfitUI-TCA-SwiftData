import Foundation
@testable import ToDoList

final class MockDataFetcher: DataFetcherProtocol {
    var result: (Data, URLResponse)?
    var error: Error?
    func dataRequest(from _: URLRequest) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }
        return result ?? (Data(), URLResponse())
    }
}
