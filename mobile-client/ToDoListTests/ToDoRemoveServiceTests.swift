import Foundation
import Testing
@testable import ToDoList

struct ToDoRemoteServiceTests {
    // A mock data fetcher to simulate network responses.
    private var mockDataFetcher: MockDataFetcher

    // A mock local service to simulate local data storage.
    private var mockLocalService: MockToDoLocalService

    // The service under test, using the mocked dependencies.
    private var service: ToDoRemoteService

    /// Initializes the test suite, setting up mock services for testing.
    init() {
        mockLocalService = MockToDoLocalService()
        mockDataFetcher = MockDataFetcher()
        service = ToDoRemoteService(localService: mockLocalService, dataFetcher: mockDataFetcher)
    }

    /// Tests the successful fetching of ToDo items from the remote service.
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
        // Prepare the response to simulate a successful fetch.
        let fetchResponse = FetchToDoResponse(success: true, data: todos)

        // Encode the response into JSON data.
        let jsonData = try! JSONEncoder().encode(fetchResponse)

        // Define the URL for the fetch request.
        let url = URL(string: "http://localhost:5000/todos")!

        // Create a successful HTTP response.
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        // Set the result of the mock data fetcher.
        mockDataFetcher.result = (jsonData, httpResponse)

        // Call the method to fetch ToDo items.
        let remoteToDos = try! await service.fetchToDos()

