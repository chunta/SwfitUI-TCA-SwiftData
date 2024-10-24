
import ComposableArchitecture
import Foundation
import SwiftData
import Testing
@testable import ToDoList

struct AddToDoReducerTests {
    @Test
    func testSaveToDoSuccess() async {
        let newTodo = ToDoItem(id: 0, title: "New Task", deadline: nil, status: "pending", tags: [], createdAt: "", updatedAt: "")

        let mockService = MockToDoRemoteService()

        let store = await TestStore(initialState: AddToDoReducer.State(todo: ToDoItem(id: 0, title: "", deadline: nil, status: "", tags: [], createdAt: "", updatedAt: ""))) {
            AddToDoReducer()
        } withDependencies: {
            $0.toDoService = mockService
        }

        await store.send(.setTitle("New Task")) {
            $0.todo.title = "New Task"
        }
        await store.send(.setStatus("pending")) {
            $0.todo.status = "pending"
        }

        await store.send(.saveButtonTapped) {
            $0.isSaving = true
        }

        await store.receive(.saveResponse(.success(newTodo))) {
            $0.isSaving = false
        }
    }

    @Test
    func testSaveToDoFailure() async {
        // Set up mock remote service
        let mockService = MockToDoRemoteService()
        mockService.error = NSError(domain: "Fail", code: 0)

        let store = await TestStore(initialState: AddToDoReducer.State(todo: ToDoItem(id: 0, title: "", deadline: nil, status: "", tags: [], createdAt: "", updatedAt: ""))) {
            AddToDoReducer()
        } withDependencies: {
            $0.toDoService = mockService
        }

        await store.send(.setTitle("New Task")) {
            $0.todo.title = "New Task"
        }
        await store.send(.setStatus("pending")) {
            $0.todo.status = "pending"
        }

        await store.send(.saveButtonTapped) {
            $0.isSaving = true
        }

        await store.receive(.saveResponse(.failure(.networkError(mockService.error!)))) {
            $0.isSaving = false
            $0.saveError = "Network error: The operation couldn’t be completed. (Fail error 0.)"
        }
    }
}
