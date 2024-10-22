import Combine
import ComposableArchitecture
import Foundation

protocol ToDoServiceProtocol {
    func fetchToDos() async throws -> [ToDoItem]
    func postToDo(_ todo: ToDoItem) async throws -> ToDoItem
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

    private func handleError(_ error: Error) throws -> Never {
        if let urlError = error as? URLError {
            throw ToDoServiceError.networkError(urlError)
        } else if let decodingError = error as? DecodingError {
            throw ToDoServiceError.decodingError(decodingError)
        } else {
            throw error
        }
    }

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
            let decodedResponse = try JSONDecoder().decode(FetchToDoResponse.self, from: data)
            return decodedResponse.data

        } catch {
            try handleError(error)
        }
    }

    func postToDo(_ todo: ToDoItem) async throws -> ToDoItem {
        let url = URL(string: "http://localhost:5000/todos")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let encodedData = try JSONEncoder().encode(todo)
            let (data, response) = try await URLSession.shared.upload(for: request, from: encodedData)
            guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
                throw ToDoServiceError.invalidResponse((response as? HTTPURLResponse)?.statusCode ?? 0)
            }
            let decodedResponse = try JSONDecoder().decode(AddToDoResponse.self, from: data)
            guard decodedResponse.success else {
                throw ToDoServiceError.invalidResponse(httpResponse.statusCode)
            }
            return decodedResponse.data
        } catch {
            try handleError(error)
        }
    }
}

struct ToDoServiceKey: DependencyKey {
    static var liveValue: ToDoServiceProtocol = ToDoService.shared
}

extension DependencyValues {
    var toDoService: ToDoServiceProtocol {
        get { self[ToDoServiceKey.self] }
        set { self[ToDoServiceKey.self] = newValue }
    }
}
