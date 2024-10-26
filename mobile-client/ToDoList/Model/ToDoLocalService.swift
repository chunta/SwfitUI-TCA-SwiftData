import Foundation
import SwiftData

/// Protocol defining the core local storage operations for ToDo items.
protocol ToDoLocalServiceProtocol {
    /// Fetches all ToDo items from local storage.
    /// - Returns: An array of `ToDoItemData` instances.
    /// - Throws: An error if fetching fails.
    func fetchTodos() throws -> [ToDoItemData]

    /// Saves a new ToDo item to local storage.
    /// - Parameter todo: The `ToDoItemData` instance to save.
    /// - Throws: An error if saving fails.
    func save(todo: ToDoItemData) throws

    /// Updates an existing ToDo item in local storage by ID.
    /// - Parameters:
    ///   - todoId: The unique identifier of the ToDo item to update.
    ///   - newToDo: The updated `ToDoItem` instance with new data.
    /// - Throws: An error if updating fails.
    func update(todoId: Int, newToDo: ToDoItem) throws

    /// Deletes a ToDo item from local storage.
    /// - Parameter todo: The `ToDoItemData` instance to delete.
    /// - Throws: An error if deleting fails.
    func delete(todo: ToDoItemData) throws
}

/// Service class implementing `ToDoLocalServiceProtocol` for managing local ToDo item storage.
class ToDoLocalService: ToDoLocalServiceProtocol {
    private let context: ModelContext

    /// Initializes the service with a provided data model context.
    /// - Parameter context: The `ModelContext` for interacting with the local database.
    init(context: ModelContext) {
        self.context = context
    }

    /// Fetches all ToDo items from local storage, sorted by deadline.
    /// - Returns: A sorted array of `ToDoItemData` instances.
    /// - Throws: An error if fetching fails.
    func fetchTodos() throws -> [ToDoItemData] {
        let fetchDescriptor = FetchDescriptor<ToDoItemData>()
        var todos = try context.fetch(fetchDescriptor)
        todos.sortedByDeadline()
        return todos
    }

    /// Saves a new ToDo item to local storage.
    /// - Parameter todo: The `ToDoItemData` instance to save.
    /// - Throws: An error if saving fails.
    func save(todo: ToDoItemData) throws {
        context.insert(todo)
        try context.save()
    }

    /// Updates an existing ToDo item in local storage.
    /// - Parameters:
    ///   - todoId: The unique identifier of the ToDo item to update.
    ///   - newToDo: The updated `ToDoItem` instance with new values.
    /// - Throws: An error if the update operation fails.
    func update(todoId: Int, newToDo: ToDoItem) throws {
        var descriptor = FetchDescriptor<ToDoItemData>(
            predicate: #Predicate<ToDoItemData> { $0.id == todoId }
        )
        descriptor.fetchLimit = 1
        do {
            if let existingToDo = try context.fetch(descriptor).first {
                existingToDo.title = newToDo.title
                existingToDo.deadline = newToDo.deadline
                existingToDo.status = newToDo.status
                existingToDo.tags = newToDo.tags.map { Tag(name: $0) }
                existingToDo.updatedAt = newToDo.updatedAt
                try context.save()
            }
        } catch {
            throw error
        }
    }

    /// Deletes a ToDo item from local storage.
    /// - Parameter todo: The `ToDoItemData` instance to delete.
    /// - Throws: An error if the delete operation fails.
    func delete(todo: ToDoItemData) throws {
        context.delete(todo)
        try context.save()
    }
}
