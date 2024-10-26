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
                addButton
            }
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle("All ToDos")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("\(store.todos.count)")
                        .padding(8)
                        .font(.footnote)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
            }
            .navigationBarItems(trailing:
                Button(action: {
                    store.send(.toggleEditMode)
                }) {
                    Image(systemName: store.isEditing ? "checkmark.circle" : "square.and.pencil")
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
        ScrollViewReader { scrollProxy in
            List {
                ForEach(store.todos) { todo in
                    todoRow(todo)
                }
                .deleteDisabled(true)
            }
            .listStyle(.plain)
            .listRowBackground(Color.clear)
            .onChange(of: store.insertionIndex) { _, newIndex in
                if newIndex >= 0, newIndex < store.todos.count {
                    withAnimation {
                        scrollProxy.scrollTo(store.todos[newIndex].id, anchor: .center)
                    }
                }
            }
        }
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
                    .padding(.horizontal, 6)
                }
            }
            .padding(.vertical, 3)
            .padding(.horizontal, 0)

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
                    if !store.isLoading {
                        store.send(.addButtonTapped)
                    }
                }) {
                    Image(systemName: "plus")
                        .font(Font.title.weight(.light))
                        .frame(width: 24, height: 24)
                        .padding()
                        .background(Color(.white))
                        .foregroundColor(.black)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
                .padding(.trailing, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct TodoRow: View {
    let todo: ToDoItem

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(todo.title)
                    .font(.headline)
                Spacer()
                Text(todo.status)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .padding(7)
                    .background(statusColor(for: todo.status))
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
            .padding(.vertical, 4)

            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)

                Text(ToDoDateFormatter.formattedDeadline(deadline: todo.deadline))
                    .font(.footnote)
                    .foregroundColor(.gray)

                Spacer()

                ForEach(todo.tags.filter { !$0.isEmpty }, id: \.self) { tag in
                    Text("#\(tag)")
                        .foregroundColor(.gray)
                        .padding(2)
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
