import ComposableArchitecture
import SwiftUI

extension UISegmentedControl {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        setContentHuggingPriority(.defaultLow, for: .vertical)
    }
}

enum ToDoStatus: String, CaseIterable, Identifiable {
    case todo
    case inProgress
    case done
    var id: String { rawValue }
}

struct AddToDoView: View {
    @Bindable var store: StoreOf<AddToDoReducer>

    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    @State private var tags: [String] = []

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    ToDoTitleField(title: $store.todo.title.sending(\.setTitle))

                    DeadlineField(store: store, showDatePicker: $showDatePicker)

                    if showDatePicker {
                        DatePickerComponent(store: store, selectedDate: $selectedDate)
                    }

                    StatusPicker(selectedStatus: $store.todo.status.sending(\.setStatus))

                    TagInputField(tags: $store.todo.tags.sending(\.setTags), store: store)

                    TagView(tags: $store.todo.tags.sending(\.setTags))

                    ActionButtons(store: store)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical)
            }
            .navigationTitle("Add To-Do")
            .navigationBarTitleDisplayMode(.large)
            .alert(isPresented: Binding<Bool>(
                get: { store.saveError != nil },
                set: { _ in }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(store.saveError ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK")) {
                        store.send(.setError(nil))
                    }
                )
            }

            if store.isSaving {
                ProgressView("Saving...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(width: 100, height: 100)
                    .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

struct ToDoTitleField: View {
    @Binding var title: String

    var body: some View {
        TextField("To-Do Title (Required, max 32 characters)", text: $title)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .padding(.horizontal)
            .background(Color(.systemGray5))
            .cornerRadius(5)
            .foregroundColor(title.isEmpty ? .gray : .black)
    }
}

struct DeadlineField: View {
    @Bindable var store: StoreOf<AddToDoReducer>
    @Binding var showDatePicker: Bool

    var body: some View {
        HStack {
            TextField("Deadline", text: Binding(
                get: { store.todo.deadline ?? "" },
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
    @Bindable var store: StoreOf<AddToDoReducer>
    @Binding var selectedDate: Date

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    private func formatDate(_ date: Date) -> String {
        var formattedDate = dateFormatter.string(from: date)
        formattedDate = formattedDate.replacingOccurrences(of: "(\\+\\d{2})(\\d{2})", with: "$1:$2", options: .regularExpression)
        return formattedDate
    }

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
                           if let deadline = store.todo.deadline,
                              let date = dateFormatter.date(from: deadline)
                           {
                               return date
                           }
                           return Date()
                       },
                       set: { newDate in
                           let formattedDate = formatDate(newDate)
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
                selectedStatus = ToDoStatus.todo.rawValue
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
    @Binding var tags: [String]
    @Bindable var store: StoreOf<AddToDoReducer>
    @State private var input: String = ""

    private let maxTags = 3
    private let maxCharactersPerTag = 8

    var body: some View {
        HStack {
            Image(systemName: "tag.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .padding(.trailing, 8)

            TextField(tags.count < maxTags ? "Add a tag (max \(maxTags) tags, \(maxCharactersPerTag) chars each)" : "Tag limit reached", text: $input, onCommit: {
                addTag()
                DispatchQueue.main.async {
                    input = ""
                }
            })
            .font(.system(size: 15))
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .padding(.horizontal)
            .background(Color(.systemGray5))
            .cornerRadius(5)
            .disabled(tags.count >= maxTags)
        }
    }

    private func addTag() {
        let trimmedInput = input.trimmingCharacters(in: .whitespaces)
        guard !trimmedInput.isEmpty, trimmedInput.count <= maxCharactersPerTag, tags.count < maxTags else { return }
        tags.append(trimmedInput)
    }
}

struct TagView: View {
    @Binding var tags: [String]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tags.filter { !$0.isEmpty }, id: \.self) { tag in
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

    private func removeTag(_ tag: String) {
        if let index = tags.firstIndex(of: tag) {
            tags.remove(at: index)
        }
    }
}

struct TagItem: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Text(tag)
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
    @Bindable var store: StoreOf<AddToDoReducer>

    private var isTitleValid: Bool {
        let title = store.todo.title
        return !title.isEmpty && title.count <= 32
    }

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                if isTitleValid, !store.isSaving {
                    store.send(.saveButtonTapped)
                }
            }) {
                Text("Add")
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(isTitleValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
            .disabled(!isTitleValid)

            Button(action: {
                if !store.isSaving {
                    store.send(.cancelButtonTapped)
                }
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
                initialState: AddToDoReducer.State(
                    todo:
                    ToDoItem(id: 0, title: "", deadline: "", status: "", tags: [""], createdAt: "", updatedAt: "")
                )
            ) {
                AddToDoReducer()
            }
        )
    }
}
