import Foundation

// Extensions for sorting ToDoItemData array by deadline.
extension [ToDoItemData] {
    /// Sorts the `ToDoItemData` array by the `deadline` property, placing items
    /// with the earliest deadlines at the beginning of the array. Items without
    /// a specified deadline are considered to have a deadline of `Date.distantFuture`.
    mutating func sortedByDeadline() {
        sort { first, second in
            let firstDeadline = ToDoDateFormatter.isoDateFormatter.date(from: first.deadline ?? "") ?? Date.distantFuture
            let secondDeadline = ToDoDateFormatter.isoDateFormatter.date(from: second.deadline ?? "") ?? Date.distantFuture
            return firstDeadline < secondDeadline
        }
    }
}

// Extensions for sorting ToDoItem array by deadline.
extension [ToDoItem] {
    /// Sorts the `ToDoItem` array by the `deadline` property, placing items
    /// with the earliest deadlines at the beginning of the array. Items without
    /// a specified deadline are considered to have a deadline of `Date.distantFuture`.
    mutating func sortedByDeadline() {
        sort { first, second in
            let firstDeadline = ToDoDateFormatter.isoDateFormatter.date(from: first.deadline ?? "") ?? Date.distantFuture
            let secondDeadline = ToDoDateFormatter.isoDateFormatter.date(from: second.deadline ?? "") ?? Date.distantFuture
            return firstDeadline < secondDeadline
        }
    }
}
