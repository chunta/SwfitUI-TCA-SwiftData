
import ComposableArchitecture
import SwiftUI

struct ToDoListView: View {
    @Bindable var store: StoreOf<ToDoListFeature>

    var body: some View {
        NavigationStack {
            Button("Add To-Do") {
                store.send(.addButtonTapped)
            }
            .padding()

            List {
                ForEach(store.todos) { todo in
                    HStack {
                        Text("\(todo.id)")
                        Text(todo.title)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let todo = store.todos[index]
                        store.send(.deleteToDoItem(todo.id))
                    }
                }
            }
        }
        .sheet(
            item: $store.scope(state: \.addToDo, action: \.addToDo)
        ) { addContactStore in
            NavigationStack {
                AddToDoView(store: addContactStore)
            }
        }
    }
}
