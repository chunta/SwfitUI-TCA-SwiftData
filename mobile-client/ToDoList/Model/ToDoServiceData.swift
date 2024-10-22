import SwiftData

protocol ToDoServiceDataProtocol {
    func fetchTodos() throws -> [ToDoItemData]
    func save(todo: ToDoItemData) throws
    func update(todo: ToDoItemData) throws
    func delete(todo: ToDoItemData) throws
}

class ToDoServiceData {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchTodos() throws -> [ToDoItemData] {
        let fetchDescriptor = FetchDescriptor<ToDoItemData>()
        return try context.fetch(fetchDescriptor)
    }

    func save(todo: ToDoItemData) throws {
        context.insert(todo)
        try context.save()
    }

    func update(todo _: ToDoItemData) throws {
        // Assuming `todo` is the existing item fetched from the context
        try context.save()
    }

    func delete(todo: ToDoItemData) throws {
        context.delete(todo)
        try context.save()
    }
}
