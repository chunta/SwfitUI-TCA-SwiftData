import Foundation
@testable import ToDoList

/// A mock implementation of the `ToDoLocalServiceProtocol` for testing purposes.
final class MockToDoLocalService: ToDoLocalServiceProtocol {
    var todos: [ToDoItemData] = [] // Holds the list of ToDo items
    var error: Error? // Holds an optional error

    /// Fetches all ToDo items.
    /// - Throws: An error if one is set.
    func fetchTodos() throws -> [ToDoItemData] {
        if let error {
            throw error // Throw the error if it's set
        }
        return todos // Return the list of todos
    }

    /// Saves a ToDo item.
    /// - Parameter todo: The ToDoItemData to save.
    /// - Throws: An error if one is set.
    func save(todo: ToDoItemData) throws {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            // Update the existing item if found
            todos[index] = todo
        } else {
            // Append the new item if not found
            todos.append(todo)
        }
    }

    /// Updates an existing ToDo item.
    /// - Parameters:
    ///   - todoId: The ID of the ToDo item to update.
    ///   - newToDo: The new ToDoItem to replace the old one.
    /// - Throws: An error if one is set.
    func update(todoId: Int, newToDo: ToDoItem) throws {
        if let index = todos.firstIndex(where: { $0.id == todoId }) {
            // Update the existing item if found
            todos[index] = ToDoItemData(from: newToDo)
        }
    }

    /// Deletes a ToDo item.
    /// - Parameter todo: The ToDoItemData to delete.
    /// - Throws: An error if one is set.
    func delete(todo: ToDoItemData) throws {
        // Remove the item from the list
        todos.removeAll { $0.id == todo.id }
    }
}
