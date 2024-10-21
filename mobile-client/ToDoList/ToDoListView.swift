
import ComposableArchitecture
import SwiftUI

struct ToDoListView: View {
    @Bindable var store: StoreOf<ToDoListFeature>

    var body: some View {
        NavigationStack {
            ZStack {
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

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            store.send(.addButtonTapped)
                        }) {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .padding()
                                .background(Color(.systemGray3))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("To-Do List")
            .navigationBarTitleDisplayMode(.large)
        }
        .fullScreenCover(
            item: $store.scope(state: \.addToDo, action: \.addToDo)
        ) { addContactStore in
            NavigationStack {
                AddToDoView(store: addContactStore)
            }
            .presentationDetents([.large])
        }
    }
}

#Preview {
    NavigationStack {
        ToDoListView(
            store: Store(
                initialState: ToDoListFeature.State(todos: [
                    ToDoItem(id: 1, title: "Buy groceries", deadline: "", createdAt: "", updatedAt: ""),
                    ToDoItem(id: 2, title: "Walk the dog", deadline: "", createdAt: "", updatedAt: ""),
                ])) {
                    ToDoListFeature()
                }
        )
    }
}
