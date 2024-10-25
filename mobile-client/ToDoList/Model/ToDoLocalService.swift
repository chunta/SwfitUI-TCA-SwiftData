import Foundation
import SwiftData

protocol ToDoLocalServiceProtocol {
    func fetchTodos() throws -> [ToDoItemData]
    func save(todo: ToDoItemData) throws
    func update(todoId: Int, newToDo: ToDoItem) throws
    func delete(todo: ToDoItemData) throws
}

class ToDoLocalService: ToDoLocalServiceProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchTodos() throws -> [ToDoItemData] {
        let fetchDescriptor = FetchDescriptor<ToDoItemData>()
        var todos = try context.fetch(fetchDescriptor)
        todos.sortedByDeadline()
        return todos
    }

    func save(todo: ToDoItemData) throws {
        context.insert(todo)
        try context.save()
    }

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

    func delete(todo: ToDoItemData) throws {
        context.delete(todo)
        try context.save()
    }
}
