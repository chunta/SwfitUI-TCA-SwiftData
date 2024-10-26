import ComposableArchitecture
import Foundation

/// The feature responsible for managing the ToDo list state and actions.
@Reducer
struct ToDoListFeature {
    @ObservableState
    struct State: Equatable {
        /// Presents the AddToDo feature's state if active.
        @Presents var addToDo: AddToDoFeature.State?
        /// The list of ToDo items.
        var todos: IdentifiedArrayOf<ToDoItem> = []
        /// Indicates whether the ToDo items are currently being loaded.
        var isLoading: Bool = false
        /// Holds an error message if fetching ToDo items fails.
        var error: String?
        /// Indicates whether a ToDo item is currently being deleted.
        var isDeleting: Bool = false
        /// Holds the ID of the ToDo item currently being deleted.
        var deletingTodoID: Int?
        /// Indicates whether the list is in edit mode.
        var isEditing: Bool = false
        /// Holds the ID of the ToDo item being edited.
        var editingTodoId: Int?
        /// Index for insertion of new ToDo items.
        var insertionIndex: Int = 0
        /// Presents an alert based on specific actions.
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: Equatable {
        /// Toggles the edit mode for the ToDo list.
        case toggleEditMode
        /// Indicates that the add button was tapped.
        case addButtonTapped
        /// Handles actions from the AddToDo feature.
        case addToDo(PresentationAction<AddToDoFeature.Action>)
        /// Fetches the ToDo items from the service.
        case fetchToDos
        /// Handles the response from the fetchToDos action.
        case fetchToDosResponse(Result<[ToDoItem], ToDoError>)
        /// Deletes a ToDo item by ID.
        case deleteToDoItem(Int)
        /// Handles the response from the deleteToDoItem action.
        case deleteToDoResponse(Result<Int, ToDoError>)
        /// Handles alert actions.
        case alert(PresentationAction<Alert>)

        @CasePathable
        enum Alert {
            case useLocalData
            case retry
            case leaveApp
        }
    }

    @Dependency(\.toDoService) var toDoService

    /// Finds the index to insert a new ToDo item in sorted order based on its deadline.
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
                state.addToDo = AddToDoFeature.State(todo: ToDoItem(id: 0, title: "", deadline: nil, status: "", tags: [], createdAt: "", updatedAt: ""))
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
            AddToDoFeature()
        }
    }
}
