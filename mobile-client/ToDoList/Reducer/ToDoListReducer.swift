import ComposableArchitecture
import Foundation

@Reducer
struct ToDoListReducer {
    @ObservableState
    struct State: Equatable {
        @Presents var addToDo: AddToDoReducer.State?
        var todos: IdentifiedArrayOf<ToDoItem> = []
        var isLoading: Bool = false
        var error: String?
        var isDeleting: Bool = false
        var deletingTodoID: Int?
        var isEditing: Bool = false
        var editingTodoId: Int?
        var insertionIndex: Int = 0
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: Equatable {
        case toggleEditMode
        case addButtonTapped
        case addToDo(PresentationAction<AddToDoReducer.Action>)
        case fetchToDos
        case fetchToDosResponse(Result<[ToDoItem], ToDoError>)
        case deleteToDoItem(Int)
        case deleteToDoResponse(Result<Int, ToDoError>)
        case alert(PresentationAction<Alert>)
        @CasePathable
        enum Alert {
            case useLocalData
            case retry
            case leaveApp
        }
    }

    @Dependency(\.toDoService) var toDoService

    func binaryInsertionIndex(_ todos: inout IdentifiedArrayOf<ToDoItem>, newTodo: ToDoItem) -> Int {
        var left = 0
        var right = todos.count - 1
        let newDeadline = newTodo.deadline.flatMap { ToDoDateFormatter.isoDateFormatter.date(from: $0) } ?? Date.distantFuture

        while left <= right {
            let mid = left + (right - left) / 2
            let midDeadline = todos[mid].deadline.flatMap { ToDoDateFormatter.isoDateFormatter.date(from: $0) } ?? Date.distantFuture

            if newDeadline < midDeadline {
                right = mid - 1
            } else {
                left = mid + 1
            }
        }

        return left
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert(.presented(.useLocalData)):
                state.isLoading = true
                state.error = nil
                return .run { send in
                    do {
                        let toDos = try await toDoService.fetchCachedTodos()
                        await send(.fetchToDosResponse(.success(toDos)))
                    } catch {
                        await send(.fetchToDosResponse(.failure(.localError)))
                    }
                }

            case .alert(.presented(.retry)):
                state.alert = nil
                return .send(.fetchToDos)

            case .alert(.presented(.leaveApp)):
                state.alert = nil
                exit(-1)
                return .none

            case .alert(.dismiss):
                state.alert = nil
                return .none

            case .toggleEditMode:
                state.isEditing.toggle()
                return .none

            case .addButtonTapped:
                state.addToDo = AddToDoReducer.State(todo: ToDoItem(id: 0, title: "", deadline: nil, status: "", tags: [], createdAt: "", updatedAt: ""))
                return .none

            case .addToDo(.presented(.cancelButtonTapped)):
                state.addToDo = nil
                return .none

            case let .addToDo(.presented(.saveResponse(.success(todo)))):
                let index = binaryInsertionIndex(&state.todos, newTodo: todo)

                state.insertionIndex = index

                state.todos.insert(todo, at: index)

                state.addToDo = nil
                return .none

            case .addToDo:
                return .none

            case .fetchToDos:
                state.isLoading = true
                state.error = nil
                return .run { send in
                    do {
                        let toDos = try await toDoService.fetchToDos()
                        await send(.fetchToDosResponse(.success(toDos)))
                    } catch {
                        await send(.fetchToDosResponse(.failure(.networkError(error))))
                    }
                }

            case let .fetchToDosResponse(.success(todos)):
                state.isLoading = false
                state.todos = IdentifiedArrayOf(uniqueElements: todos)
                return .none

            case let .fetchToDosResponse(.failure(error)):
                state.isLoading = false
                if error == .localError {
                    state.error = error.localizedDescription
                    state.alert = .init(
                        title: { TextState("Local Data Error") },
                        actions: {
                            ButtonState(role: .cancel, action: .leaveApp) {
                                TextState("Leave App")
                            }
                        },
                        message: { TextState("We couldn't access your local data at the moment. Please leave the app and try again later.") }
                    )
                } else {
                    // Set alert for other types of errors
                    state.error = error.localizedDescription
                    state.alert = .init(
                        title: { TextState("Failed to Fetch ToDo List!") },
                        actions: {
                            ButtonState(role: .destructive, action: .useLocalData) {
                                TextState("Use Local Data")
                            }
                            ButtonState(role: .destructive, action: .retry) {
                                TextState("Retry")
                            }
                            ButtonState(role: .cancel, action: .leaveApp) {
                                TextState("Leave App")
                            }
                        },
                        message: { TextState("Unable to fetch the to-do list. Would you like to retry or leave the app?") }
                    )
                }
                return .none

            case let .deleteToDoItem(id):
                state.isDeleting = true
                state.deletingTodoID = id
                return .run { send in
                    do {
                        try await toDoService.deleteToDo(id: id)
                        await send(.deleteToDoResponse(.success(id)))
                    } catch {
                        await send(.deleteToDoResponse(.failure(.networkError(error))))
                    }
                }

            case let .deleteToDoResponse(.success(id)):
                state.todos.removeAll { $0.id == id }
                state.isDeleting = false
                state.deletingTodoID = nil
                return .none

            case .deleteToDoResponse(.failure(_)):
                state.isDeleting = false
                state.deletingTodoID = nil
                state.alert = .init(title: {
                    TextState("Failed to Delete Item!")
                })
                return .none
            }
        }
        .ifLet(\.$addToDo, action: \.addToDo) {
            AddToDoReducer()
        }
    }
}
