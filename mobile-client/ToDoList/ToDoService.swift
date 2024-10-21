
import Combine
import ComposableArchitecture
import Foundation

// A service that handles fetching to-do items from a remote server
struct ToDoService {
    var fetchToDoItems: () -> Effect<[ToDoItem]>
    var updateToDoItem: (ToDoItem) -> Effect<ToDoItem>
    var deleteToDoItem: (Int) -> Effect<Int>
}
