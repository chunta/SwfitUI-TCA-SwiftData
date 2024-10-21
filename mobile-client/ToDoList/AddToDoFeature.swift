
import ComposableArchitecture
import Foundation

@Reducer
struct AddToDoFeature {
    @ObservableState
    struct State: Equatable {
        var todo: ToDoItem
    }

    enum Action {
        case cancelButtonTapped
        case saveButtonTapped
        case setTitle(String)
        case setDeadline(String)
        case setStatus(String)
        case setTags([String])
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .cancelButtonTapped:
                return .none

            case .saveButtonTapped:
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
            }
        }
    }
}