        // Expect the number of fetched ToDos to match the mock data.
        #expect(remoteToDos.count == todos.count)
    }

    /// Tests the order of fetched ToDo items from the remote service.
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

        // Prepare the response to simulate a successful fetch.
        let fetchResponse = FetchToDoResponse(success: true, data: todos)

        // Encode the response into JSON data.
        let jsonData = try! JSONEncoder().encode(fetchResponse)

        // Define the URL for the fetch request.
        let url = URL(string: "http://localhost:5000/todos")!

        // Create a successful HTTP response.
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        mockDataFetcher.result = (jsonData, httpResponse)

        // Call the method to fetch ToDo items and validate the order of fetched ToDo items.
        let remoteToDos = try! await service.fetchToDos()

        #expect(remoteToDos[0].id == 2)
        #expect(remoteToDos[1].id == 1)
        #expect(remoteToDos[2].id == 5)
        #expect(remoteToDos[3].deadline == nil)
        #expect(remoteToDos[4].deadline == nil)
    }

    /// Tests the failure scenario when fetching ToDo items from the remote service.
    @Test
    func testFetchDoToFailure() async {
        // Define the URL for the fetch request.
        let url = URL(string: "http://localhost:5000/todos")!

        // Create an HTTP response with a status code indicating failure (500 Internal Server Error).
        let httpResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!

        // Set the result of the mock data fetcher to simulate a failure response.
        mockDataFetcher.result = (Data(), httpResponse)

        do {
            // Attempt to fetch ToDo items, expecting an error to be thrown.
            _ = try await service.fetchToDos()

            // If no error is thrown, record an unexpected error.
            Issue.record("Unexpected Error")
        } catch {
            // Handle the error thrown by the fetch method.
            if let serviceError = error as? ToDoError {
                // Expect the error to be of type ToDoServiceError and verify the status code.
                #expect(serviceError == ToDoError.invalidResponse(500))
            } else {
                // Record an unexpected error if the error type does not match.
                Issue.record("Unexpected Error")
            }
        }
    }

    /// Tests the successful posting of a ToDo item to the remote service.
    @Test
    func testPostToDoSuccess() async {
        // Create a sample ToDo item to be posted.
        let todo = ToDoItem(id: 1,
                            title: "Buy groceries",
                            status: "pending",
                            tags: ["errand"],
                            createdAt: "2024-10-10T10:00:00.117Z",
                            updatedAt: "2024-10-15T10:00:00.117Z")

        // Prepare the response to simulate a successful post.
        let fetchResponse = AddToDoResponse(success: true, data: todo)

        // Encode the response into JSON data.
        let jsonData = try! JSONEncoder().encode(fetchResponse)

        // Define the URL for the post request.
        let url = URL(string: "http://localhost:5000/todos")!

        // Create a successful HTTP response.
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        // Set the result of the mock data fetcher to simulate a successful post response.
        mockDataFetcher.result = (jsonData, httpResponse)

        do {
            // Call the method to post the ToDo item.
            let remoteToDo = try await service.postToDo(todo)

            // Verify the title of the posted ToDo matches the original.
            #expect(remoteToDo.title == todo.title)

            // Expect the local service's todos count to be 1 after the post.
            #expect(mockLocalService.todos.count == 1)

            // Verify the createdAt property of the stored ToDo matches the original.
            #expect(mockLocalService.todos.first!.createdAt == todo.createdAt)
        } catch {
            // Record an unexpected error if one occurs.
            Issue.record("Unexpected Error")
        }
    }

    /// Tests the failure of posting a ToDo item to the remote service.
    @Test
    func testPostToDoFailure() async {
        // Create a sample ToDo item to be posted.
        let todo = ToDoItem(id: 1,
                            title: "Buy groceries",
                            status: "pending",
                            tags: ["errand"],
                            createdAt: "2024-10-10T10:00:00.333Z",
                            updatedAt: "2024-10-15T10:00:00.333Z")

        // Define the URL for the post request.
        let url = URL(string: "http://localhost:5000/todos")!

        // Create an HTTP response with a 500 status code to simulate a server error.
        let httpResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!

        // Set the result of the mock data fetcher to simulate a server error.
        mockDataFetcher.result = (Data(), httpResponse)

        do {
            // Attempt to post the ToDo item.
            _ = try await service.postToDo(todo)
            Issue.record("Unexpected Error")
        } catch {
            // Verify that the error returned is of the expected type.
            if let serviceError = error as? ToDoError {
                #expect(serviceError == ToDoError.invalidResponse(500))
            } else {
                Issue.record("Unexpected Error")
            }
        }
    }

    /// Tests the successful deletion of a ToDo item from the remote service.
    @Test
    func testDeleteToDoSuccess() async {
        // Create a sample ToDo item to be posted and deleted.
        let todo = ToDoItem(id: 1,
                            title: "Buy groceries",
                            status: "pending",
                            tags: ["errand"],
                            createdAt: "2024-10-10T10:00:00.333Z",
                            updatedAt: "2024-10-15T10:00:00.333Z")

        // Prepare the response to simulate a successful post.
        let fetchResponse = AddToDoResponse(success: true, data: todo)

        // Encode the response into JSON data.
        let jsonData = try! JSONEncoder().encode(fetchResponse)

        // Define the URL for the post request.
        let url = URL(string: "http://localhost:5000/todos")!

        // Create a successful HTTP response.
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        // Set the result of the mock data fetcher to simulate a successful post response.
        mockDataFetcher.result = (jsonData, httpResponse)

        // Post the ToDo item.
        let remoteToDo = try! await service.postToDo(todo)

        // Verify the title of the posted ToDo matches the original.
        #expect(remoteToDo.title == todo.title)

        // Expect the local service's todos count to be 1 after the post.
        #expect(mockLocalService.todos.count == 1)

        // Set the result of the mock data fetcher to simulate a successful deletion.
        mockDataFetcher.result = (Data(), httpResponse)

        do {
            // Attempt to delete the ToDo item.
            try await service.deleteToDo(id: 1)
            // Expect the local service's todos count to be 0 after the deletion.
            #expect(mockLocalService.todos.count == 0)
        } catch {
            Issue.record("Unexpected Error")
        }
    }

    /// Tests the failure of deleting a ToDo item from the remote service.
    @Test
    func testDeleteToDoFailure() async {
        // Create a sample ToDo item to be posted and deleted.
        let todo = ToDoItem(id: 1,
                            title: "Buy groceries",
                            status: "pending",
                            tags: ["errand"],
                            createdAt: "2024-10-10T10:00:00.333Z",
                            updatedAt: "2024-10-15T10:00:00.333Z")

        // Prepare the response to simulate a successful post.
        let fetchResponse = AddToDoResponse(success: true, data: todo)

        // Encode the response into JSON data.
        let jsonData = try! JSONEncoder().encode(fetchResponse)

        // Define the URL for the post request.
        let url = URL(string: "http://localhost:5000/todos")!

        // Create a successful HTTP response.
        var httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        // Set the result of the mock data fetcher to simulate a successful post response.
        mockDataFetcher.result = (jsonData, httpResponse)

        // Post the ToDo item.
        let remoteToDo = try! await service.postToDo(todo)

        // Verify the title of the posted ToDo matches the original.
        #expect(remoteToDo.title == todo.title)

        // Expect the local service's todos count to be 1 after the post.
        #expect(mockLocalService.todos.count == 1)

        // Create an HTTP response with a 500 status code to simulate a server error for deletion.
        httpResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
        mockDataFetcher.result = (Data(), httpResponse)

        do {
            // Attempt to delete the ToDo item.
            try await service.deleteToDo(id: 1)
            Issue.record("Unexpected Error")
        } catch {
            // Verify that the error returned is of the expected type.
            if let serviceError = error as? ToDoError {
                #expect(serviceError == ToDoError.invalidResponse(500))
            } else {
                Issue.record("Unexpected Error")
            }
        }
    }

    /// Tests the synchronization of remote and local ToDo items during updates and removals.
    @Test
    func testRemoteLocalSyncUpdateRemove() async {
        // Populate the local service with existing ToDo items.
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

        // Create mock remote ToDo items to fetch.
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

        // Prepare the response to simulate a successful fetch.
        let fetchResponse = FetchToDoResponse(success: true, data: todos)
        let jsonData = try! JSONEncoder().encode(fetchResponse)
        let url = URL(string: "http://localhost:5000/todos")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        // Set the result of the mock data fetcher to simulate a successful fetch response.
        mockDataFetcher.result = (jsonData, httpResponse)

        // Fetch the remote ToDo items.
        let remoteToDos = try! await service.fetchToDos()

        // Verify that the number of fetched ToDos matches the mock data.
        #expect(remoteToDos.count == todos.count)

        // Verify that the local service's todos count matches the fetched count.
        #expect(mockLocalService.todos.count == todos.count)

        // Verify the title of the local item with id 1 is updated to match the remote item.
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

    /// Tests the synchronization of remote ToDo items with local storage, ensuring updates and additions work correctly.
    @Test
    func testRemoteLocalSyncUpdateAdd() async {
        // Initial local ToDo items.
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

        // Set the local service's ToDo items.
        mockLocalService.todos = originLocalToDos

        // Mock remote ToDo items to fetch.
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

        // Prepare the response to simulate a successful fetch.
        let fetchResponse = FetchToDoResponse(success: true, data: todos)
        let jsonData = try! JSONEncoder().encode(fetchResponse)
        let url = URL(string: "http://localhost:5000/todos")!
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        // Set the result of the mock data fetcher to simulate a successful fetch response.
        mockDataFetcher.result = (jsonData, httpResponse)

        // Fetch remote ToDo items.
        let remoteToDos = try! await service.fetchToDos()

        // Check that the number of remote ToDos matches the expected count.
        #expect(remoteToDos.count == todos.count)

        // The local ToDo count should be greater than the original local count after sync.
        #expect(mockLocalService.todos.count > originLocalToDos.count)

        // Check that the local item with id 2 has been updated to match the remote item.
        if let localTodoWithId2 = mockLocalService.todos.first(where: { $0.id == 2 }),
           let remoteTodoWithId2 = remoteToDos.first(where: { $0.id == 2 })
        {
            #expect(localTodoWithId2.title == remoteTodoWithId2.title)
            #expect(localTodoWithId2.tags.count == remoteTodoWithId2.tags.count)
            #expect(localTodoWithId2.tags.first!.name == remoteTodoWithId2.tags.first!)
        } else {
            Issue.record("Unexpected Error: Could not find local or remote ToDo item with ID 2")
        }
    }
}
