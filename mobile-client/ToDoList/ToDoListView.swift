
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
        .sheet(
            item: $store.scope(state: \.addToDo, action: \.addToDo)
        ) { addContactStore in
            NavigationStack {
                AddToDoView(store: addContactStore)
            }
            .presentationDetents([.height(570)])
        }
    }
}

#Preview {
    NavigationStack {
        ToDoListView(
            store: Store(
                initialState: ToDoListFeature.State(todos: [
                    ToDoItem(id: 0, title: "Play Game", deadline: "", status: "", tag: "", createdAt: "", updatedAt: ""),
                    ToDoItem(id: 1, title: "Sleep", deadline: "", status: "", tag: "", createdAt: "", updatedAt: ""),
                ])) {
                    ToDoListFeature()
                }
        )
    }
}
