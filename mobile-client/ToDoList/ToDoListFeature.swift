
import ComposableArchitecture
import Foundation

enum ToDoError: Error, LocalizedError {
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
}

@Reducer
struct ToDoListFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var addToDo: AddToDoFeature.State?
        var todos: IdentifiedArrayOf<ToDoItem> = []
        var currentId: Int = 0
        var isLoading: Bool = false
        var error: String?
    }

    enum Action {
        case addButtonTapped
        case addToDo(PresentationAction<AddToDoFeature.Action>)
        case deleteToDoItem(Int)
        case fetchToDos
        case fetchToDosResponse(Result<[ToDoItem], ToDoError>)
    }

    @Dependency(\.toDoService) var toDoService

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addButtonTapped:
                state.addToDo
                    = AddToDoFeature.State(todo: ToDoItem(id: state.currentId, title: "", deadline: "", status: "", tags: [], createdAt: "", updatedAt: ""))
                return .none

            case .addToDo(.presented(.cancelButtonTapped)):
                state.addToDo = nil
                return .none

            case .addToDo(.presented(.saveButtonTapped)):
                guard let todo = state.addToDo?.todo else { return .none }
                state.todos.append(todo)
                state.currentId += 1
                state.addToDo = nil
                return .none

            case let .deleteToDoItem(id):
                state.todos.removeAll(where: { $0.id == id })
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
                return .none

            case .addToDo:
                return .none
            }
        }
        .ifLet(\.$addToDo, action: \.addToDo) {
            AddToDoFeature()
        }
    }
}

struct ToDoServiceKey: DependencyKey {
    static var liveValue: ToDoServiceProtocol = ToDoService.shared
}

extension DependencyValues {
    var toDoService: ToDoServiceProtocol {
        get { self[ToDoServiceKey.self] }
        set { self[ToDoServiceKey.self] = newValue }
    }
}
