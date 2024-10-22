import Foundation

struct FetchToDoResponse: Codable {
    let success: Bool
    let data: [ToDoItem]
}

struct AddToDoResponse: Codable {
    let success: Bool
    let data: ToDoItem
}
