import SwiftData

@Model
class ToDoItemData: Identifiable {
    @Attribute(.unique) var id: Int
    var title: String
    var deadline: String?
    var status: String
    var tags: [String]
    var createdAt: String
    var updatedAt: String

    init(id: Int, title: String, deadline: String?, status: String, tags: [String], createdAt: String, updatedAt: String) {
        self.id = id
        self.title = title
        self.deadline = deadline
        self.status = status
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
