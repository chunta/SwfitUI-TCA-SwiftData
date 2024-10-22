import SwiftData
import SwiftUI

struct ToDoItem: Identifiable, Codable, Equatable {
    var id: Int
    var title: String
    var deadline: String?
    var status: String
    var tags: [String]
    var createdAt: String
    var updatedAt: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(deadline, forKey: .deadline)
        try container.encode(status, forKey: .status)
        try container.encode(tags, forKey: .tags)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

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
