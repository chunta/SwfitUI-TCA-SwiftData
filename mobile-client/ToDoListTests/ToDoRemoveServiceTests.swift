import Foundation
import Testing
@testable import ToDoList

struct ToDoRemoteServiceTests {
    private var mockDataFetcher: MockDataFetcher
    private var mockLocalService: MockToDoLocalService
    private var service: ToDoRemoteService

    init() {
        mockLocalService = MockToDoLocalService()
        mockDataFetcher = MockDataFetcher()
        service = ToDoRemoteService(localService: mockLocalService, dataFetcher: mockDataFetcher)
    }

    @Test
    func testFetchDoToSuccess() async {
        let todos = [
            ToDoItem(id: 1,
                     title: "Buy groceries",
                     status: "pending",
                     tags: ["errand"],
                     createdAt: "2024-10-10T10:00:00Z",
                     updatedAt: "2024-10-15T10:00:00Z"),
            ToDoItem(id: 2,
                     title: "Finish project report",
                     status: "in-progress",
                     tags: ["work"],
                     createdAt: "2024-10-01T09:00:00Z",
                     updatedAt: "2024-10-12T09:00:00Z"),
            ToDoItem(id: 3,
                     title: "Book dentist appointment",
                     status: "pending",
                     tags: ["health"],
                     createdAt: "2024-09-20T11:00:00Z",
                     updatedAt: "2024-10-05T11:00:00Z"),
            ToDoItem(id: 4,
                     title: "Plan weekend trip",
                     status: "completed",
                     tags: ["travel"],
                     createdAt: "2024-08-15T12:30:00Z",
                     updatedAt: "2024-09-01T12:30:00Z"),
            ToDoItem(id: 5,
                     title: "Clean the garage",
                     status: "pending",
                     tags: ["home", "chores"],
                     createdAt: "2024-07-22T13:45:00Z",
                     updatedAt: "2024-08-30T13:45:00Z"),
        ]
        let fetchResponse = FetchToDoResponse(success: true, data: todos)
        let jsonData = try! JSONEncoder().encode(fetchResponse)
        let url = URL(string: "http://localhost:5000/todos")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        mockDataFetcher.result = (jsonData, httpResponse)

        let remoteToDos = try! await service.fetchToDos()

        #expect(remoteToDos.count == todos.count)
        #expect(remoteToDos[0].title == todos[0].title)
        #expect(remoteToDos[4].title == todos[4].title)
    }

    @Test
    func testFetchDoToFailure() async {
        let url = URL(string: "http://localhost:5000/todos")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!

        mockDataFetcher.result = (Data(), httpResponse)

        do {
            _ = try await service.fetchToDos()
            Issue.record("Unexpected Error")
        } catch {
            if let serviceError = error as? ToDoServiceError {
                #expect(serviceError == ToDoServiceError.invalidResponse(500))
            } else {
                Issue.record("Unexpected Error")
            }
        }
    }

    @Test
    func testPostToDoSuccess() async {
        let todo = ToDoItem(id: 1,
                            title: "Buy groceries",
                            status: "pending",
                            tags: ["errand"],
                            createdAt: "2024-10-10T10:00:00Z",
                            updatedAt: "2024-10-15T10:00:00Z")
        let fetchResponse = AddToDoResponse(success: true, data: todo)
        let jsonData = try! JSONEncoder().encode(fetchResponse)
        let url = URL(string: "http://localhost:5000/todos")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        mockDataFetcher.result = (jsonData, httpResponse)
        do {
            let remoteToDo = try await service.postToDo(todo)
            #expect(remoteToDo.title == todo.title)
            #expect(mockLocalService.todos.count == 1)
            #expect(mockLocalService.todos.first!.createdAt == todo.createdAt)
        } catch {
            Issue.record("Unexpected Error")
        }
    }

    @Test
    func testPostToDoFailure() async {
        let todo = ToDoItem(id: 1,
                            title: "Buy groceries",
                            status: "pending",
                            tags: ["errand"],
                            createdAt: "2024-10-10T10:00:00Z",
                            updatedAt: "2024-10-15T10:00:00Z")
        let fetchResponse = AddToDoResponse(success: true, data: todo)
        let jsonData = try! JSONEncoder().encode(fetchResponse)
        let url = URL(string: "http://localhost:5000/todos")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!

        mockDataFetcher.result = (jsonData, httpResponse)
        do {
            try await service.postToDo(todo)
            Issue.record("Unexpected Error")
        } catch {
            if let serviceError = error as? ToDoServiceError {
                #expect(serviceError == ToDoServiceError.invalidResponse(500))
            } else {
                Issue.record("Unexpected Error")
            }
        }
    }

    @Test
    func testDeleteToDoSuccess() async {
        let todo = ToDoItem(id: 1,
                            title: "Buy groceries",
                            status: "pending",
                            tags: ["errand"],
                            createdAt: "2024-10-10T10:00:00Z",
                            updatedAt: "2024-10-15T10:00:00Z")
        let fetchResponse = AddToDoResponse(success: true, data: todo)
        let jsonData = try! JSONEncoder().encode(fetchResponse)
        let url = URL(string: "http://localhost:5000/todos")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        mockDataFetcher.result = (jsonData, httpResponse)

        let remoteToDo = try! await service.postToDo(todo)

        #expect(remoteToDo.title == todo.title)
        #expect(mockLocalService.todos.count == 1)

        mockDataFetcher.result = (Data(), httpResponse)
        do {
            try await service.deleteToDo(id: 1)
            #expect(mockLocalService.todos.count == 0)
        } catch {
            Issue.record("Unexpected Error")
        }
    }

    @Test
    func testDeleteToDoFailure() async {
        let todo = ToDoItem(id: 1,
                            title: "Buy groceries",
                            status: "pending",
                            tags: ["errand"],
                            createdAt: "2024-10-10T10:00:00Z",
                            updatedAt: "2024-10-15T10:00:00Z")
        let fetchResponse = AddToDoResponse(success: true, data: todo)
        let jsonData = try! JSONEncoder().encode(fetchResponse)
        let url = URL(string: "http://localhost:5000/todos")!
        var httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        mockDataFetcher.result = (jsonData, httpResponse)

        let remoteToDo = try! await service.postToDo(todo)

        #expect(remoteToDo.title == todo.title)
        #expect(mockLocalService.todos.count == 1)

        httpResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
        mockDataFetcher.result = (Data(), httpResponse)
        do {
            try await service.deleteToDo(id: 1)
            Issue.record("Unexpected Error")
        } catch {
            if let serviceError = error as? ToDoServiceError {
                #expect(serviceError == ToDoServiceError.invalidResponse(500))
            } else {
                Issue.record("Unexpected Error")
            }
        }
    }
}
