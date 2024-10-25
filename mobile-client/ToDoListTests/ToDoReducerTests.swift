import ComposableArchitecture
import Foundation
import SwiftData
import Testing
@testable import ToDoList

struct ToDoReducerTests {
    /// Tests the successful fetching of ToDo items from the remote service.
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

        // Send the fetch action and expect loading state to be true.
        await store.send(.fetchToDos) {
            $0.isLoading = true
        }

        // Receive the successful fetch response and update the state accordingly.
        await store.receive(.fetchToDosResponse(.success(todos))) {
            $0.isLoading = false
            $0.todos = IdentifiedArrayOf(uniqueElements: todos)
        }
    }

    /// Tests the failure case when fetching ToDo items from the remote service.
    @Test
    func testFetchToDosFailure() async {
        let mockService = MockToDoRemoteService()
        mockService.error = NSError(domain: "Fail", code: 0)

        let store = await TestStore(initialState: ToDoListReducer.State()) {
            ToDoListReducer()
        } withDependencies: {
            $0.toDoService = mockService
        }

        // Send the fetch action and expect loading state to be true.
        await store.send(.fetchToDos) {
            $0.isLoading = true
        }

        // Receive the failure response and update the state with an error message.
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

    /// Tests the successful addition of a new ToDo item.
    @Test
    func testAddToDoSuccess() async {
        let mockService = MockToDoRemoteService()
        mockService.todos = []

        let store = await TestStore(initialState: ToDoListReducer.State()) {
            ToDoListReducer()
        } withDependencies: {
            $0.toDoService = mockService
        }

        // Trigger the add button action and initialize the addToDo state.
        await store.send(.addButtonTapped) {
            $0.addToDo = AddToDoReducer.State(todo: ToDoItem(id: 0, title: "", deadline: nil, status: "", tags: [], createdAt: "", updatedAt: ""))
        }

        // Prepare the first ToDo item and send the save response.
        let todo1 = ToDoItem(id: 1, title: "Task 1", deadline: "2022-10-10T10:00:00.807Z", status: "pending", tags: [], createdAt: "2024-11-01T10:00:00.807Z", updatedAt: "2024-11-01T10:00:00.117Z")
        await store.send(.addToDo(.presented(.saveResponse(.success(todo1))))) {
            $0.insertionIndex = 0
            $0.todos.insert(todo1, at: $0.insertionIndex)
            $0.addToDo = nil
        }

        // Prepare and add the second ToDo item.
        let todo2 = ToDoItem(id: 2, title: "Task 2", deadline: "2024-10-05T10:00:00.807Z", status: "pending", tags: [], createdAt: "2024-10-01T10:00:00.807Z", updatedAt: "2024-10-01T10:00:00.807Z")
        await store.send(.addButtonTapped) {
            $0.addToDo = AddToDoReducer.State(todo: ToDoItem(id: 0, title: "", deadline: nil, status: "", tags: [], createdAt: "", updatedAt: ""))
        }

        await store.send(.addToDo(.presented(.saveResponse(.success(todo2))))) {
            $0.insertionIndex = 1
            $0.todos.insert(todo2, at: $0.insertionIndex)
            $0.addToDo = nil
        }

        // Prepare and add the third ToDo item.
        let todo3 = ToDoItem(id: 3, title: "Task 3", deadline: "2021-10-10T10:00:00.807Z", status: "pending", tags: [], createdAt: "2024-10-01T11:00:00.807Z", updatedAt: "2024-10-01T11:00:00.807Z")
        await store.send(.addButtonTapped) {
            $0.addToDo = AddToDoReducer.State(todo: ToDoItem(id: 0, title: "", deadline: nil, status: "", tags: [], createdAt: "", updatedAt: ""))
        }

        await store.send(.addToDo(.presented(.saveResponse(.success(todo3))))) {
            $0.insertionIndex = 0
            $0.todos.insert(todo3, at: $0.insertionIndex)
            $0.addToDo = nil
        }

        // Prepare and add the fourth ToDo item.
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

    /// Tests the performance of inserting a new ToDo item into the list.
    @Test
    func testNewToDoItemInsertionPerformance() async {
        let totalAdditionDay = 6000

        // Generate a list of ToDo items to be added.
        var todos = (0 ..< totalAdditionDay).map { i in
            ToDoItem(
                id: i,
                title: "Task \(i)",
                deadline: randomDeadline(additionDay: totalAdditionDay),
                status: "pending",
                tags: [],
                createdAt: "2024-10-25T00:00:00Z",
                updatedAt: "2024-10-25T00:00:00Z"
            )
        }

        // Sort ToDo items by their deadline.
        todos.sortedByDeadline()

        // Select a random deadline for the new ToDo item to be inserted between two existing items.
        let inBetweenDeadline = randomDeadlineInBetween(between: todos[4217].deadline!, and: todos[4218].deadline!)

        let initialState = ToDoListReducer.State(todos: IdentifiedArrayOf(uniqueElements: todos))

        let store = await TestStore(initialState: initialState) {
            ToDoListReducer()
        } withDependencies: {
            $0.toDoService = MockToDoRemoteService()
        }

        // Create a new ToDo item with a specified deadline.
        let newTodo = ToDoItem(
            id: totalAdditionDay,
            title: "New Task",
            deadline: inBetweenDeadline,
            status: "pending",
            tags: [],
            createdAt: "2024-10-25T10:00:00Z",
            updatedAt: "2024-10-25T10:00:00Z"
        )

        await store.send(.addButtonTapped) {
            $0.addToDo = AddToDoReducer.State(todo: ToDoItem(id: 0, title: "", deadline: nil, status: "", tags: [], createdAt: "", updatedAt: ""))
        }

        // Record the start time of the insertion operation
        let runStartTime = Date().millisecondsSince1970

        // Measure the performance of adding a new ToDo item.
        await store.send(.addToDo(.presented(.saveResponse(.success(newTodo))))) {
            $0.insertionIndex = 4218
            $0.todos.insert(newTodo, at: $0.insertionIndex)
            $0.addToDo = nil
        }

        // Record the end time of the insertion operation
        let runEndTime = Date().millisecondsSince1970

        let spentTime = runEndTime - runStartTime

        print("Time spent on insertion: \(spentTime) milliseconds")

        #expect(spentTime < 130)
    }

    /// Tests the successful deletion of a ToDo item.
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

    /// Tests the failure case when trying to delete a ToDo item.
    @Test
    func testDeleteToDoFailure() async {
        let todos = [
            ToDoItem(id: 1, title: "Task 1", deadline: nil, status: "in-progress", tags: [], createdAt: "2024-10-10T08:30:00.807Z", updatedAt: "2024-10-20T10:15:00.807Z"),
            ToDoItem(id: 2, title: "Task 2", deadline: nil, status: "pending", tags: [], createdAt: "2024-10-15T09:00:00.807Z", updatedAt: "2024-10-25T14:00:00.807Z"),
        ]

        let mockService = MockToDoRemoteService()
        mockService.todos = todos
        mockService.error = NSError(domain: "Fail", code: 0)

        let store = await TestStore(initialState: ToDoListReducer.State(todos: IdentifiedArrayOf(uniqueElements: todos))) {
            ToDoListReducer()
        } withDependencies: {
            $0.toDoService = mockService
        }

        // Send the delete action for the second ToDo item and expect the deletion process to start.
        await store.send(.deleteToDoItem(1)) {
            $0.isDeleting = true
            $0.deletingTodoID = 1
        }

        // Receive the failure response and update the state to reflect the error.
        await store.receive(.deleteToDoResponse(.failure(.networkError(mockService.error!)))) {
            $0.isDeleting = false
            $0.deletingTodoID = nil
            $0.alert = .init(title: { TextState("Failed to Delete Item!") })
        }
    }
}

extension ToDoReducerTests {
    /// Generates a random deadline string in ISO 8601 format by adding a random number of days
    /// to the current date, constrained by the specified maximum number of days to add.
    ///
    /// - Parameter additionDay: The maximum number of days to add to the current date.
    /// - Returns: A string representing the randomly generated deadline in ISO 8601 format.
    func randomDeadline(additionDay: Int) -> String {
        let calendar = Calendar.current
        let currentDate = Date()

        // Generate a random number of days within the specified range
        let randomDays = Int.random(in: 0 ... additionDay)
        let randomDate = calendar.date(byAdding: .day, value: randomDays, to: currentDate) ?? currentDate

        // Format the date in ISO 8601 format
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        return formatter.string(from: randomDate)
    }

    /// Generates a random deadline string in ISO 8601 format between two specified date strings.
    ///
    /// - Parameters:
    ///   - startString: A string representing the start date in ISO 8601 format.
    ///   - endString: A string representing the end date in ISO 8601 format.
    /// - Returns: An optional string representing a randomly generated deadline in ISO 8601 format,
    ///            or `nil` if the input date strings cannot be parsed.
    func randomDeadlineInBetween(between startString: String, and endString: String) -> String? {
        guard
            let startDate = ToDoDateFormatter.isoDateFormatter.date(from: startString),
            let endDate = ToDoDateFormatter.isoDateFormatter.date(from: endString)
        else {
            return nil
        }

        // Calculate the time interval between the start and end dates
        let timeInterval = endDate.timeIntervalSince(startDate)
        let randomTimeInterval = TimeInterval.random(in: 0 ... timeInterval)
        let randomDate = startDate.addingTimeInterval(randomTimeInterval)

        return ToDoDateFormatter.isoDateFormatter.string(from: randomDate)
    }
}

extension Date {
    /// A computed property that returns the time interval since 1970 in milliseconds.
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1000.0).rounded())
    }
}
