import Foundation
@testable import ToDoList

final class MockToDoLocalService: ToDoLocalServiceProtocol {
    var todos: [ToDoItemData] = []
    var error: Error?

    func fetchTodos() throws -> [ToDoItemData] {
        if let error {
            throw error
        }
        return todos
    }

    func save(todo: ToDoItemData) throws {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index] = todo
        } else {
            todos.append(todo)
        }
    }

    func update(todoId: Int, newToDo: ToDoItem) throws {
        if let index = todos.firstIndex(where: { $0.id == todoId }) {
            todos[index] = ToDoItemData(from: newToDo)
        }
    }

    func delete(todo: ToDoItemData) throws {
        todos.removeAll { $0.id == todo.id }
    }
}
