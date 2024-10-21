import ComposableArchitecture
import SwiftUI

extension UISegmentedControl {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        setContentHuggingPriority(.defaultLow, for: .vertical)
    }
}

enum ToDoStatus: String, CaseIterable, Identifiable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
    var id: String { rawValue }
}

struct Tag: Identifiable {
    let id = UUID()
    let name: String
}

struct AddToDoView: View {
    @Bindable var store: StoreOf<AddToDoFeature>

    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    @State private var tags: [Tag] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ToDoTitleField(title: $store.todo.title.sending(\.setTitle))

                DeadlineField(store: store, showDatePicker: $showDatePicker)

                if showDatePicker {
                    DatePickerComponent(store: store, selectedDate: $selectedDate)
                }

                StatusPicker(selectedStatus: $store.todo.status.sending(\.setStatus))

                TagInputField(tags: $tags)

                TagView(tags: $tags)

                ActionButtons(store: store)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical)
        }
        .navigationTitle("Add To-Do")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ToDoTitleField: View {
    @Binding var title: String

    var body: some View {
        TextField("Enter To-Do Title", text: $title)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .padding(.horizontal)
            .background(Color(.systemGray5))
            .cornerRadius(5)
    }
}

struct DeadlineField: View {
    @Bindable var store: StoreOf<AddToDoFeature>
    @Binding var showDatePicker: Bool

    var body: some View {
        HStack {
            TextField("Deadline", text: Binding(
                get: { store.todo.deadline },
                set: { _ in }
            ))
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .padding(.horizontal)
            .background(Color(.systemGray5))
            .cornerRadius(5)
            .disabled(true)
            .modifier(AutoResizingTextFieldModifier())

            Button(action: {
                showDatePicker.toggle()
            }) {
                Image(systemName: "calendar")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(10)
            }
        }
    }
}

struct AutoResizingTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .font(.system(size: min(20, geometry.size.width / 10)))
                .frame(width: geometry.size.width)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

struct DatePickerComponent: View {
    @Bindable var store: StoreOf<AddToDoFeature>
    @Binding var selectedDate: Date

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()

    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2023, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2200, month: 12, day: 31, hour: 23, minute: 59, second: 59))!
        return startDate ... endDate
    }()

    var body: some View {
        DatePicker("Select Deadline",
                   selection: Binding<Date>(
                       get: {
                           dateFormatter.date(from: store.todo.deadline) ?? Date()
                       },
                       set: { newDate in
                           let formattedDate = dateFormatter.string(from: newDate)
                           store.send(.setDeadline(formattedDate))
                           selectedDate = newDate
                       }
                   ),
                   in: dateRange,
                   displayedComponents: [.date, .hourAndMinute])
            .padding()
            .datePickerStyle(.graphical)
            .background(Color.pink.opacity(0.2), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct StatusPicker: View {
    @Binding var selectedStatus: String

    var body: some View {
        HStack {
            Image(systemName: "flag.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .padding(.trailing, 8)

            Picker("Status", selection: $selectedStatus) {
                ForEach(ToDoStatus.allCases, id: \.self) { status in
                    Text(status.rawValue)
                        .tag(status.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(height: 42)
        }
        .onAppear {
            if selectedStatus.isEmpty {
                selectedStatus = ToDoStatus.pending.rawValue
            }
        }
    }
}

struct TagField: View {
    @Binding var tag: String

    var body: some View {
        HStack {
            Image(systemName: "tag.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .padding(.trailing, 8)

            TextField("Enter Tag", text: $tag)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .padding(.horizontal)
                .background(Color(.systemGray5))
                .cornerRadius(5)
        }
    }
}

struct TagInputField: View {
    @Binding var tags: [Tag]
    @State private var input: String = ""

    var body: some View {
        HStack {
            Image(systemName: "tag.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .padding(.trailing, 8)

            TextField("Add a tag", text: $input, onCommit: {
                addTag()
            })
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .padding(.horizontal)
            .background(Color(.systemGray5))
            .cornerRadius(5)
        }
    }

    private func addTag() {
        guard !input.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newTag = Tag(name: input.trimmingCharacters(in: .whitespaces))
        tags.append(newTag)
        DispatchQueue.main.async {
            input = ""
        }
    }
}

struct TagView: View {
    @Binding var tags: [Tag]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tags) { tag in
                TagItem(tag: tag) {
                    removeTag(tag)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 52)
        .padding(.horizontal)
        .padding(.vertical, 5)
        .background(Color(.systemGray6))
        .cornerRadius(5)
        .clipped()
    }

    private func removeTag(_ tag: Tag) {
        if let index = tags.firstIndex(where: { $0.id == tag.id }) {
            tags.remove(at: index)
        }
    }
}

struct TagItem: View {
    let tag: Tag
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Text(tag.name)
                .padding(8)
                .background(Color.blue.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(5)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct ActionButtons: View {
    @Bindable var store: StoreOf<AddToDoFeature>

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                store.send(.saveButtonTapped)
            }) {
                Text("Add")
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }

            Button(action: {
                store.send(.cancelButtonTapped)
            }) {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
        }
        .padding(.top, 20)
    }
}

#Preview {
    NavigationStack {
        AddToDoView(
            store: Store(
                initialState: AddToDoFeature.State(
                    todo:
                    ToDoItem(id: 0, title: "", deadline: "", status: "", tag: "", createdAt: "", updatedAt: "")
                )
            ) {
                AddToDoFeature()
            }
        )
    }
}
