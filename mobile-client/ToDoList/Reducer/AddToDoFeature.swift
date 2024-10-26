import ComposableArchitecture
import Foundation

/// A reducer for managing the state and actions related to adding a new ToDo item.
@Reducer
struct AddToDoFeature {
    @ObservableState
    struct State: Equatable {
        // The ToDo item being added or modified
        var todo: ToDoItem
        // Indicates if the save operation is in progress
        var isSaving: Bool = false
        // Holds an error message if saving fails
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
                // No action required for cancel button
                return .none

            case .saveButtonTapped:
                // Start saving and indicate progress
                state.isSaving = true
                return .run { [state] send in
                    do {
                        // Attempt to post the new ToDo item
                        let newTodo = try await toDoService.postToDo(state.todo)
                        await send(.saveResponse(.success(newTodo)))
                    } catch {
                        // Handle any error that occurs during the save operation
                        await send(.saveResponse(.failure(error as? ToDoError ?? .unknownError)))
                    }
                }

            case .saveResponse(.success(_)):
                // Save was successful; stop the saving indication
                state.isSaving = false
                return .none

            case let .saveResponse(.failure(error)):
                // Save failed; stop the saving indication and show the error
                state.isSaving = false
                state.saveError = error.localizedDescription
                return .none

            case let .setTitle(title):
                // Update the title of the ToDo item
                state.todo.title = title
                return .none

            case let .setDeadline(deadline):
                // Update the deadline of the ToDo item
                state.todo.deadline = deadline
                return .none

            case let .setStatus(status):
                // Update the status of the ToDo item
                state.todo.status = status
                return .none

            case let .setTags(newTags):
                // Update the tags associated with the ToDo item
                state.todo.tags = newTags
                return .none

            case let .setError(errorMessage):
                // Set an error message for display
                state.saveError = errorMessage
                return .none
            }
        }
    }
}
