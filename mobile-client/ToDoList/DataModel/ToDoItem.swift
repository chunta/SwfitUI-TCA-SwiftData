import SwiftUI

/// A model representing a To-Do item, including details such as its ID, title, deadline,
/// status, tags, and timestamps for creation and last update.
///
/// Conforms to `Identifiable`, `Codable`, and `Equatable` for use in SwiftUI lists, encoding/decoding,
/// and equality checks.
///
/// - Properties:
///   - id: Unique identifier for the to-do item.
///   - title: Title or description of the to-do task.
///   - deadline: Optional deadline for the task, formatted as a string.
///   - status: Current status of the task (e.g., "pending", "completed").
///   - tags: Array of tags or categories associated with the task.
///   - createdAt: Timestamp representing the creation date, formatted as a string.
///   - updatedAt: Timestamp representing the last update, formatted as a string.
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
