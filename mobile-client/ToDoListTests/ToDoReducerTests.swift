import ComposableArchitecture
import Foundation
import SwiftData
import Testing
@testable import ToDoList

struct ToDoReducerTests {
    @Test
    func testFetchToDosSuccess() async {
        let todos = [
            ToDoItem(id: 1, title: "Task 1", status: "in-progress", tags: [], createdAt: "2024-10-10T08:30:00.807Z", updatedAt: "2024-10-20T10:15:00.807Z"),
            ToDoItem(id: 2, title: "Task 2", status: "pending", tags: [], createdAt: "2024-10-15T09:00:00.807Z", updatedAt: "2024-10-25T14:00:00.807Z"),
        ]

        let mockService = MockToDoRemoteService()
        mockService.todos = todos

        let store = await TestStore(initialState: ToDoListReducer.State()) {
            ToDoListReducer()
        } withDependencies: {
            $0.toDoService = mockService
        }

        await store.send(.fetchToDos) {
            $0.isLoading = true
        }

        await store.receive(.fetchToDosResponse(.success(todos))) {
            $0.isLoading = false
            $0.todos = IdentifiedArrayOf(uniqueElements: todos)
        }
    }

    @Test
    func testFetchToDosFailure() async {
        let mockService = MockToDoRemoteService()
        mockService.error = NSError(domain: "Fail", code: 0)

        let store = await TestStore(initialState: ToDoListReducer.State()) {
            ToDoListReducer()
        } withDependencies: {
            $0.toDoService = mockService
        }

        await store.send(.fetchToDos) {
            $0.isLoading = true
        }

        await store.receive(.fetchToDosResponse(.failure(.networkError(mockService.error!)))) {
            $0.isLoading = false
            $0.error = "Network error: The operation couldn’t be completed. (Fail error 0.)"
            $0.alert = .init(
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
    }

    @Test
    func testAddToDoSuccess() async {
        let mockService = MockToDoRemoteService()
        mockService.todos = []

        let store = await TestStore(initialState: ToDoListReducer.State()) {
            ToDoListReducer()
        } withDependencies: {
            $0.toDoService = mockService
        }

        await store.send(.addButtonTapped) {
            $0.addToDo = AddToDoReducer.State(todo: ToDoItem(id: 0, title: "", deadline: nil, status: "", tags: [], createdAt: "", updatedAt: ""))
        }

        // We not only test addition value, but only insertion index
        let todo1 = ToDoItem(id: 1, title: "Task 1", deadline: "2022-10-10T10:00:00.807Z", status: "pending", tags: [], createdAt: "2024-11-01T10:00:00.807Z", updatedAt: "2024-11-01T10:00:00.117Z")
        await store.send(.addToDo(.presented(.saveResponse(.success(todo1))))) {
            $0.insertionIndex = 0
            $0.todos.insert(todo1, at: $0.insertionIndex)
            $0.addToDo = nil
        }

        let todo2 = ToDoItem(id: 2, title: "Task 2", deadline: "2024-10-05T10:00:00.807Z", status: "pending", tags: [], createdAt: "2024-10-01T10:00:00.807Z", updatedAt: "2024-10-01T10:00:00.807Z")

        await store.send(.addButtonTapped) {
            $0.addToDo = AddToDoReducer.State(todo: ToDoItem(id: 0, title: "", deadline: nil, status: "", tags: [], createdAt: "", updatedAt: ""))
        }

        await store.send(.addToDo(.presented(.saveResponse(.success(todo2))))) {
            $0.insertionIndex = 1
            $0.todos.insert(todo2, at: $0.insertionIndex)
            $0.addToDo = nil
        }

        let todo3 = ToDoItem(id: 3, title: "Task 3", deadline: "2021-10-10T10:00:00.807Z", status: "pending", tags: [], createdAt: "2024-10-01T11:00:00.807Z", updatedAt: "2024-10-01T11:00:00.807Z")
        await store.send(.addButtonTapped) {
            $0.addToDo = AddToDoReducer.State(todo: ToDoItem(id: 0, title: "", deadline: nil, status: "", tags: [], createdAt: "", updatedAt: ""))
        }

        await store.send(.addToDo(.presented(.saveResponse(.success(todo3))))) {
            $0.insertionIndex = 0
            $0.todos.insert(todo3, at: $0.insertionIndex)
            $0.addToDo = nil
        }

        let todo4 = ToDoItem(id: 4, title: "Task 4", deadline: nil, status: "pending", tags: [], createdAt: "2024-10-01T11:00:00.807Z", updatedAt: "2024-10-01T11:00:00.807Z")
        await store.send(.addButtonTapped) {
            $0.addToDo = AddToDoReducer.State(todo: ToDoItem(id: 0, title: "", deadline: nil, status: "", tags: [], createdAt: "", updatedAt: ""))
        }

        await store.send(.addToDo(.presented(.saveResponse(.success(todo4))))) {
            $0.insertionIndex = 3
            $0.todos.insert(todo4, at: $0.insertionIndex)
            $0.addToDo = nil
        }
    }

    @Test
    func testDeleteToDoSuccess() async {
        let todos = [
            ToDoItem(id: 1, title: "Task 1", status: "in-progress", tags: [], createdAt: "2024-10-10T08:30:00.117Z", updatedAt: "2024-10-20T10:15:00.117Z"),
            ToDoItem(id: 2, title: "Task 2", status: "pending", tags: [], createdAt: "2024-10-15T09:00:00.117Z", updatedAt: "2024-10-25T14:00:00.117Z"),
        ]

        let mockService = MockToDoRemoteService()
        mockService.todos = todos

        let store = await TestStore(initialState: ToDoListReducer.State(todos: IdentifiedArrayOf(uniqueElements: todos))) {
            ToDoListReducer()
        } withDependencies: {
            $0.toDoService = mockService
        }

        await store.send(.deleteToDoItem(1)) {
            $0.isDeleting = true
            $0.deletingTodoID = 1
        }

        await store.receive(.deleteToDoResponse(.success(1))) {
            $0.todos.removeAll { $0.id == 1 }
            $0.isDeleting = false
            $0.deletingTodoID = nil
        }
    }

    @Test
    func testDeleteToDoFailure() async {
        let todos = [
            ToDoItem(id: 1, title: "Task 1", status: "in-progress", tags: [], createdAt: "2024-10-10T08:30:00.117Z", updatedAt: "2024-10-20T10:15:00.117Z"),
            ToDoItem(id: 2, title: "Task 2", status: "pending", tags: [], createdAt: "2024-10-15T09:00:00.117Z", updatedAt: "2024-10-25T14:00:00.117Z"),
        ]

        let mockService = MockToDoRemoteService()
        mockService.todos = todos
        mockService.error = NSError(domain: "Fail", code: 0)

        let store = await TestStore(initialState: ToDoListReducer.State(todos: IdentifiedArrayOf(uniqueElements: todos))) {
            ToDoListReducer()
        } withDependencies: {
            $0.toDoService = mockService
        }

        await store.send(.deleteToDoItem(1)) {
            $0.isDeleting = true
            $0.deletingTodoID = 1
        }

        await store.receive(.deleteToDoResponse(.failure(.networkError(mockService.error!)))) {
            $0.isDeleting = false
            $0.deletingTodoID = nil
            $0.alert = .init(title: { TextState("Failed to Delete Item!") })
        }
    }
}
