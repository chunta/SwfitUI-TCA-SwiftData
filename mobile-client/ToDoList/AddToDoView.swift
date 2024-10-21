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

struct AddToDoView: View {
    @Bindable var store: StoreOf<AddToDoFeature>

    @State private var showDatePicker = false
    @State private var selectedDate = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ToDoTitleField(title: $store.todo.title.sending(\.setTitle))

                DeadlineField(store: store, showDatePicker: $showDatePicker)

                if showDatePicker {
                    DatePickerComponent(store: store, selectedDate: $selectedDate)
                }

                StatusPicker(selectedStatus: $store.todo.status.sending(\.setStatus))

                TagField(tag: $store.todo.tag.sending(\.setTag))

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
