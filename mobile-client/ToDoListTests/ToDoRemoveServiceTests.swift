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
                     createdAt: "2024-10-10T10:00:00.117Z",
                     updatedAt: "2024-10-15T10:00:00.117Z"),
            ToDoItem(id: 2,
                     title: "Finish project report",
                     status: "in-progress",
                     tags: ["work"],
                     createdAt: "2024-10-01T09:00:00.117Z",
                     updatedAt: "2024-10-12T09:00:00.117Z"),
            ToDoItem(id: 3,
                     title: "Book dentist appointment",
                     status: "pending",
                     tags: ["health"],
                     createdAt: "2024-09-20T11:00:00.117Z",
                     updatedAt: "2024-10-05T11:00:00.117Z"),
            ToDoItem(id: 4,
                     title: "Plan weekend trip",
                     status: "completed",
                     tags: ["travel"],
                     createdAt: "2024-08-15T12:30:00.117Z",
                     updatedAt: "2024-09-01T12:30:00.117Z"),
            ToDoItem(id: 5,
                     title: "Clean the garage",
                     status: "pending",
                     tags: ["home", "chores"],
                     createdAt: "2024-07-22T13:45:00.117Z",
                     updatedAt: "2024-08-30T13:45:00.117Z"),
        ]
        let fetchResponse = FetchToDoResponse(success: true, data: todos)
        let jsonData = try! JSONEncoder().encode(fetchResponse)
        let url = URL(string: "http://localhost:5000/todos")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        mockDataFetcher.result = (jsonData, httpResponse)

        let remoteToDos = try! await service.fetchToDos()

        #expect(remoteToDos.count == todos.count)
    }

    @Test
    func testFetchToDoSuccessFetchOrder() async {
        let todos = [
            ToDoItem(id: 1,
                     title: "Buy groceries",
                     deadline: "2023-10-20T09:12:57.455Z",
                     status: "pending",
                     tags: ["errand"],
                     createdAt: "2024-10-20T09:12:57.455Z",
                     updatedAt: "2024-10-20T09:12:57.455Z"),
            ToDoItem(id: 2,
                     title: "Finish project report",
                     deadline: "2022-10-21T09:12:57.455Z",
                     status: "in-progress",
                     tags: ["work"],
                     createdAt: "2024-10-20T09:12:57.455Z",
                     updatedAt: "2024-10-20T09:12:57.455Z"),
            ToDoItem(id: 3,
                     title: "Hello World",
                     deadline: nil,
                     status: "pending",
                     tags: ["health"],
                     createdAt: "2024-10-20T09:12:57.455Z",
                     updatedAt: "2024-10-20T09:12:57.455Z"),
            ToDoItem(id: 4,
                     title: "Plan weekend trip",
                     deadline: nil,
                     status: "completed",
                     tags: ["travel"],
                     createdAt: "2024-08-15T12:30:00.333Z",
                     updatedAt: "2024-09-01T12:30:00.222Z"),
            ToDoItem(id: 5,
                     title: "Clean the garage",
                     deadline: "2024-12-31T09:12:57.455Z",
                     status: "pending",
                     tags: ["home", "chores"],
                     createdAt: "2024-07-22T13:45:00.331Z",
                     updatedAt: "2024-08-30T13:45:00.222Z"),
        ]

        let fetchResponse = FetchToDoResponse(success: true, data: todos)
        let jsonData = try! JSONEncoder().encode(fetchResponse)
        let url = URL(string: "http://localhost:5000/todos")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        mockDataFetcher.result = (jsonData, httpResponse)

        let remoteToDos = try! await service.fetchToDos()

        #expect(remoteToDos[0].id == 2)
        #expect(remoteToDos[1].id == 1)
        #expect(remoteToDos[2].id == 5)
        #expect(remoteToDos[3].deadline == nil)
        #expect(remoteToDos[4].deadline == nil)
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
                            createdAt: "2024-10-10T10:00:00.117Z",
                            updatedAt: "2024-10-15T10:00:00.117Z")
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
                            createdAt: "2024-10-10T10:00:00.333Z",
                            updatedAt: "2024-10-15T10:00:00.333Z")
        let fetchResponse = AddToDoResponse(success: true, data: todo)
        let jsonData = try! JSONEncoder().encode(fetchResponse)
        let url = URL(string: "http://localhost:5000/todos")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!

        mockDataFetcher.result = (jsonData, httpResponse)
        do {
            _ = try await service.postToDo(todo)
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
                            createdAt: "2024-10-10T10:00:00.333Z",
                            updatedAt: "2024-10-15T10:00:00.333Z")
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
                            createdAt: "2024-10-10T10:00:00.333Z",
                            updatedAt: "2024-10-15T10:00:00.333Z")
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

    @Test
    func testRemoteLocalSyncUpdateRemove() async {
        mockLocalService.todos = [
            ToDoItemData(id: 1,
                         title: "Local Title",
                         deadline: "2024-11-01T09:00:00.333Z",
                         status: "in-progress",
                         tags: [Tag(name: "work")],
                         createdAt: "2024-10-10T08:30:00.333Z",
                         updatedAt: "2024-10-20T10:15:00.333Z"),
            ToDoItemData(id: 2,
                         title: "Buy a birthday gift for John",
                         deadline: "2024-10-25T18:00:00Z",
                         status: "pending",
                         tags: [Tag(name: "work"), Tag(name: "birthday")],
                         createdAt: "2024-10-05T12:00:00.333Z",
                         updatedAt: "2024-10-19T14:45:00.333Z"),
            ToDoItemData(id: 3,
                         title: "Complete home renovation plan",
                         deadline: "2024-12-10T17:00:00.333Z",
                         status: "pending",
                         tags: [],
                         createdAt: "2024-09-25T14:00:00.333Z",
                         updatedAt: "2024-10-10T09:30:00.333Z"),
            ToDoItemData(id: 4,
                         title: "Sleep",
                         deadline: "2024-11-10T17:00:00.333Z",
                         status: "todo",
                         tags: [],
                         createdAt: "2024-09-25T14:00:00.333Z",
                         updatedAt: "2024-11-07T09:30:00.333Z"),
        ]

        let todos = [
            ToDoItem(id: 1,
                     title: "New Title",
                     status: "pending",
                     tags: ["errand"],
                     createdAt: "2024-10-10T10:00:00.333Z",
                     updatedAt: "2024-10-15T10:00:00.333Z"),
            ToDoItem(id: 2,
                     title: "Finish project report",
                     status: "in-progress",
                     tags: ["work"],
                     createdAt: "2024-10-01T09:00:00.333Z",
                     updatedAt: "2024-10-12T09:00:00.333Z"),
        ]
        let fetchResponse = FetchToDoResponse(success: true, data: todos)
        let jsonData = try! JSONEncoder().encode(fetchResponse)
        let url = URL(string: "http://localhost:5000/todos")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        mockDataFetcher.result = (jsonData, httpResponse)

        let remoteToDos = try! await service.fetchToDos()

        #expect(remoteToDos.count == todos.count)

        // Local number of todo item should be same as the latest fetch number
        #expect(mockLocalService.todos.count == todos.count)

        // Title of local item with id 1 should be updated
        if let localTodoWithId1 = mockLocalService.todos.first(where: { $0.id == 1 }),
           let remoteTodoWithId1 = remoteToDos.first(where: { $0.id == 1 })
        {
            #expect(localTodoWithId1.title == remoteTodoWithId1.title)
            #expect(localTodoWithId1.tags.count == remoteTodoWithId1.tags.count)
            #expect(localTodoWithId1.tags.first!.name == remoteTodoWithId1.tags.first!)
        } else {
            Issue.record("Unexpected Error")
        }
    }

    @Test
    func testRemoteLocalSyncUpdateAdd() async {
        let originLocalToDos = [
            ToDoItemData(id: 1,
                         title: "Local Title",
                         deadline: "2024-11-01T09:00:00.333Z",
                         status: "in-progress",
                         tags: [Tag(name: "work")],
                         createdAt: "2024-10-10T08:30:00.333Z",
                         updatedAt: "2024-10-20T10:15:00.333Z"),
            ToDoItemData(id: 2,
                         title: "Buy a birthday gift for John",
                         deadline: "2024-10-25T18:00:00Z",
                         status: "pending",
                         tags: [Tag(name: "work"), Tag(name: "birthday")],
                         createdAt: "2024-10-05T12:00:00.333Z",
                         updatedAt: "2024-10-19T14:45:00.333Z"),
        ]

        mockLocalService.todos = originLocalToDos

        let todos = [
            ToDoItem(id: 1,
                     title: "New Title",
                     status: "pending",
                     tags: ["errand"],
                     createdAt: "2024-10-10T10:00:00.333Z",
                     updatedAt: "2024-10-15T10:00:00.333Z"),
            ToDoItem(id: 2,
                     title: "Finish project report",
                     status: "in-progress",
                     tags: ["sleep"],
                     createdAt: "2024-10-01T09:00:00.333Z",
                     updatedAt: "2024-10-12T09:00:00.323Z"),
            ToDoItem(id: 3,
                     title: "Complete home renovation plan",
                     deadline: "2024-12-10T17:00:00.323Z",
                     status: "pending",
                     tags: [],
                     createdAt: "2024-09-25T14:00:00.323Z",
                     updatedAt: "2024-10-10T09:30:00.323Z"),
            ToDoItem(id: 4,
                     title: "Sleep",
                     deadline: "2024-11-10T17:00:00.323Z",
                     status: "todo",
                     tags: [],
                     createdAt: "2024-09-25T14:00:00.323Z",
                     updatedAt: "2024-11-07T09:30:00.323Z"),
        ]
        let fetchResponse = FetchToDoResponse(success: true, data: todos)
        let jsonData = try! JSONEncoder().encode(fetchResponse)
        let url = URL(string: "http://localhost:5000/todos")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        mockDataFetcher.result = (jsonData, httpResponse)

        let remoteToDos = try! await service.fetchToDos()

        #expect(remoteToDos.count == todos.count)

        // Latest number of local todo item should be greater than origin todos
        #expect(mockLocalService.todos.count > originLocalToDos.count)

        // Title of local item with id 1 should be updated
        if let localTodoWithId2 = mockLocalService.todos.first(where: { $0.id == 2 }),
           let remoteTodoWithId2 = remoteToDos.first(where: { $0.id == 2 })
        {
            #expect(localTodoWithId2.title == remoteTodoWithId2.title)
            #expect(localTodoWithId2.tags.count == remoteTodoWithId2.tags.count)
            #expect(localTodoWithId2.tags.first!.name == remoteTodoWithId2.tags.first!)
        } else {
            Issue.record("Unexpected Error")
        }
    }
}
