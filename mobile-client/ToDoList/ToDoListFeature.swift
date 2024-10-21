
import ComposableArchitecture
import Foundation

@Reducer
struct ToDoListFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var addToDo: AddToDoFeature.State?
        var todos: IdentifiedArrayOf<ToDoItem> = []
        var currentId: Int = 0 // Add a counter for IDs
    }

    enum Action {
        case addButtonTapped
        case addToDo(PresentationAction<AddToDoFeature.Action>)
        case deleteToDoItem(Int)
    }

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

            case .addToDo:
                return .none
            }
        }
        .ifLet(\.$addToDo, action: \.addToDo) {
            AddToDoFeature()
        }
    }
}
