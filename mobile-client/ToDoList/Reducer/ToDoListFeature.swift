import ComposableArchitecture
import Foundation
import UIKit

enum ToDoError: Error, LocalizedError, Equatable {
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse(Int)

    var errorDescription: String? {
        switch self {
        case let .networkError(error):
            "Network error: \(error.localizedDescription)"
        case let .decodingError(error):
            "Decoding error: \(error.localizedDescription)"
        case let .invalidResponse(statusCode):
            "Invalid response from server: \(statusCode)"
        }
    }

    static func == (lhs: ToDoError, rhs: ToDoError) -> Bool {
        switch (lhs, rhs) {
        case let (.networkError(error1), .networkError(error2)):
            (error1 as NSError).code == (error2 as NSError).code &&
                (error1.localizedDescription == error2.localizedDescription)
        case let (.decodingError(error1), .decodingError(error2)):
            (error1 as NSError).code == (error2 as NSError).code &&
                (error1.localizedDescription == error2.localizedDescription)
        case let (.invalidResponse(statusCode1), .invalidResponse(statusCode2)):
            statusCode1 == statusCode2
        default:
            false
        }
    }
}

@Reducer
struct ToDoListFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var addToDo: AddToDoFeature.State?
        var todos: IdentifiedArrayOf<ToDoItem> = []
        var isLoading: Bool = false
        var error: String?
        var isDeleting: Bool = false
        var deletingTodoID: Int?
        var isEditing: Bool = false
        var editingTodoId: Int?
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: Equatable {
        case toggleEditMode
        case addButtonTapped
        case addToDo(PresentationAction<AddToDoFeature.Action>)
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

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert(.presented(.useLocalData)):
                state.alert = nil
                return .none

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
                state.todos.insert(todo, at: 0)
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
