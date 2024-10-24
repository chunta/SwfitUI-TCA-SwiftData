import SwiftData

// Represents a tag for a todo item, used for encoding/decoding
// and managing associated tags in the app.
struct Tag: Codable {
    let name: String
}

@Model
class ToDoItemData: Identifiable {
    @Attribute(.unique) var id: Int
    var title: String
    var deadline: String?
    var status: String
    var tags: [Tag]
    var createdAt: String
    var updatedAt: String
    init(id: Int,
         title: String,
         deadline: String?,
         status: String,
         tags: [Tag],
         createdAt: String,
         updatedAt: String)
    {
        self.id = id
        self.title = title
        self.deadline = deadline
        self.status = status
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    convenience init(from todoItem: ToDoItem) {
        let tags = todoItem.tags.map { Tag(name: $0) }
        self.init(
            id: todoItem.id,
            title: todoItem.title,
            deadline: todoItem.deadline,
            status: todoItem.status,
            tags: tags,
            createdAt: todoItem.createdAt,
            updatedAt: todoItem.updatedAt
        )
    }

    func toDoItem() -> ToDoItem {
        let tags = tags.map(\.name)
        return ToDoItem(
            id: id,
            title: title,
            deadline: deadline,
            status: status,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
