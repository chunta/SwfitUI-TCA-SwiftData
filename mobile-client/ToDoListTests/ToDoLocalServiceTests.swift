import SwiftData
import Testing
@testable import ToDoList

struct ToDoLocalServiceTests {
    private var context: ModelContext
    private var service: ToDoLocalService

    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: ToDoItemData.self, configurations: config)
        context = ModelContext(container)
        service = ToDoLocalService(context: context)
    }

    @Test
    func testSaveAndFetchTodos() {
        let todo =
            ToDoItemData(id: 0,
                         title: "Grocery Shopping",
                         deadline: nil,
                         status: "todo",
                         tags: [Tag(name: "groceries"), Tag(name: "shopping")],
                         createdAt: "now",
                         updatedAt: "now")
        try! service.save(todo: todo)

        let todos = try! service.fetchTodos()
        #expect(todos.count == 1)

        let fetchedTodo = todos.first
        #expect(fetchedTodo?.title == "Grocery Shopping")
    }

    @Test
    func testSaveAndFetchTodosFetchOrder() {
        let todo1 =
            ToDoItemData(id: 0,
                         title: "Prepare Presentation",
                         deadline: "2023-05-13T20:49:00.000Z",
                         status: "todo",
                         tags: [],
                         createdAt: "2023-12-01T12:22:30.356Z",
                         updatedAt: "2023-12-08T12:22:30.356Z")
        let todo2 =
            ToDoItemData(id: 1,
                         title: "Visit Doctor",
                         deadline: "2023-05-13T20:49:00.000+08:00",
                         status: "todo",
                         tags: [Tag(name: "health")],
                         createdAt: "2023-12-02T12:22:30.356Z",
                         updatedAt: "2023-12-10T12:22:30.356Z")
        let todo3 =
            ToDoItemData(id: 2,
                         title: "Finish Book",
                         deadline: "2024-12-30T15:12:26.676Z",
                         status: "todo",
                         tags: [Tag(name: "reading")],
                         createdAt: "2023-12-03T12:22:30.356Z",
                         updatedAt: "2023-12-09T12:22:30.356Z")

        let todo4 =
            ToDoItemData(id: 3,
                         title: "Finish Book",
                         deadline: nil,
                         status: "todo",
                         tags: [Tag(name: "reading")],
                         createdAt: "2023-12-03T12:22:30.356Z",
                         updatedAt: "2023-12-09T12:22:30.356Z")

        try! service.save(todo: todo1)
        try! service.save(todo: todo2)
        try! service.save(todo: todo3)
        try! service.save(todo: todo4)

        let todos = try! service.fetchTodos()
        #expect(todos.count == 4)
        #expect(todos.first!.id == 1)
        #expect(todos[1].id == 0)
        #expect(todos[2].id == 2)
        #expect(todos[3].id == 3)
    }

    @Test
    func testUpdateTodo() {
        let todo = ToDoItemData(id: 1,
                                title: "Draft Report",
                                deadline: nil,
                                status: "todo",
                                tags: [Tag(name: "work")],
                                createdAt: "now", updatedAt: "now")
        try! service.save(todo: todo)

        let updatedTodo = ToDoItem(id: 1,
                                   title: "Draft Final Report",
                                   deadline: nil,
                                   status: "in-progress",
                                   tags: [],
                                   createdAt: "now",
                                   updatedAt: "now")
        try! service.update(todoId: 1, newToDo: updatedTodo)

        let todos = try! service.fetchTodos()
        let fetchedTodo = todos.first!

        #expect(fetchedTodo.title == "Draft Final Report")
        #expect(fetchedTodo.status == "in-progress")
        #expect(fetchedTodo.tags.count == 0)
    }

    @Test
    func testDeleteTodo() async throws {
        let todo1 = ToDoItemData(id: 0,
                                 title: "Walk the Dog",
                                 deadline: nil, status: "todo",
                                 tags: [Tag(name: "pets")],
                                 createdAt: "now",
                                 updatedAt: "now")
        let todo2 = ToDoItemData(id: 1,
                                 title: "Walk the Dog",
                                 deadline: nil, status: "todo",
                                 tags: [Tag(name: "pets")],
                                 createdAt: "now",
                                 updatedAt: "now")
        try service.save(todo: todo1)
        try service.save(todo: todo2)
        try service.delete(todo: todo2)

        // Delete non-existent todo, expect no change
        let todo3 = ToDoItemData(id: 2,
                                 title: "Walk the Dog",
                                 deadline: nil,
                                 status: "todo",
                                 tags: [Tag(name: "pets")],
                                 createdAt: "now",
                                 updatedAt: "now")
        try service.delete(todo: todo3)

        let todos = try service.fetchTodos()
        #expect(todos.count == 1)
    }
}
