import Foundation

/// An enumeration representing various errors that can occur in the ToDo application.
enum ToDoError: Error, LocalizedError, Equatable {
    /// Error occurring due to network-related issues, wrapping an underlying `Error`.
    case networkError(Error)
    /// Error occurring during the decoding process, wrapping a `DecodingError`.
    case decodingError(Error)
    /// Error for an invalid server response, capturing the status code.
    case invalidResponse(Int)
    /// Error representing a general local issue, such as an issue fetching local data.
    case localError
    /// Error for an unknown issue when the exact cause is indeterminate.
    case unknownError

    /// Provides a user-friendly description for each error type.
    var errorDescription: String? {
        switch self {
        case let .networkError(error):
            "Network error: \(error.localizedDescription)"
        case let .decodingError(error):
            "Decoding error: \(error.localizedDescription)"
        case let .invalidResponse(statusCode):
            "Invalid response from server: \(statusCode)"
        case .localError:
            "Unknown local error while fetching local storage data"
        case .unknownError:
            "Unknown error"
        }
    }

    /// Equatable conformance to compare two `ToDoError` values for equality.
    /// Custom logic is used to handle error comparison by comparing underlying error codes and descriptions.
    static func == (lhs: ToDoError, rhs: ToDoError) -> Bool {
        switch (lhs, rhs) {
        case let (.networkError(error1), .networkError(error2)),
             let (.decodingError(error1), .decodingError(error2)):
            (error1 as NSError).code == (error2 as NSError).code &&
                (error1.localizedDescription == error2.localizedDescription)
        case let (.invalidResponse(statusCode1), .invalidResponse(statusCode2)):
            statusCode1 == statusCode2
        case (.localError, .localError),
             (.unknownError, .unknownError):
            true
        default:
            false
        }
    }
}
