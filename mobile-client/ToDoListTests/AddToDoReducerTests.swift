
import ComposableArchitecture
import Foundation
import SwiftData
import Testing
@testable import ToDoList

struct AddToDoReducerTests {
    /// Tests the successful saving of a new ToDo item.
    @Test
    func testSaveToDoSuccess() async {
        // Arrange: Create a new ToDo item and a mock service.
        let newTodo = ToDoItem(id: 0, title: "New Task", deadline: nil, status: "pending", tags: [], createdAt: "", updatedAt: "")
        let mockService = MockToDoRemoteService()

        // Create a test store with an initial state and dependencies.
        let store = await TestStore(initialState: AddToDoReducer.State(todo: ToDoItem(id: 0, title: "", deadline: nil, status: "", tags: [], createdAt: "", updatedAt: ""))) {
            AddToDoReducer()
        } withDependencies: {
            $0.toDoService = mockService
        }

        // Act: Set the title and status of the ToDo item.
        await store.send(.setTitle("New Task")) {
            $0.todo.title = "New Task"
        }
        await store.send(.setStatus("pending")) {
            $0.todo.status = "pending"
        }

        // Trigger the save action.
        await store.send(.saveButtonTapped) {
            $0.isSaving = true
        }

        // Assert: Receive the success response and check the state.
        await store.receive(.saveResponse(.success(newTodo))) {
            $0.isSaving = false
        }
    }

    /// Tests the failure case when saving a new ToDo item.
    @Test
    func testSaveToDoFailure() async {
        // Arrange: Set up a mock remote service that simulates an error.
        let mockService = MockToDoRemoteService()
        mockService.error = NSError(domain: "Fail", code: 0)

        // Create a test store with an initial state and dependencies.
        let store = await TestStore(initialState: AddToDoReducer.State(todo: ToDoItem(id: 0, title: "", deadline: nil, status: "", tags: [], createdAt: "", updatedAt: ""))) {
            AddToDoReducer()
        } withDependencies: {
            $0.toDoService = mockService
        }

        // Act: Set the title and status of the ToDo item.
        await store.send(.setTitle("New Task")) {
            $0.todo.title = "New Task"
        }
        await store.send(.setStatus("pending")) {
            $0.todo.status = "pending"
        }

        // Trigger the save action.
        await store.send(.saveButtonTapped) {
            $0.isSaving = true
        }

        // Assert: Receive the failure response and check the state for the error message.
        await store.receive(.saveResponse(.failure(.networkError(mockService.error!)))) {
            $0.isSaving = false
            $0.saveError = "Network error: The operation couldn’t be completed. (Fail error 0.)"
        }
    }
}
