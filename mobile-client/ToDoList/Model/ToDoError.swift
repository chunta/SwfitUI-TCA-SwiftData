import Foundation

/// An enumeration representing errors that can occur in the ToDo application.
enum ToDoError: Error, LocalizedError, Equatable {
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse(Int)
    case localError
    case unknownError

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

    static func == (lhs: ToDoError, rhs: ToDoError) -> Bool {
        switch (lhs, rhs) {
        case let (.networkError(error1), .networkError(error2)),
             let (.decodingError(error1), .decodingError(error2)):
            (error1 as NSError).code == (error2 as NSError).code &&
                (error1.localizedDescription == error2.localizedDescription)
        case let (.invalidResponse(statusCode1), .invalidResponse(statusCode2)):
            statusCode1 == statusCode2
        case (.localError, .localError):
            true
        case (.unknownError, .unknownError):
            true
        default:
            false
        }
    }
}
