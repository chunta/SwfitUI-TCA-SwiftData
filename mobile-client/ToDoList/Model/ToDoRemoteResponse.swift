import Foundation

/// A response model representing the result of adding a new ToDo item.
struct AddToDoResponse: Codable {
    /// Indicates whether the add operation was successful.
    let success: Bool
    /// The newly added `ToDoItem` data returned from the server.
    let data: ToDoItem
}

/// A response model representing the result of fetching multiple ToDo items.
struct FetchToDoResponse: Codable {
    /// Indicates whether the fetch operation was successful.
    let success: Bool
    /// An array of `ToDoItem` data returned from the server.
    let data: [ToDoItem]
}
