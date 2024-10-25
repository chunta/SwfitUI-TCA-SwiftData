import Foundation

// Extensions for ToDoItemData
extension [ToDoItemData] {
    mutating func sortedByDeadline() {
        sort { first, second in
            let firstDeadline = ToDoDateFormatter.isoDateFormatter.date(from: first.deadline ?? "") ?? Date.distantFuture
            let secondDeadline = ToDoDateFormatter.isoDateFormatter.date(from: second.deadline ?? "") ?? Date.distantFuture
            return firstDeadline < secondDeadline
        }
    }
}

// Extensions for ToDoItem
extension [ToDoItem] {
    mutating func sortedByDeadline() {
        sort { first, second in
            let firstDeadline = ToDoDateFormatter.isoDateFormatter.date(from: first.deadline ?? "") ?? Date.distantFuture
            let secondDeadline = ToDoDateFormatter.isoDateFormatter.date(from: second.deadline ?? "") ?? Date.distantFuture
            return firstDeadline < secondDeadline
        }
    }
}
