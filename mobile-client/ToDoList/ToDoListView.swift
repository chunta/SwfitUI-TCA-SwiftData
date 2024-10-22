import ComposableArchitecture
import SwiftUI

struct ToDoListView: View {
    @Bindable var store: StoreOf<ToDoListFeature>
    @State private var showAlert = true

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    Spacer().frame(height: 6)
                    if store.isLoading {
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else {
                        todoList
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
                                .background(Color(.systemGray2))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 40)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("To-Do List (\(store.todos.count))")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing:
                Button(action: {
                    store.send(.toggleEditMode)
                }) {
                    Image(systemName: store.isEditing ? "checkmark" : "pencil")
                }
            )
            .onAppear {
                store.send(.fetchToDos)
            }
            .alert($store.scope(state: \.alert, action: \.alert))
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

    private var todoList: some View {
        List {
            ForEach(store.todos) { todo in
                todoRow(todo)
            }
            .onDelete(perform: deleteTodo)
        }
        .listStyle(.plain)
        .listRowBackground(Color.clear)
    }

    private func todoRow(_ todo: ToDoItem) -> some View {
        ZStack {
            HStack {
                TodoRow(todo: todo)
                Spacer()
                if store.isEditing {
                    Button(action: {
                        guard !store.isDeleting else { return }
                        store.send(.deleteToDoItem(todo.id))
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding()

            if store.isDeleting, store.deletingTodoID == todo.id {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(width: 24, height: 24)
            }
        }
    }

    private func deleteTodo(indexSet: IndexSet) {
        for index in indexSet {
            let todo = store.todos[index]
            store.send(.deleteToDoItem(todo.id))
        }
    }

    private var addButton: some View {
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
                        .background(Color(.systemGray2))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .padding(.trailing, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct TodoRow: View {
    let todo: ToDoItem

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone.current
        return formatter
    }

    func formattedDeadline(deadline: String?) -> String {
        if let deadline, let date = dateFormatter.date(from: deadline) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .medium
            displayFormatter.timeZone = TimeZone.current
            let formattedDate = displayFormatter.string(from: date)
            let timeZoneString = deadline.hasSuffix("Z") ? "UTC" : String(deadline.suffix(5))
            return "\(formattedDate) (\(timeZoneString))"
        }
        return ""
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(todo.title)
                    .font(.headline)
                Spacer()
                Text(todo.status)
                    .padding(6)
                    .background(statusColor(for: todo.status))
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
            .padding(.vertical, 4)

            HStack {
                Text(formattedDeadline(deadline: todo.deadline ?? ""))
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Spacer()

                ForEach(todo.tags.filter { !$0.isEmpty }, id: \.self) { tag in
                    Text(tag)
                        .padding(10)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(10)
                }
            }
            .font(.subheadline)
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 5)
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case ToDoStatus.todo.rawValue:
            Color.purple
        case ToDoStatus.inProgress.rawValue:
            Color.blue
        case ToDoStatus.done.rawValue:
            Color.green
        default:
            Color.gray
        }
    }
}

#Preview {
    NavigationStack {
        ToDoListView(
            store: Store(
                initialState: ToDoListFeature.State(todos: [
                    ToDoItem(id: 0,
                             title: "Play Game",
                             deadline: "2024-12-14T12:34:56.789+0530",
                             status: ToDoStatus.todo.rawValue, tags: ["Games", "Fun"],
                             createdAt: "",
                             updatedAt: ""),
                    ToDoItem(id: 1,
                             title: "Game",
                             deadline: "2024-10-05T22:32:00.000+0800",
                             status: ToDoStatus.todo.rawValue, tags: ["Fun"],
                             createdAt: "",
                             updatedAt: ""),
                    ToDoItem(id: 2,
                             title: "Sleep",
                             deadline: "2024-10-20T09:12:57.455Z",
                             status: ToDoStatus.inProgress.rawValue,
                             tags: ["Health", "F2"],
                             createdAt: "",
                             updatedAt: ""),
                    ToDoItem(id: 3,
                             title: "Jump",
                             deadline: "2023-12-10T05:48:21.996Z",
                             status: ToDoStatus.inProgress.rawValue,
                             tags: ["F2"],
                             createdAt: "",
                             updatedAt: ""),
                ])) {
                    ToDoListFeature()
                }
        )
    }
}
