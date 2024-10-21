
import Combine
import ComposableArchitecture
import Foundation

protocol ToDoServiceProtocol {
    func fetchToDos() async throws -> [ToDoItem]
}

enum ToDoServiceError: Error, LocalizedError {
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse(Int)

    var errorDescription: String? {
        switch self {
        case let .networkError(error):
            "Network error: \(error.localizedDescription)"
        case let .decodingError(error):
            "Decoding error: \(error.localizedDescription)"
        case let .invalidResponse(statusCode):
            "Invalid response from server: \(statusCode)"
        }
    }
}

final class ToDoService: ToDoServiceProtocol {
    static let shared = ToDoService()

    private init() {}

    func fetchToDos() async throws -> [ToDoItem] {
        let url = URL(string: "http://localhost:5000/todos")!

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ToDoServiceError.invalidResponse(0)
            }

            guard (200 ... 299).contains(httpResponse.statusCode) else {
                throw ToDoServiceError.invalidResponse(httpResponse.statusCode)
            }

            // Convert incoming data to a string for logging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Incoming response: \(responseString)")
            } else {
                print("Failed to convert data to string")
            }

            // Decode the data into ToDoResponse
            let decodedResponse = try JSONDecoder().decode(ToDoResponse.self, from: data)

            // Return the array of ToDoItem from the decoded response
            return decodedResponse.data

        } catch {
            // Handle specific errors
            if let urlError = error as? URLError {
                throw ToDoServiceError.networkError(urlError)
            } else if let decodingError = error as? DecodingError {
                throw ToDoServiceError.decodingError(decodingError)
            } else {
                throw error // Re-throw any other unexpected error
            }
        }
    }
}
