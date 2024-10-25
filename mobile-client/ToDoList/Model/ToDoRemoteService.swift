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

final class ToDoRemoteService: ToDoRemoteServiceProtocol {
    private let endPoint = "http://localhost:5000/todos"
    private let localService: ToDoLocalServiceProtocol
    private let dataFetcher: DataFetcherProtocol

    init(localService: ToDoLocalServiceProtocol, dataFetcher: DataFetcherProtocol) {
        self.localService = localService
        self.dataFetcher = dataFetcher
    }

    /// Handles errors and converts them into ToDoError types.
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

    func fetchToDos() async throws -> [ToDoItem] {
        do {
            let request = RequestBuilder.build(url: URL(string: endPoint)!, method: "GET", headers: nil, body: nil)
            let (data, response)
                = try await dataFetcher.dataRequest(from: request)
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

    func fetchCachedTodos() async throws -> [ToDoItem] {
        try localService.fetchTodos().map { $0.toDoItem() }
    }

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

struct ToDoServiceKey: DependencyKey {
    static var liveValue: ToDoRemoteServiceProtocol
        = ToDoRemoteService(localService: ToDoLocalService(context: ModelContext(try! ModelContainer(for: ToDoItemData.self))),
                            dataFetcher: URLSessionDataFetcher())
}

extension DependencyValues {
    var toDoService: ToDoRemoteServiceProtocol {
        get { self[ToDoServiceKey.self] }
        set { self[ToDoServiceKey.self] = newValue }
    }
}
