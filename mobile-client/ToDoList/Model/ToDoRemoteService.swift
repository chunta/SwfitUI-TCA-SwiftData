import Combine
import ComposableArchitecture
import Foundation
import SwiftData

protocol ToDoRemoteServiceProtocol {
    func fetchToDos() async throws -> [ToDoItem]
    func fetchCachedTodos() async throws -> [ToDoItem]
    func postToDo(_ todo: ToDoItem) async throws -> ToDoItem
    func deleteToDo(id: Int) async throws
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

final class ToDoRemoteService: ToDoRemoteServiceProtocol {
    private let localService: ToDoLocalServiceProtocol

    init(localService: ToDoLocalServiceProtocol) {
        self.localService = localService
    }

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
            try await Task.sleep(nanoseconds: 2_000_000_000)
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ToDoServiceError.invalidResponse(0)
            }
            guard (200 ... 299).contains(httpResponse.statusCode) else {
                throw ToDoServiceError.invalidResponse(httpResponse.statusCode)
            }
            let decodedResponse = try JSONDecoder().decode(FetchToDoResponse.self, from: data)
            let remoteTodos = decodedResponse.data

            // Sync local data with remote data:
            // 1. For each remote ToDo, update the matching local item if IDs match, replacing its properties.
            // 2. If no match is found, insert the remote item as a new local record.
            let localTodos = try localService.fetchTodos()
            let remoteTodoIDs = Set(remoteTodos.map { $0.id })

            // Update or insert local todos
            for remoteTodo in remoteTodos {
                if let _ = localTodos.first(where: { $0.id == remoteTodo.id }) {
                    try localService.update(todoId: remoteTodo.id, newToDo: remoteTodo)
                } else {
                    let newLocalTodo = ToDoItemData(from: remoteTodo)
                    try localService.save(todo: newLocalTodo)
                }
            }

            // Delete local todos that are not present in remote data
            for localTodo in localTodos {
                if !remoteTodoIDs.contains(localTodo.id) {
                    try localService.delete(todo: localTodo)
                }
            }
            return remoteTodos
        } catch {
            print("Error fetching remote todos: \(error.localizedDescription)")
            try handleError(error)
        }
    }

    func fetchCachedTodos() async throws -> [ToDoItem] {
        return try localService.fetchTodos().map { $0.toDoItem() }
    }

    func postToDo(_ todo: ToDoItem) async throws -> ToDoItem {
        let url = URL(string: "http://localhost:5000/todos")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            let encodedData = try JSONEncoder().encode(todo)
            let (data, response) = try await URLSession.shared.upload(for: request, from: encodedData)
            guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
                throw ToDoServiceError.invalidResponse((response as? HTTPURLResponse)?.statusCode ?? 0)
            }
            let decodedResponse = try JSONDecoder().decode(AddToDoResponse.self, from: data)
            guard decodedResponse.success else {
                throw ToDoServiceError.invalidResponse(httpResponse.statusCode)
            }

            // Save the new ToDo item in local storage
            let newLocalTodo = ToDoItemData(from: decodedResponse.data)
            try localService.save(todo: newLocalTodo)

            return decodedResponse.data
        } catch {
            try handleError(error)
        }
    }

    func deleteToDo(id: Int) async throws {
        let url = URL(string: "http://localhost:5000/todos/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        do {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
                throw ToDoServiceError.invalidResponse((response as? HTTPURLResponse)?.statusCode ?? 0)
            }

            // Delete the local ToDo item
            let localTodos = try localService.fetchTodos()
            if let matchingLocalTodo = localTodos.first(where: { $0.id == id }) {
                try localService.delete(todo: matchingLocalTodo)
            }
        } catch {
            try handleError(error)
        }
    }
}

struct ToDoServiceKey: DependencyKey {
    static var liveValue: ToDoRemoteServiceProtocol
        = ToDoRemoteService(localService: ToDoLocalService(context: ModelContext(try! ModelContainer(for: ToDoItemData.self))))
}

extension DependencyValues {
    var toDoService: ToDoRemoteServiceProtocol {
        get { self[ToDoServiceKey.self] }
        set { self[ToDoServiceKey.self] = newValue }
    }
}
