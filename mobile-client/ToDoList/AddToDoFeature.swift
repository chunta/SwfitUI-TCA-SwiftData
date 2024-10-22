import ComposableArchitecture
import Foundation

@Reducer
struct AddToDoFeature {
    @ObservableState
    struct State: Equatable {
        var todo: ToDoItem
        var isSaving: Bool = false
        var saveError: String?
    }

    enum Action: Equatable {
        case cancelButtonTapped
        case saveButtonTapped
        case saveResponse(Result<ToDoItem, ToDoError>)
        case setTitle(String)
        case setDeadline(String)
        case setStatus(String)
        case setTags([String])
        case setError(String?)
    }

    @Dependency(\.toDoService) var toDoService

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .cancelButtonTapped:
                return .none

            case .saveButtonTapped:
                state.isSaving = true
                return .run { [state] send in
                    do {
                        let newTodo = try await toDoService.postToDo(state.todo)
                        await send(.saveResponse(.success(newTodo)))
                    } catch {
                        await send(.saveResponse(.failure(.networkError(error))))
                    }
                }

            case .saveResponse(.success(_)):
                state.isSaving = false
                return .none

            case let .saveResponse(.failure(error)):
                state.isSaving = false
                state.saveError = error.localizedDescription
                return .none

            case let .setTitle(title):
                state.todo.title = title
                return .none

            case let .setDeadline(deadline):
                state.todo.deadline = deadline
                return .none

            case let .setStatus(status):
                state.todo.status = status
                return .none

            case let .setTags(newTags):
                state.todo.tags = newTags
                return .none

            case let .setError(errorMessage):
                state.saveError = errorMessage
                return .none
            }
        }
    }
}
