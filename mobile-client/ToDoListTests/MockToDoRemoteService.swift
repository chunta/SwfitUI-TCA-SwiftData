import Foundation
@testable import ToDoList

/// A mock implementation of the `ToDoRemoteServiceProtocol` for testing purposes.
final class MockToDoRemoteService: ToDoRemoteServiceProtocol {
    var todos: [ToDoItem] = []
    var error: Error?

    /// Fetches the ToDo items.
    /// - Throws: An error if one is set.
    /// - Returns: An array of ToDoItem.
    func fetchToDos() async throws -> [ToDoItem] {
        if let error {
            throw error
        }
        return todos
    }

    /// Fetches cached ToDo items.
    /// - Throws: An error if one is set.
    /// - Returns: An array of ToDoItem.
    func fetchCachedTodos() async throws -> [ToDoItem] {
        if let error {
            throw error
        }
        return todos
    }

    /// Posts a new ToDo item.
    /// - Parameter todo: The ToDoItem to post.
    /// - Throws: An error if one is set.
    /// - Returns: The posted ToDoItem.
    func postToDo(_ todo: ToDoItem) async throws -> ToDoItem {
        if let error {
            throw error
        }
        // Append the new ToDo item to the list
        todos.append(todo)
        return todo
    }

    /// Deletes a ToDo item by its ID.
    /// - Parameter id: The ID of the ToDoItem to delete.
    /// - Throws: An error if one is set or if the ToDo item is not found.
    func deleteToDo(id: Int) async throws {
        if let error {
            throw error
        }
        // Remove the ToDo item with the specified ID
        if let index = todos.firstIndex(where: { $0.id == id }) {
            todos.remove(at: index)
        } else {
            throw ToDoError.invalidResponse(404)
        }
    }
}
