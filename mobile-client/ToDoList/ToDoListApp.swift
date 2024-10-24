import ComposableArchitecture
import SwiftUI

@main
struct ToDoListApp: App {
    static let todoListStore = Store(
        initialState: ToDoListReducer.State())
    {
        ToDoListReducer()
    }

    var body: some Scene {
        WindowGroup {
            ToDoListView(store: ToDoListApp.todoListStore)
        }
    }
}
