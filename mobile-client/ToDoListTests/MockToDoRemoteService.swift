import Foundation
@testable import ToDoList

final class MockToDoRemoteService: ToDoRemoteServiceProtocol {
    var todos: [ToDoItem] = []
    var error: Error?

    func fetchToDos() async throws -> [ToDoItem] {
        if let error {
            throw error
        }
        return todos
    }

    func fetchCachedTodos() async throws -> [ToDoItem] {
        if let error {
            throw error
        }
        return todos
    }

    func postToDo(_ todo: ToDoItem) async throws -> ToDoItem {
        if let error {
            throw error
        }
        todos.append(todo)
        return todo
    }

    func deleteToDo(id: Int) async throws {
        if let error {
            throw error
        }
        if let index = todos.firstIndex(where: { $0.id == id }) {
            todos.remove(at: index)
        } else {
            throw ToDoError.invalidResponse(404)
        }
    }
}
