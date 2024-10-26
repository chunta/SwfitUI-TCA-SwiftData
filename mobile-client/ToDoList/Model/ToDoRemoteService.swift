import Combine
import ComposableArchitecture
import Foundation
import SwiftData

/// A protocol defining the contract for remote ToDo service operations.
protocol ToDoRemoteServiceProtocol {
    /// Fetches the list of ToDo items from the remote server.
    /// - Throws: An error of type `ToDoError` if the fetch operation fails.
    /// - Returns: An array of `ToDoItem` objects.
    func fetchToDos() async throws -> [ToDoItem]

    /// Fetches cached ToDo items from local storage.
    /// - Throws: An error of type `ToDoError` if the fetch operation fails.
    /// - Returns: An array of `ToDoItem` objects from local storage.
    func fetchCachedTodos() async throws -> [ToDoItem]

    /// Posts a new ToDo item to the remote server.
    /// - Parameter todo: The `ToDoItem` to be added.
    /// - Throws: An error of type `ToDoError` if the post operation fails.
    /// - Returns: The newly created `ToDoItem` object from the server.
    func postToDo(_ todo: ToDoItem) async throws -> ToDoItem

    /// Deletes a ToDo item from the remote server by its ID.
    /// - Parameter id: The unique identifier of the ToDo item to be deleted.
    /// - Throws: An error of type `ToDoError` if the delete operation fails.
    func deleteToDo(id: Int) async throws
}

/// A concrete implementation of the `ToDoRemoteServiceProtocol`.
final class ToDoRemoteService: ToDoRemoteServiceProtocol {
    private let endPoint = "http://localhost:5000/todos"
    private let localService: ToDoLocalServiceProtocol
    private let dataFetcher: DataFetcherProtocol

    /// Initializes a new instance of `ToDoRemoteService`.
    /// - Parameters:
    ///   - localService: An instance conforming to `ToDoLocalServiceProtocol` for local operations.
    ///   - dataFetcher: An instance conforming to `DataFetcherProtocol` for network requests.
    init(localService: ToDoLocalServiceProtocol, dataFetcher: DataFetcherProtocol) {
        self.localService = localService
        self.dataFetcher = dataFetcher
    }

    /// Handles errors and converts them into `ToDoError` types.
    /// - Parameter error: The original error encountered.
    /// - Throws: A `ToDoError` based on the type of the original error.
    private func handleError(_ error: Error) throws -> Never {
        if let toDoError = error as? ToDoError {
            throw toDoError
        }

        switch error {
        case let urlError as URLError:
            throw ToDoError.networkError(urlError)
        case let decodingError as DecodingError:
            throw ToDoError.decodingError(decodingError)
        default:
            throw ToDoError.unknownError
        }
    }

    /// Fetches the list of ToDo items from the remote server and synchronizes local data.
    /// - Throws: An error of type `ToDoError` if the fetch operation fails.
    /// - Returns: An array of `ToDoItem` objects from the remote server.
    func fetchToDos() async throws -> [ToDoItem] {
        do {
            let request = RequestBuilder.build(url: URL(string: endPoint)!, method: "GET", headers: nil, body: nil)
            let (data, response) = try await dataFetcher.dataRequest(from: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ToDoError.invalidResponse(0)
            }
            guard (200 ... 299).contains(httpResponse.statusCode) else {
                throw ToDoError.invalidResponse(httpResponse.statusCode)
            }
            let decodedResponse = try JSONDecoder().decode(FetchToDoResponse.self, from: data)
            var remoteTodos = decodedResponse.data

            // Sort remote todos by deadline (nil values will be placed at the end)
            remoteTodos.sortedByDeadline()

            // Sync local data with remote data:
            // 1. For each remote ToDo, update the matching local item if IDs match, replacing its properties.
            // 2. If no match is found, insert the remote item as a new local record.
            let localTodos = try localService.fetchTodos()
            let remoteTodoIDs = Set(remoteTodos.map(\.id))

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

    /// Fetches cached ToDo items from local storage.
    /// - Throws: An error of type `ToDoError` if the fetch operation fails.
    /// - Returns: An array of `ToDoItem` objects from local storage.
    func fetchCachedTodos() async throws -> [ToDoItem] {
        try localService.fetchTodos().map { $0.toDoItem() }
    }

    /// Posts a new ToDo item to the remote server.
    /// - Parameter todo: The `ToDoItem` to be added.
    /// - Throws: An error of type `ToDoError` if the post operation fails.
    /// - Returns: The newly created `ToDoItem` object from the server.
    func postToDo(_ todo: ToDoItem) async throws -> ToDoItem {
        do {
            let encodedData = try JSONEncoder().encode(todo)
            let request = RequestBuilder.build(url: URL(string: endPoint)!, method: "POST", headers: ["Content-Type": "application/json"], body: encodedData)
            let (data, response) = try await dataFetcher.dataRequest(from: request)
            guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
                throw ToDoError.invalidResponse((response as? HTTPURLResponse)?.statusCode ?? 0)
            }
            let decodedResponse = try JSONDecoder().decode(AddToDoResponse.self, from: data)
            guard decodedResponse.success else {
                throw ToDoError.invalidResponse(httpResponse.statusCode)
            }

            // Save the new ToDo item in local storage
            let newLocalTodo = ToDoItemData(from: decodedResponse.data)
            try localService.save(todo: newLocalTodo)

            return decodedResponse.data
        } catch {
            try handleError(error)
        }
    }

    /// Deletes a ToDo item from the remote server by its ID.
    /// - Parameter id: The unique identifier of the ToDo item to be deleted.
    /// - Throws: An error of type `ToDoError` if the delete operation fails.
    func deleteToDo(id: Int) async throws {
        do {
            let deleteURL = "\(endPoint)/\(id)"
            let request = RequestBuilder.build(url: URL(string: deleteURL)!, method: "DELETE", headers: nil, body: nil)
            let (_, response) = try await dataFetcher.dataRequest(from: request)
            guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
                throw ToDoError.invalidResponse((response as? HTTPURLResponse)?.statusCode ?? 0)
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

/// A key for dependency injection of the ToDo remote service.
struct ToDoServiceKey: DependencyKey {
    static var liveValue: ToDoRemoteServiceProtocol
        = ToDoRemoteService(localService: ToDoLocalService(context: ModelContext(try! ModelContainer(for: ToDoItemData.self))),
                            dataFetcher: URLSessionDataFetcher())
}

extension DependencyValues {
    /// A computed property to access the ToDo remote service in the dependency container.
    var toDoService: ToDoRemoteServiceProtocol {
        get { self[ToDoServiceKey.self] }
        set { self[ToDoServiceKey.self] = newValue }
    }
}
