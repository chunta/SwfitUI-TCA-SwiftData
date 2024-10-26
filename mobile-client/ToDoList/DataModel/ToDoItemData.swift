import SwiftData

/// Represents a tag associated with a to-do item, allowing
/// for encoding/decoding of tags in the app.
struct Tag: Codable {
    let name: String
}

/// A SwiftData model representing a to-do item, including properties such as
/// `id`, `title`, and `tags` for flexible management within the app.
@Model
class ToDoItemData: Identifiable {
    @Attribute(.unique) var id: Int
    var title: String
    var deadline: String?
    var status: String
    var tags: [Tag]
    var createdAt: String
    var updatedAt: String

    /// Initializes a new `ToDoItemData` instance with the provided properties.
    ///
    /// - Parameters:
    ///   - id: Unique identifier of the to-do item.
    ///   - title: Title or description of the to-do item.
    ///   - deadline: Optional ISO 8601 formatted deadline as a string.
    ///   - status: Current status of the item (e.g., "pending", "completed").
    ///   - tags: Array of associated `Tag` instances for categorization.
    ///   - createdAt: ISO 8601 formatted creation timestamp.
    ///   - updatedAt: ISO 8601 formatted last updated timestamp.
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

    /// Convenience initializer to create `ToDoItemData` from a `ToDoItem`.
    /// Maps `tags` from an array of strings to `Tag` objects.
    ///
    /// - Parameter todoItem: The `ToDoItem` instance to be converted.
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

    /// Converts the `ToDoItemData` instance back to a `ToDoItem` instance,
    /// with `tags` converted from `Tag` objects to an array of tag names as strings.
    ///
    /// - Returns: A `ToDoItem` with the properties copied from `ToDoItemData`.
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
