import Foundation

struct AddToDoResponse: Codable {
    let success: Bool
    let data: ToDoItem
}

struct FetchToDoResponse: Codable {
    let success: Bool
    let data: [ToDoItem]
}
