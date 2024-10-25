import SwiftData
import Testing
@testable import ToDoList

struct ToDoLocalServiceTests {
    private var context: ModelContext
    private var service: ToDoLocalService

    /// Initializes a new instance of `ToDoLocalServiceTests`.
    init() {
        // Configure the model to be stored in memory only for testing purposes.
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: ToDoItemData.self, configurations: config)
        context = ModelContext(container)
        service = ToDoLocalService(context: context)
    }

    /// Tests saving and fetching ToDo items.
    @Test
    func testSaveAndFetchTodos() {
        // Arrange: Create a new ToDo item to save.
        let todo = ToDoItemData(id: 0,
                                title: "Grocery Shopping",
                                deadline: nil,
                                status: "todo",
                                tags: [Tag(name: "groceries"), Tag(name: "shopping")],
                                createdAt: "now",
                                updatedAt: "now")
        try! service.save(todo: todo)

        // Act: Fetch the saved ToDo items.
        let todos = try! service.fetchTodos()

        // Assert: Check that the count and the title match expectations.
        #expect(todos.count == 1)

        let fetchedTodo = todos.first
        #expect(fetchedTodo?.title == "Grocery Shopping")
    }

    /// Tests saving multiple ToDo items and their fetch order.
    @Test
    func testSaveAndFetchTodosFetchOrder() {
        // Arrange: Create multiple ToDo items with varying attributes.
        let todo1 = ToDoItemData(id: 0,
                                 title: "Prepare Presentation",
                                 deadline: "2023-05-13T20:49:00.000Z",
                                 status: "todo",
                                 tags: [],
                                 createdAt: "2023-12-01T12:22:30.356Z",
                                 updatedAt: "2023-12-08T12:22:30.356Z")
        let todo2 = ToDoItemData(id: 1,
                                 title: "Visit Doctor",
                                 deadline: "2023-05-13T20:49:00.000+08:00",
                                 status: "todo",
                                 tags: [Tag(name: "health")],
                                 createdAt: "2023-12-02T12:22:30.356Z",
                                 updatedAt: "2023-12-10T12:22:30.356Z")
        let todo3 = ToDoItemData(id: 2,
                                 title: "Finish Book",
                                 deadline: "2024-12-30T15:12:26.676Z",
                                 status: "todo",
                                 tags: [Tag(name: "reading")],
                                 createdAt: "2023-12-03T12:22:30.356Z",
                                 updatedAt: "2023-12-09T12:22:30.356Z")
        let todo4 = ToDoItemData(id: 3,
                                 title: "Finish Book",
                                 deadline: nil,
                                 status: "todo",
                                 tags: [Tag(name: "reading")],
                                 createdAt: "2023-12-03T12:22:30.356Z",
                                 updatedAt: "2023-12-09T12:22:30.356Z")

        // Act: Save all ToDo items.
        try! service.save(todo: todo1)
        try! service.save(todo: todo2)
        try! service.save(todo: todo3)
        try! service.save(todo: todo4)

        // Assert: Fetch the items and check their order.
        let todos = try! service.fetchTodos()
        #expect(todos.count == 4)
        #expect(todos.first!.id == 1) // Visit Doctor
        #expect(todos[1].id == 0) // Prepare Presentation
        #expect(todos[2].id == 2) // Finish Book
        #expect(todos[3].id == 3) // Finish Book
    }

    /// Tests updating an existing ToDo item.
    @Test
    func testUpdateTodo() {
        // Arrange: Create and save a ToDo item.
        let todo = ToDoItemData(id: 1,
                                title: "Draft Report",
                                deadline: nil,
                                status: "todo",
                                tags: [Tag(name: "work")],
                                createdAt: "now",
                                updatedAt: "now")
        try! service.save(todo: todo)

        // Act: Update the ToDo item.
        let updatedTodo = ToDoItem(id: 1,
                                   title: "Draft Final Report",
                                   deadline: nil,
                                   status: "in-progress",
                                   tags: [],
                                   createdAt: "now",
                                   updatedAt: "now")
        try! service.update(todoId: 1, newToDo: updatedTodo)

        // Assert: Fetch the updated item and verify its properties.
        let todos = try! service.fetchTodos()
        let fetchedTodo = todos.first!

        #expect(fetchedTodo.title == "Draft Final Report")
        #expect(fetchedTodo.status == "in-progress")
        #expect(fetchedTodo.tags.count == 0)
    }

    /// Tests deleting a ToDo item.
    @Test
    func testDeleteTodo() async throws {
        // Arrange: Create and save two ToDo items.
        let todo1 = ToDoItemData(id: 0,
                                 title: "Walk the Dog",
                                 deadline: nil,
                                 status: "todo",
                                 tags: [Tag(name: "pets")],
                                 createdAt: "now",
                                 updatedAt: "now")
        let todo2 = ToDoItemData(id: 1,
                                 title: "Walk the Dog",
                                 deadline: nil,
                                 status: "todo",
                                 tags: [Tag(name: "pets")],
                                 createdAt: "now",
                                 updatedAt: "now")
        try service.save(todo: todo1)
        try service.save(todo: todo2)

        // Act: Delete the second ToDo item.
        try service.delete(todo: todo2)

        // Attempt to delete a non-existent ToDo item, expecting no change.
        let todo3 = ToDoItemData(id: 2,
                                 title: "Walk the Dog",
                                 deadline: nil,
                                 status: "todo",
                                 tags: [Tag(name: "pets")],
                                 createdAt: "now",
                                 updatedAt: "now")
        try service.delete(todo: todo3)

        // Assert: Check the remaining ToDo items.
        let todos = try service.fetchTodos()

        // Only one ToDo should remain.
        #expect(todos.count == 1)
    }
}
